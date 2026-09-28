# BISCA: catalogo e inventario (fase di sola lettura)

## Analisi e confini

Il progetto usa `AccountSession` per Supabase Auth; `AccountProfile` è il
ProfileSync già esistente. `GameSettings` salva `bisca_settings.cfg` e risolve
i dorsi numerati con `back%d.png`. `deck_selector.gd` conferma le scelte tramite
GameSettings; AccountProfile le invia nel profilo cloud. Card, deck_pile e
match_controller leggono le texture tramite GameSettings.

Questi file e la logica lobby non sono modificati. La conversione guest/email
conserva lo stesso UID e quindi lo stesso inventario. Nessun nuovo sistema auth,
token, cache di preferenze o profilo è stato aggiunto.

## File di questa fase

Modificati:
- `project.godot`: autoload ShopManager dopo AccountProfile, già configurato.
- `scenes/balatro/scripts/main_menu.gd`: collega il pulsante Shop già presente,
  crea la pagina una sola volta, riusa navigazione e ritorno Home esistenti.

Creati:
- `scenes/balatro/scripts/shop_manager.gd`: GET catalogo/inventario, cache in
  memoria, API e signal, paginazione, controlli account e risposte obsolete.
- `scenes/balatro/scripts/shop_page.gd`: consultazione con anteprime locali,
  prezzo/rarità/tipo/proprietà/disponibilità e pulsanti Indietro/Aggiorna.
- `deployment/tests/shop_manager_test.gd`: test con risposte simulate, zero rete.
- `deployment/tests/shop_page_test.gd`: integrazione menu/Shop con 12 oggetti finti.
- `deployment/supabase/002_shop_readonly.sql`: grant/RLS, default server-side.
- `deployment/supabase/003_shop_verify.sql`: prove permessi/isolation con rollback.
- Questo documento. I relativi `.gd.uid` sono metadati generati da Godot.

## API ShopManager

- `refresh()`: lettura esplicita. Richieste concorrenti accorpate in una successiva.
- `get_items()`, `get_items_by_type(type)`, `get_item(id)`.
- `owns_item(id)`, `get_owned_items()`, `get_owned_items_by_type(type)`.
- `get_inventory()`: righe grezze indicizzate per item_id, anche per oggetti non
  presenti nel catalogo visibile. Tutti i getter restituiscono copie profonde.
- Signal senza argomenti: `catalog_loaded`, `inventory_loaded`, `changed`.
- Stato: `catalog_ready`, `inventory_ready`, `loading`, `stale`, `last_error`.

`get_item` restituisce anche `price`, `rarity`, `asset_id`, `item_type`,
`is_available`, `is_default`. Disponibilità e proprietà sono indipendenti:
un oggetto non più in vendita può restare posseduto. Tipo non noto: mostrato
senza texture. Le preview usano solo risorse locali e indici 1–12, mai URL dal DB.

Il catalogo e l'inventario vengono pubblicati solo dopo una lettura completa.
Si continua fino a una pagina vuota anche se il limite del server è più basso
di quello richiesto. Limite protettivo 100 pagine da massimo 100 righe richieste;
non si applicano snapshot troncati. Se supera il limite si segnala un errore.
Prezzi fuori dalla precisione intera sicura JSON vengono rifiutati, non arrotondati.

Nessun `_process`, polling, acquisto, INSERT, PATCH, saldo locale o cache su disco.
Gli header vengono da AccountSession. Sul Web si lascia la decompressione al
browser, come nel profilo. I test e il server headless non contattano Supabase.

Cambio UID: inventario svuotato subito; una generazione invalida tutte le risposte
precedenti, anche A→B→A. Stesso UID: guest/email e rinnovi non creano altri inventari.
Offline: uno snapshot della stessa identità può restare visibile ma è `stale`;
non è autorizzazione ad acquistare. Al riavvio offline il possesso è sconosciuto.

## Default autorevole e compatibilità

`owns_item("deck_back_1")` è true SOLO se la riga è stata letta dall'inventario.
Non si aggiunge un default fittizio. SQL 002 assegna il default a tutti gli utenti
esistenti e ai nuovi signup (inclusi guest). Il vincolo UNIQUE evita duplicati.
Se manca la riga, la UI segnala la migrazione mancante. La conversione guest→email
non cambia UID e non necessita di riassegnazione.

Il selettore attuale continua a permettere gli stessi dorsi di prima: questa fase
NON introduce blocchi all'equipaggiamento. Il possesso nello Shop è indipendente
dal dorso già selezionato. Non sono stati introdotti acquisti o premi. Una futura
RPC dovrà validare sul server acquisto/saldo e, se richiesto, equipaggiamento.

## Supabase: passaggi MANUALI (non applicati da Codex)

1. Conferma che le tabelle e colonne indicate nella richiesta esistano. In
   particolare `bisca_items.id`, `bisca_inventory(user_id,item_id)` UNIQUE,
   `bisca_profiles.public_id` e le colonne di progressione. Non eseguire di nuovo
   la vecchia `001_profiles.sql`: era per creare il profilo iniziale.
2. Rivedi ed esegui `002_shop_readonly.sql` come postgres nel SQL Editor.
   La transazione non ricrea tabelle o utenti e non tocca saldi/progressi.
   Normalizza solo prezzo=0/default=true/asset_id=1 per deck_back_1 e assegna
   tale dorso. La migrazione è ripetibile; il trigger ha nome specifico e non
   sostituisce altri trigger.
3. La migrazione revoca grant di tabella E colonna a PUBLIC/anon/authenticated
   per catalogo, inventario, profilo e progresso stagionale. Riconcede SELECT;
   nel profilo solo INSERT(id,deck_back,deck_front) e UPDATE(deck_back,deck_front).
   Questo mantiene la creazione profilo di AccountProfile. Policy restrittive
   limitano al proprio UID anche in presenza di vecchie policy permissive.
   `bisca_season` e Season 1 non vengono modificati.
4. Esegui `003_shop_verify.sql` con almeno due utenti Auth. Deve stampare PASS.
   Le prove terminano con ROLLBACK, senza lasciare modifiche di test. Verificano
   default, dati altrui invisibili, impossibilità di assegnare oggetti/premi,
   catalogo immutabile, anon senza accesso e modifica del proprio mazzo consentita.
5. Rivedi le eventuali funzioni SECURITY DEFINER elencate in fondo al test:
   grant sulle tabelle non impediscono a una vecchia RPC insicura di scriverle.
   Nessuna RPC di acquisto/grant è stata aggiunta. Il solo nuovo trigger definer
   ha search_path vuoto e EXECUTE revocato ai client.

Il trigger auth è critico: un suo errore può bloccare la creazione utenti.
Provare un nuovo guest dopo la migrazione e controllare Auth Logs se fallisce.
Non cancellare `deck_back_1` come amministratore; non esporre service_role al client.
La migrazione presuppone di essere eseguita dal ruolo postgres della dashboard.
Non è stato possibile validare qui lo schema remoto o eseguire i test SQL.

## Test precisi

Da root del progetto (usa il percorso del tuo binario Godot):

```sh
godot --headless --path . --script deployment/tests/shop_manager_test.gd
godot --headless --path . --script deployment/tests/shop_page_test.gd
godot --headless --path . --script deployment/tests/account_profile_test.gd
godot --headless --path . --script deployment/tests/account_panel_test.gd
```

Prova reale dopo SQL:
1. Avvia da Godot, entra nello Shop: 12 dorsi ordinati, anteprime coerenti con
   asset_id, deck_back_1 gratuito e posseduto. Gli altri non posseduti, salvo
   righe già presenti nel tuo inventario. Nessun pulsante acquista/equipaggia.
2. Da amministratore su un account DI TEST assegna un oggetto usando Table Editor;
   premi Aggiorna: deve apparire posseduto. Cambia is_available=false: deve
   restare posseduto ma non disponibile. Ripristina i dati di test.
3. Esci/accedi a un secondo account: nessun oggetto esclusivo del primo visibile
   come posseduto. Prova anche rete lenta, cambi rapidi di account e offline.
4. Collega email a un guest: stesso UID e stesso inventario; nessun duplicato.
5. Ritorna Home, modifica/conferma il mazzo nel selettore esistente, riavvia e
   verifica AccountProfile. Prova singleplayer e lobby: nome/foto invariati.
6. Esporta Web con il preset esistente BISCA Web e prova browser/mobile. Le
   nuove sorgenti richiedono nuova esportazione e deploy; non basta ricaricare
   la vecchia versione su GitHub Pages.

Riferimenti per grant/RLS e trigger auth:
https://supabase.com/docs/guides/database/postgres/row-level-security
https://supabase.com/docs/guides/auth/managing-user-data

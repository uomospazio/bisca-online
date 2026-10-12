# Catalogo cosmetici (migrazione 018)

Applicata e verificata sul progetto Bisca `yaphzyncmzrbrruzcarn`.

| Tipo | ID | asset_id | Prezzo |
| --- | --- | --- | --- |
| deck_back | deck_back_1 … deck_back_12 | 1 … 12 | 500 |
| avatar | avatar_1 … avatar_32 | 1 … 32 (32 = AvatarSpecial) | 100 |
| throwable | throw_<nome senza estensione> | indice ZERO-based in ThrowCatalog.FILES | 200 |

Eccezioni gratuite: deck_back_1, avatar_1, throw_pomodoro (asset_id 8).
Il trigger assegna questi tre oggetti a ogni nuovo utente, guest inclusi.
Il backfill li assegna anche agli utenti esistenti, senza revocare acquisti.
Inventario, acquisti e offerte continuano a usare le RPC/RLS esistenti.
Le offerte già estratte restano valide; la prossima estrazione può includere
avatar e lanciabili. Non viene resettato il cambio offerte tramite pubblicità.

I front disponibili sono ora 0 e 1. I valori 2 esistenti o inviati da vecchi
client vengono convertiti a 1. Le immagini del terzo front non sono cancellate.

Gli indici dei lanciabili esistenti non vanno riordinati: sono usati anche
nei messaggi multiplayer. Per aggiungerne altri, aggiungere il file al catalogo
Godot e una riga Supabase con lo stesso indice, quindi riesportare client e server.
Questa modifica non distribuisce automaticamente gli export Web/iOS/server.

Verifiche:
- `deployment/tests/cosmetic_catalog_test.gd`: default, inventario isolato per
  account, texture di tutte le categorie, front e preferenze persistenti.
- `deployment/tests/shop_manager_test.gd`: paginazione, offline, race e acquisti
  conservati nella cache della corretta identità.
- Verifica remota: 12 dorsi, 32 avatar, 9 lanciabili; tre default;
  nessun utente privo dei default e nessun profilo con front 2.

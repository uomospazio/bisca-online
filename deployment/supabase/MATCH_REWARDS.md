# Premi partita: attivazione

1. Eseguire `010_match_rewards.sql` e poi `011_match_statistics.sql` nel SQL Editor Supabase. Se 010 e' gia' applicato, basta 011. Applicare 011 prima di distribuire il nuovo server: ora usa `bisca_record_match`.
2. Nel servizio **server Godot** su Render, Environment, aggiungere `SUPABASE_SECRET_KEY` con una secret key `sb_secret_...` del progetto Supabase (Settings > API Keys). NON aggiungerla a Godot client, GitHub o file esportati. NON usare la publishable key.
3. Distribuire il server aggiornato (Dockerfile incluso) e riesportare/distribuire il client.

Non ci sono nuovi autoload. Nessun prezzo dei dorsi viene modificato.

## Statistiche

Le nuove partite multiplayer concluse per l'account (eliminazione/vittoria) aumentano `bisca_profiles.games_played`; una vittoria aumenta anche `wins`. Sono conteggiate anche le partite senza premio in monete, comprese quelle da meno di 5 carte. Guest e account email seguono la stessa regola. Un registro `bisca_match_results` impedisce doppi conteggi sui retry: statistiche e premi vengono registrati nella stessa transazione. Nessun conteggio retroattivo; singleplayer locale e abbandono volontario prima del risultato esclusi. Nessuna scrittura delle statistiche dal client.

Verifica: annotare games_played/wins prima del match; dopo eliminazione aspettarsi +1/+0, dopo vittoria +1/+1. Retry e riconnessioni non devono incrementare nuovamente i valori. Con partenza da 4 carte aspettarsi le statistiche ma zero monete.

## Lobby e animazioni testo

Tutti gli umani in lobby devono premere PRONTO; l'ultimo avvia automaticamente. I bot non devono confermare. Il pulsante diventa ANNULLA finche' non parte la partita. Ingressi, disconnessioni, rimozioni e modifiche alle impostazioni azzerano le conferme. Rigioca riapre la lobby per una nuova conferma. Aggiornare sia server sia client.

In Settings, ANIMAZIONI TESTO attiva/disattiva l'oscillazione di nomi e sottotitoli. La preferenza e' locale, salvata automaticamente, efficace subito anche in partita; le transizioni menu e le animazioni delle carte restano invariate.

## Modalita' di test attuale

`REQUIRE_THREE_DISTINCT_ACCOUNTS = false` in `match_rewards_server.gd`: il minimo di tre account e il blocco dei duplicati sono temporaneamente disattivati. Si possono provare i premi in multiplayer anche con un solo umano e i bot. Restano necessari un account autenticato destinatario (anche guest), il server configurato e la partenza da 5 carte. I bot non ricevono monete; resta un solo premio per account/partita, anche con piu' posti sullo stesso account (vale il primo risultato premiato). Il singleplayer locale non cambia. Basta aggiornare il server, senza nuovo SQL.

## Regole con il controllo account riattivato

- Partenza da 5 carte; almeno 3 account Supabase distinti, verificati e connessi all'avvio. I guest autenticati valgono come gli account con email.
- Se due posti usano lo stesso account la partita non assegna premi.
- 30 monete all'eliminazione definitiva, 50 totali al vincitore, mai 30+50.
- I recuperi di vita previsti dalle regole non contano come eliminazione.
- Uscita volontaria prima dell'eliminazione: niente premio. Disconnessione: non accredita subito, ma il risultato successivo deciso dal server puo' accreditarlo.
- Una disconnessione non modifica l'idoneita' iniziale della partita.
- Singleplayer, partenza da meno di 5 carte e partite non idonee: nessun premio.
- L'identita' destinataria viene fissata all'avvio. Nome/avatar lobby restano separati.
- Crediti e registro premi sono aggiornati nella stessa transazione, una sola volta per coppia partita/account. La RPC non e' eseguibile dal client.
- La schermata pop con conteggio appare solo dopo conferma Supabase; rilegge il saldo senza calcolarlo localmente.

## Test manuale dopo il deploy

1. Collegare tre browser/dispositivi con tre UID distinti; creare partita da 5 carte.
2. Annotare i saldi in bisca_profiles. Far eliminare un giocatore: +30 e popup immediato dopo l'accredito.
3. Completare la partita: ultimo eliminato +30, vincitore +50 totale.
4. Controllare bisca_match_rewards: una riga per account e match_id. Riconnessioni e snapshot ripetuti non aumentano il saldo.
5. Ripetere con due umani e bot / quattro carte / singleplayer: zero accrediti.
6. Cambiare account: il popup dell'account precedente non deve comparire, nessun trasferimento di saldo.
7. Chiamando bisca_award_match con una normale sessione guest o email si deve ottenere permission denied.

## Limiti operativi

Il server ritenta gli accrediti falliti ogni 15 secondi finche' resta acceso. La coda non e' persistente: se il processo viene terminato prima che Supabase confermi un premio, quel premio potrebbe andare perso. I premi gia' registrati nel database restano salvati. Le notifiche ancora non consegnate sono in memoria; dopo riavvio il saldo resta corretto ma il popup puo' non comparire. Non viene promesso recupero delle partite dopo un crash (anche le partite attuali vivono in memoria).

Questa fase non aggiunge controlli anti-collusione/farming oltre ai criteri sopra, ne' ads, XP o classifica.

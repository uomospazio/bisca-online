# Premi partita: attivazione

1. Eseguire `010_match_rewards.sql` nel SQL Editor Supabase.
2. Nel servizio **server Godot** su Render, Environment, aggiungere `SUPABASE_SECRET_KEY` con una secret key `sb_secret_...` del progetto Supabase (Settings > API Keys). NON aggiungerla a Godot client, GitHub o file esportati. NON usare la publishable key.
3. Distribuire il server aggiornato (Dockerfile incluso) e riesportare/distribuire il client.

Non ci sono nuovi autoload. Nessun prezzo dei dorsi viene modificato.

## Regole

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

# Classifica stagionale

## Installazione

1. Nel SQL Editor di Supabase eseguire `supabase/022_seasons.sql` una sola volta, dopo le migrazioni fino alla 021. La migrazione e' transazionale.
2. Aggiornare il server dedicato con il nuovo `match_rewards_server.gd`, poi distribuire il client aggiornato. Il nuovo server usa `bisca_record_ranked_match`; non distribuirlo prima della migrazione.
3. La stagione iniziale e' STAGIONE 0, dal 15 ottobre 2026 alle 00:00 al 1 gennaio 2027 alle 00:00, fuso Europe/Rome. Modificare `bisca_seasons.starts_at` e `ends_at` da Supabase prima della chiusura. Non creare stagioni sovrapposte e non riaprire una stagione gia' liquidata.

## Regole

- Multiplayer: 200 punti al vincitore, 100 al secondo e 50 agli altri, con la stessa idoneita' dei premi in monete. Gli eliminati ricevono i punti mentre la partita continua. Eliminazioni nello stesso round condividono il piazzamento.
- Solitaria locale/offline: 50 punti fissi con la stessa pubblicita' che accredita 30 monete. Nessuna verifica o trasmissione del piazzamento offline. Serve connessione per annuncio/accredito; si usa la stagione attiva al momento dell'accredito.
- La chiave univoca dell'annuncio per utente/partita impedisce doppi accrediti. Annunci shop e bonus multiplayer non danno punti aggiuntivi. Le richieste ripetute non duplicano premi o statistiche.
- La classifica e' globale. Sono mostrati i primi 100 e, separatamente, il proprio piazzamento anche oltre il centesimo. A parita' di punti precede chi raggiunge prima quel totale; ulteriore parita' risolta per ID.
- Le statistiche profilo leggono games_played e wins gia' registrati dal server. Non vengono inventati risultati delle partite locali offline e non si ricostruiscono partite storiche.
- Il server chiama ogni 15 secondi `bisca_settle_seasons()`: dopo la scadenza assegna una sola volta 5000, 2000, 1000, 900, 800, 700, 600, 500, 400, 300 monete ai primi dieci. Se il server e' spento, liquida al riavvio. La funzione puo' anche essere schedulata lato Supabase con credenziali di servizio.

## Sicurezza e limiti attuali

I punteggi non sono scrivibili dal client. La migrazione conserva le restrizioni della 016: annunci **di test**, utenti in `bisca_ad_testers`, conferma client. Prima degli annunci reali e' necessaria la verifica server-to-server del provider; il punteggio fisso rimuove la fiducia nel piazzamento offline, non prova che una partita locale sia stata completata. Non sono stati rimossi i controlli per i tester.

SQL e server/client sono predisposti nel repository: non implicano un deploy su Supabase. Per testare SQL localmente usare `node deployment/tests/seasons_sql.mjs /percorso/pglite/dist/index.js`.

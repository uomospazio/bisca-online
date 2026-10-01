# Market giornaliero

Eseguire `012_daily_shop.sql` nel SQL Editor dopo le migrazioni shop esistenti.
Non e' stato applicato automaticamente al progetto Supabase.

La RPC `bisca_daily_shop` richiede una sessione autenticata (anche guest), sceglie
fino a 6 oggetti disponibili non default e salva la selezione per giorno UTC.
Tutti vedono gli stessi ID, anche riaprendo o cambiando account. Se il catalogo ha
meno di sei candidati, vengono mostrati tutti. Cambiamenti al catalogo non
riestraggono la giornata; un oggetto ritirato non e' piu' visualizzato/acquistabile.
Il client usa la durata restituita dal server, non la data del telefono.
Gli articoli posseduti rimangono visibili con POSSEDUTO.

La tabella delle offerte non e' scrivibile/leggibile direttamente dal client.
Il saldo e gli acquisti continuano a usare la RPC atomica esistente; prezzi invariati.
La rotazione e' una vetrina: la RPC acquisti esistente non viene limitata agli ID
del giorno, preservando la compatibilita' con i client precedenti.

Test manuale:
1. Aprire Personalizza (brush) dalla home: nessun mazzo nella home.
2. Indietro e monete rimangono fissi, mentre il contenuto scorre.
3. Confermare un dorso posseduto con il selettore esistente.
4. Toccare gli slot attorno al profilo per scegliere uno degli oggetti disponibili
   o lasciare vuoto; la preferenza e' locale al dispositivo, non inventario cloud.
5. Scorrere sopra le immagini fino alle due righe del market. Tap apre conferma,
   swipe non acquista. Gli oggetti entrano senza pop.
6. Con due account confrontare gli ID delle offerte; riaprire non cambia selezione.
7. A mezzanotte UTC il client richiede la nuova selezione.
8. Senza rete o prima della migrazione: messaggio esplicito, nessuna offerta inventata.

Gli unici oggetti da lanciare disponibili restano quelli in throw_catalog.gd.
La scelta degli slot non modifica gli ID trasmessi dal multiplayer.

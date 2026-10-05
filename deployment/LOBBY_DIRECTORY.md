# Elenco lobby pubbliche e private

Questa modifica coinvolge sia il client Godot sia il server multiplayer.
Prima di provare le nuove build online, aggiorna il servizio del server con
questa versione del repository (il Dockerfile include `network_session.gd`).
Le vecchie build vanno aggiornate: è stato aggiunto un messaggio RPC.

- Le lobby nuove sono pubbliche; la scelta «Lobby privata (con codice)» è dentro la lobby.
- Solo l'host può cambiare questa scelta dentro la lobby; il cambio azzera i pronti.
- L'elenco si aggiorna ogni cinque secondi mentre la pagina multiplayer è aperta.
- Compaiono le lobby in attesa, non piene e con host connesso.
- Le lobby private mostrano il lucchetto e richiedono il codice.
- L'elenco non contiene codici d'accesso, token di rientro o credenziali.
- La solitaria e le partite già iniziate non compaiono.

Test locali: `deployment/tests/lobby_directory_test.gd` verifica il protocollo
con un server e tre client WebSocket; `lobby_directory_ui_test.gd` verifica
dimensioni, pulsanti Indietro, immagine shop e contenuto scorrevole.

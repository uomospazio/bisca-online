# Schermate di fine partita

La grafica usa `pngUI/inGameUI` e le quattro reference. I premi non sono
calcolati dalla UI: in multiplayer provengono dalle ricevute del server.

- Multiplayer: 50 monete al vincitore, 30 agli altri; 200/100/50 punti
  stagionali rispettivamente, se la partita e la stagione sono idonee.
- L'eliminato riscatta la presentazione del premio e torna spettatore.
  Può aggiungere 50 monete guardando un video.
- Sul podio i primi due seguono lo stesso flusso, poi tornano nella stessa lobby.
- Chi ha già visto la ricompensa all'eliminazione non la riceve di nuovo;
  sul podio può scegliere un secondo video da 50 monete, una volta per partita.
- Solitaria: 30 monete e 50 punti stagionali (con stagione attiva) esclusivamente
  dopo il riscatto del video. «Continua senza premi» non assegna nulla.

## Attivazione

1. Applicare `supabase/027_match_result_ads.sql` dopo la migrazione 026.
   La 027 non è stata applicata da questi test al database remoto.
2. Ridistribuire il server dedicato insieme al client: ora pubblica i piazzamenti,
   invia anche le ricevute senza premio e certifica la fine delle partite,
   comprese quelle vinte dai bot.
3. Verificare le build iOS/Android con gli account di test AdMob già abilitati.
   Restano in vigore le restrizioni della pipeline esistente: annunci di test e
   whitelist `bisca_ad_testers`. Questo intervento non introduce verifica SSV
   degli annunci né abilita premi pubblicitari di produzione.

## Verifiche

`match_result_flow_test.gd`: eliminazione, podio, video, solitaria, doppio
riscatto, cambio account e fine partita durante la schermata di eliminazione.
Con `-- --visual` salva le quattro anteprime in `/private/tmp/bisca-result-*.png`.

`fortune_wheel_sql.mjs`: verifica anche la migrazione 027 in un database PGlite
temporaneo, inclusi retry, privilegi, separazione dei due video, vittoria di un bot
e stagione scaduta. Nessuna scrittura al Supabase di produzione.

Completare sui dispositivi reali: annuncio annullato, rete assente durante il
riscatto, ripresa dell'app, due giocatori che chiudono il podio in tempi diversi.

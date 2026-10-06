# Pubblicità premiate BISCA — configurazione di test

Sono presenti quattro pulsanti facoltativi:

- Shop: video per **20 monete**, senza limite giornaliero.
- Fine singleplayer: video per **30 monete**, una volta per partita.
- Fine multiplayer: video per **50 monete extra**, una volta per partita.
- Shop: video per cambiare le **tre offerte personali**, una volta al giorno UTC.

Il singleplayer continua a partire offline e senza premi normali. Soltanto il
video facoltativo richiede Internet. Non vengono mostrati interstitial automatici.
Chiudere un video prima della ricompensa non assegna monete né consuma il refresh.

## 1. Supabase, una volta

Nel SQL Editor eseguire **tutto** `deployment/supabase/016_rewarded_ads_test.sql`,
dopo le migrazioni precedenti. Non viene eseguito automaticamente dall'app.

Gli annunci di test non hanno verifica Google lato server: per questo solo gli
account esplicitamente abilitati possono ricevere questi premi. Nel SQL Editor,
sostituire `CODICE_BISCA` con il codice del tester (senza #):

```sql
insert into public.bisca_ad_testers(user_id)
select id from public.bisca_profiles
where upper(public_id) = upper('CODICE_BISCA')
on conflict do nothing;
```

Questo abilita anche un account ospite: non occorre email/password. Ogni tester
va abilitato separatamente. Il client non può autorizzarsi da solo.

Per revocare l'accesso:

```sql
delete from public.bisca_ad_testers
where user_id in (select id from public.bisca_profiles
                 where upper(public_id) = upper('CODICE_BISCA'));
```

Il server decide gli importi. Il registro delle richieste impedisce doppi accrediti;
il limite del refresh è sul database, non sul dispositivo. Cambiando account o
dispositivo non si ottengono altri refresh per lo stesso account/giorno. Il giorno
cambia alle **00:00 UTC**. Gli articoli posseduti possono ancora comparire.

## 2. Server multiplayer

Ridistribuire il server Godot con il nuovo `network_session.gd`: invia ai client
l'identificativo della partita già creato dal sistema premi. Il bonus multiplayer
è permesso solo se esiste il risultato della partita per quell'account in
`bisca_match_results`. Se il risultato sta ancora arrivando, il pulsante invita
a riprovare senza consumare un annuncio.

## 3. Nuove build mobile

Riavviare Godot, quindi esportare di nuovo APK e progetto Xcode. Non basta
aggiornare il PCK di una vecchia app: sono necessarie le librerie native AdMob.

È incluso **Poing AdMob 5.1.0**, commit
`615974e9f66921a54e3c71c33db0856bdbf19d13`, con i binari ufficiali **Godot 4.7.2**
Android/iOS. Le altre reti di mediazione non sono abilitate. Il plugin si occupa
delle dipendenze Gradle e Swift Package Manager a ogni esportazione, insieme al
plugin LiveKit già esistente. Usare Gradle Build per Android.

Non serve ancora un account AdMob: per questa fase sono usati SOLO gli ID Google
di esempio. I valori predefiniti del plugin per gli App ID sono:

- Android: `ca-app-pub-3940256099942544~3347511713`
- iOS: `ca-app-pub-3940256099942544~1458002511`

Gli ID rewarded nel servizio `rewarded_ads.gd` sono rispettivamente
`ca-app-pub-3940256099942544/5224354917` e
`ca-app-pub-3940256099942544/1712485313`.

In editor desktop e sul Web i pulsanti sono disabilitati: non simulano un video
e non assegnano crediti. Su telefono il caricamento avviene soltanto dopo il tap.

## 4. Prova su telefono

1. Abilitare il proprio codice tester nel database e installare la nuova build.
2. Aprire lo shop, guardare il video di test fino alla ricompensa: saldo +20.
3. Ripetere: altri +20; interrompere un video: nessun accredito.
4. Cambiare offerte: tre articoli, il secondo refresh giornaliero è bloccato.
5. Riaprire l'app o usare lo stesso account su un altro telefono: stesse offerte.
6. Finire una partita singleplayer/multiplayer: bonus +30/+50 una sola volta.
7. Interrompere Internet dopo la visione: il premio resta in attesa sul dispositivo.
   Il pulsante diventa **Recupera premio**, senza richiedere un altro video.
8. Verificare audio, ritorno dall'annuncio, ripristino app e layout sui due sistemi.

Il recupero locale è conservato in `user://rewarded_ads_test.cfg`; non cancellare
i dati dell'app con una ricompensa ancora in attesa. Il completamento registrato
nel database è sempre idempotente. Non condividere l'app di test con account che
non si intendono autorizzare a ottenere crediti di prova.

## Prima della produzione — non saltare

Questa integrazione è **di test**, non un circuito di ricompense antifrode completo:
un tester con client modificato potrebbe simulare il completamento, soprattutto
nel singleplayer offline. Non abilitare indiscriminatamente gli account.

Prima di mettere ID reali occorrono account/app AdMob, unità rewarded distinte,
consenso UMP e opzioni privacy, verifica SSV delle firme Google e dei transaction ID
per gli accrediti, valutazione ATT se si usa tracking, dichiarazioni privacy degli
store e gestione corretta dell'età del pubblico. L'attuale RPC di test va disabilitata
per gli utenti di produzione. Non basta sostituire gli ID nel codice.

Fonti: [plugin Poing 5.1.0](https://github.com/poingstudios/godot-admob-plugin/releases/tag/v5.1.0),
[annunci di test Google](https://developers.google.com/admob/android/test-ads),
[verifica SSV](https://developers.google.com/admob/android/ssv).

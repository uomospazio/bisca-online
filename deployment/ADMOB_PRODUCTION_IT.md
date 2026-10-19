# AdMob: build definitiva e dispositivi di test

Il client usa gli ID reali anche in debug. NON provare annunci sui telefoni di
sviluppo prima di averli registrati come dispositivi di test in AdMob.
Il consenso UMP rimane necessario; il debug geografico UMP non abilita annunci test.

## Configurazione AdMob ancora da completare

Per entrambe le unita' con premio:

- Android: `ca-app-pub-4798197645196973/7155046146`
- iOS: `ca-app-pub-4798197645196973/7977173220`
- Quantita' premio: `1`; tipo premio: `bisca_reward` (verificato dal server).
- Verifica lato server, URL callback:
  `https://yaphzyncmzrbrruzcarn.supabase.co/functions/v1/admob-ssv`

Non inserire un user ID fisso nelle richieste di produzione: il client imposta
`user_id` e `custom_data` (UUID della sessione) per ogni video.

AdMob > Impostazioni > Dispositivi di test > Aggiungi dispositivo: registrare ogni
telefono con ID pubblicita' Android o IDFA iOS. Non sono IMEI/seriale/UDID.
Attendere la propagazione e verificare l'etichetta test sull'annuncio.
La rimozione del dispositivo da AdMob non richiede una nuova build.
Se IDFA non e' disponibile, valutare configurazione SDK con l'hash stampato nei
log AdMob (non incollare quell'hash nel campo IDFA della console).

## Backend

Migrazione `supabase/028_admob_ssv.sql` (relativa a questa cartella) e funzione
`../supabase/functions/admob-ssv` pubblicate sul progetto Bisca il 19/10/2026.
La funzione e' pubblica senza JWT per ricevere Google, ma verifica ECDSA/SHA256,
firma DER, query originale, unita', premio, sessione, proprietario e timestamp.
Le chiavi Google sono aggiornate almeno ogni ora. Nessuna chiave privata nel client.

`bisca_begin_ad` crea una sessione di 2 ore. `bisca_verify_ad`, eseguibile solo
dal service role, registra la conferma. `bisca_claim_ad` assegna il premio con le
regole esistenti e restituisce la stessa ricevuta ai tentativi successivi.
Transazioni Google uniche impediscono il riuso su altri video.
Il client conserva i premi in attesa e riprova senza mostrare un altro video.
Sessioni verificate non ancora riscattate vengono recuperate prima di un nuovo
video, anche se il client aveva perso il callback o lo stato locale.

Il vecchio `bisca_claim_test_ad` non e' piu' accessibile ai client: le precedenti
build basate sul riscatto di test non potranno piu' riscattare video.
Premi gia' accreditati e inventari non vengono modificati. Vecchi pending di test
locali, privi di prova SSV, non sono convertiti in premi di produzione.

## Verifica prima della pubblicazione

Test automatici SQL, firma crittografica e client Godot eseguiti. Controllati sul
server permessi e rifiuto HTTP 400 di callback senza firma. Questo NON sostituisce
una prova end-to-end di un video su iPhone e Android.

Controlli generali extra: `ui_locale_test.gd` si ferma alla riga 25 (si aspetta
"HOW MANY TRICKS WILL YOU WIN?", il catalogo preesistente usa "HOW MANY TRICKS?");
`rewarded_shop_ui_test.gd` alla riga 134 di `shop_page_test.gd` (dimensione ruota
attesa 820x820). Non sono stati cambiati layout o traduzioni preesistenti per
adattare quei test durante questo intervento.

Configurare prima le due callback in AdMob. Il pulsante Verifica URL funziona
lasciando vuoti entrambi i campi opzionali: una richiesta firmata senza identita'
riceve HTTP 200 ma NON registra sessioni e NON assegna premi.
Usare anche il tool di test SSV di
AdMob con un vero UUID sessione e il relativo user_id: dati inventati vengono
rifiutati. I video test non sono una garanzia di consegna della callback SSV;
se resta in attesa, verificare con il tool SSV, senza introdurre un bypass client.
Il callback locale da solo non accredita mai premi.

Migrazione `supabase/029_shop_ad_twenty.sql`: premio video shop ridotto a 20;
le ricevute gia' accreditate restano invariate.

Verificare: video completo, video interrotto, recupero dopo perdita rete,
doppio tap, shop +20, solitaria +30 e +50 punti con stagione attiva,
bonus multiplayer +50, refresh e ruota (nessun cambiamento ai premi).
Controllare consenso UMP e label test prima di qualsiasi interazione pubblicitaria.
Solo dopo questi controlli esportare/inviare la build finale.

Documentazione ufficiale:
- https://developers.google.com/admob/android/ssv
- https://support.google.com/admob/answer/9691433?hl=it
- https://support.google.com/admob/answer/9603226?hl=it

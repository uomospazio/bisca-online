# Accesso Google e Apple — stato e attivazione

## Implementato nel progetto

- Pulsanti nella schermata iniziale e in Impostazioni → Account → Apple / Google.
- Browser di sistema: ASWebAuthenticationSession su iOS; browser esterno e Activity di ritorno su Android. Non si usa una WebView.
- Supabase OAuth con PKCE S256; codice scambiato dal client, verifica del tentativo e della callback, annullamento e timeout di cinque minuti. Token e verifier non vengono stampati.
- Due azioni distinte: **Collega questo account** conserva l'ID tramite identity linking; **Accedi a un altro account** cambia sessione senza unire i progressi. Non si esegue un login alternativo automatico se il collegamento fallisce.
- Persistenza/refresh della sessione esistente; un accesso social non viene considerato una password configurata.
- Username recuperato anche se il profilo arriva dopo la risposta OAuth, senza sovrascrivere testo già digitato.

## Non ancora verificato

Non sono stati configurati provider o credenziali nelle console. Non è stato effettuato un login reale Google/Apple su telefono. I test locali usano risposte simulate: non attestano l'attivazione dei provider.

Desktop e Web non sono implementati da questo bridge. Se Android termina il processo durante il browser, riaprire l'app e ripetere l'accesso: il verifier è volutamente solo in memoria. In Android, tornando indietro dal browser, usare Annulla accesso oppure riprovare dopo il timeout.

## 1. Supabase

Nel progetto BISCA:

1. In Authentication → URL Configuration aggiungere ai Redirect URLs `com.bisca.game://auth/**`. Il callback è `com.bisca.game://auth/callback?flow=<valore casuale>`; il pattern deve consentire questa query. Non cambiare il Site URL esistente per questo scopo.
2. Abilitare i provider Google e Apple con le rispettive credenziali.
3. Abilitare **Manual Linking** per usare “Collega questo account”.

Il callback da registrare presso Google/Apple è invece:

`https://yaphzyncmzrbrruzcarn.supabase.co/auth/v1/callback`

Non confondere il callback HTTPS del provider con quello dell'app. Confermare sempre il callback mostrato nella propria console Supabase.

## 2. Google

Configurare il consenso OAuth del progetto Google e un client OAuth di tipo **Web application** per questo flusso browser/Supabase. Registrare il callback HTTPS sopra e inserire Client ID e Client Secret nel provider Google di Supabase. Finché il consenso è in testing, aggiungere gli account di prova autorizzati.

Questa implementazione non usa l'SDK nativo Google Sign-In: i soli App ID di AdMob o i file Firebase delle notifiche non configurano questo accesso.

## 3. Apple

Configurare Sign in with Apple nell'account Apple Developer: App ID primario, Services ID per il flusso web, dominio/Return URL, chiave di firma e identificativi richiesti. Il Bundle ID iOS attuale è `com.uomospazio.bisca.dev`.

Inserire in Supabase la configurazione per il Services ID e il secret Apple generato. Per il flusso OAuth web, il secret Apple va rinnovato entro la sua scadenza (massimo sei mesi). La chiave `.p8` e i secret restano fuori dall'app e dal repository. L'export iOS include ora l'entitlement Sign in with Apple: questo codice continua a usare il browser di autenticazione, quindi l'entitlement non sostituisce la configurazione del provider.

### Export iOS con account Developer

- Firebase Messaging e il flusso push iOS sono riattivati.
- Push Notifications è impostato su Development per i test diretti su iPhone; per distribuzione verificare l'ambiente Production e il provisioning della build firmata.
- Il Team ID esistente è rimasto invariato: verificare in Xcode che corrisponda al team Developer a pagamento.
- Abilitare Push Notifications e Sign in with Apple per il Bundle ID nel portale Apple.
- Configurare la chiave APNs in Firebase per la relativa app iOS.
- Riavviare Godot e riesportare il progetto Xcode. Non basta aggiornare il PCK.

## 4. Nuove build

Android: è necessario il nuovo `addons/bisca_voice/bin/bisca_voice.aar`, che contiene `BiscaAuthCallbackActivity` e il suo intent filter. Poi esportare e installare un nuovo APK. Per ricostruirlo seguire `deployment/android/README.md`.

iOS: riesportare da Godot; `deployment/ios/setup.py` include anche `BiscaAuth.swift`. Non basta aggiornare solo il PCK. Per vecchi export Xcode rieseguire lo script di integrazione come descritto in `deployment/ios/README.md`, oppure riesportare. Compilare/installare la nuova app.

## 5. Collaudo richiesto prima della produzione

- Login Google e Apple con account nuovi, ritorno all'app e username.
- Collegamento di un ospite: verificare che ID BISCA, monete, acquisti e amici restino gli stessi.
- Provider già appartenente a un altro account: errore di collegamento, senza cambio silenzioso; quindi accesso esplicito al profilo esistente.
- Annullamento, rete assente, timeout, riavvio e callback vecchie: nessuna sessione inattesa.
- Riavvio dopo login riuscito, rinnovo della sessione, logout e nuovo login.
- Verificare la presentazione dei pulsanti rispetto alle linee guida di branding dei provider prima della pubblicazione.

## Fonti ufficiali

- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/guides/auth/social-login/auth-apple
- https://supabase.com/docs/guides/auth/sessions/pkce-flow
- https://supabase.com/docs/guides/auth/auth-identity-linking
- https://supabase.com/docs/guides/auth/native-mobile-deep-linking
- https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession

## Prompt per riprendere

«In BISCA è implementato OAuth browser Google/Apple con PKCE in social_auth.gd, bridge iOS BiscaAuth.swift e Android BiscaAuthCallbackActivity. Leggi deployment/SOCIAL_AUTH_SETUP_IT.md. Completa la configurazione dei provider Supabase/Google/Apple con le mie credenziali nelle rispettive console e verifica su Android/iPhone login, linking ospite senza perdita di progressi, annullamento e ripristino. Non considerare i test simulati prova di un login reale; non salvare secret nel repository.»

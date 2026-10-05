# Notifiche push di BISCA per dispositivi mobili

Questa prima versione registra, previo consenso, i token FCM e invia notifiche dal server per le richieste di amicizia ricevute e gli inviti alle lobby. Le versioni Web e Desktop non cambiano. L’app non invia credenziali FCM e non accetta dai client il contenuto delle notifiche.

## 1. Plugin mobile e configurazione dell’app Firebase

Il progetto include il plugin Godotx Firebase 3.1.0, con licenza MIT, per Godot 4.7; sono inclusi solo i moduli Firebase Core e Firebase Messaging. Gli XCFramework per iOS contengono solo le parti necessarie per dispositivi e simulatori iOS. Il modello di build Gradle per Android è installato localmente nella cartella ignorata da Git `android/build/`; dopo una nuova clonazione, prima di esportare seleziona **Progetto → Installa modello di build Android**.

Registra entrambi gli identificativi delle app native in un progetto Firebase, in modo che corrispondano ai preset di esportazione:

- Android: `com.bisca.game`; add `google-services.json` as requested by the plugin.
- iOS: `com.uomospazio.bisca.dev`; add `GoogleService-Info.plist` as requested by the plugin.

Scarica i due file di configurazione client e salvali nella cartella principale del progetto usando esattamente questi nomi: `google-services.json` e `GoogleService-Info.plist`. Git li ignora. In Esporta → Android seleziona il file JSON; nel preset Android sono già abilitati Firebase Core e Messaging. In Esporta → iOS seleziona il file plist e verifica che siano abilitati i plugin iOS Core e Messaging. Non aggiungere al repository chiavi di firma private o il JSON del service account. I file di configurazione client Firebase identificano il progetto, ma non autorizzano l’invio di notifiche.

Il modello Gradle Android applica il plugin Google Services solo quando trova il file JSON locale. In questo modo le build continuano a funzionare anche prima di configurare Firebase. Il preset iOS abilita l’entitlement Push Notifications. Per inviare notifiche agli iPhone sono comunque necessarie la configurazione APNs in Firebase e un team Apple Developer abilitato al provisioning push.

Per iOS, carica in Firebase una chiave di autenticazione APNs e abilita Push Notifications nell’identificativo dell’app e nell’esportazione Apple. Serve un team Apple Developer che supporti gli entitlement push; un Personal Team gratuito potrebbe non essere sufficiente per provare le notifiche su un dispositivo. Per la verifica finale usa un iPhone reale.

## 2. Schema Supabase

Esegui `deployment/supabase/014_push_devices.sql` nell’editor SQL di Supabase. Lo script crea una tabella privata per i token e due funzioni RPC. Il client registra soltanto `auth.uid()`; non concede al client permessi di lettura o scrittura diretta sulla tabella. Se hai già eseguito la versione precedente di questo script, esegui anche `deployment/supabase/015_fix_push_registration_ambiguity.sql`: corregge un’ambiguità SQL nella RPC di registrazione del token (errore PostgreSQL `42702`).

## 3. Supabase Edge Function

Distribuisci `deployment/supabase/functions/push-dispatch/index.ts` con il nome `push-dispatch` e disattiva la verifica JWT: i Database Webhook si autenticano tramite un apposito header contenente un segreto casuale. Salva questi segreti in Supabase Function Secrets, mai in Godot:

- `FCM_SERVICE_ACCOUNT_JSON`: the Firebase service-account JSON for the same Firebase project.
- `BISCA_PUSH_WEBHOOK_SECRET`: a long random value.

L’ambiente Supabase fornisce alla funzione `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`. Configura i Database Webhook per inviare richieste POST in formato JSON con l’header `x-bisca-webhook-secret: <lo stesso valore casuale>`:

- `public.bisca_friendships`: INSERT events.
- `public.bisca_lobby_invites`: INSERT and UPDATE events.

Imposta come destinazione di entrambi i webhook l’URL della funzione distribuita `push-dispatch`. Le richieste di amicizia generano una notifica solo quando viene inserita una nuova richiesta in attesa; gli inviti alle lobby scaduti vengono ignorati. Il server mostra nell’avviso il nome utente del mittente, oppure il suo codice pubblico `#...` se non ha un nome, senza includere codici stanza o segreti degli account. Dopo modifiche a questa Edge Function, distribuiscila nuovamente su Supabase; non serve esportare una nuova app.

## 4. Richiesta automatica del permesso al primo avvio e test

Al primo avvio su iOS o Android, BISCA chiede automaticamente al sistema operativo il permesso per inviare notifiche: non è necessario passare dalle Impostazioni né accedere con email e password. BISCA crea o aggiorna automaticamente la propria sessione Supabase ospite anonima. Se il permesso viene concesso, appena la sessione è online il token FCM viene associato al relativo `auth.users.id` di Supabase. Il codice pubblico `#...` rimane l’identificativo visibile agli amici e non viene usato come proprietario del token. Se il permesso viene rifiutato, il token non viene registrato e l’app non ripropone automaticamente la richiesta. Il toggle Impostazioni → Generale consente di riprovare o disattivare e riattivare la registrazione in seguito. Dopo un rifiuto, il sistema operativo potrebbe richiedere di abilitare le notifiche dalle impostazioni del dispositivo.

Per provare il sistema, concedi il permesso sul primo dispositivo, poi da un secondo account di test invia una richiesta di amicizia o un invito a una lobby mentre BISCA sul primo dispositivo è in background. Verifica che arrivi la notifica; quindi apri BISCA e controlla la schermata Amici, che aggiorna i dati ufficiali da Supabase.

La ricezione e la registrazione del token si possono controllare nel debugger di Godot tramite il signal `PushNotifications.registration_changed`. Non scrivere mai il token effettivo nei log. Se il singleton nativo Firebase non è presente, l’impostazione segnala che il plugin mobile non è installato; il resto del gioco continua a funzionare normalmente.

## Configurazione ancora necessaria e limitazioni

I moduli nativi e l’integrazione nell’app sono pronti, ma questo repository non contiene i file di configurazione client Firebase, le credenziali APNs, il segreto del service account Firebase, la funzione Supabase distribuita né i Database Webhook. Finché questi elementi non saranno configurati, non sarà possibile provare dall’inizio alla fine la registrazione e l’invio delle notifiche. L’API attuale del plugin segnala la ricezione dei messaggi quando l’app è in primo piano; questa versione non apre ancora direttamente la schermata Amici quando si tocca una notifica. Dopo averla toccata, l’utente può aprire BISCA e consultare la lista Amici, che aggiorna i dati da Supabase.

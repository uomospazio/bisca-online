# Attivare email/password

Non occorrono altre migrazioni SQL. Il pannello è in Settings → Account nel
menu principale; durante la partita è disabilitato per evitare cambi di identità.

## Configurazione Supabase
1. Authentication → Sign In / Providers: Email abilitato, conferma email attiva.
2. Abilitare manual identity linking nelle impostazioni Auth (richiesto dalla
   guida ufficiale per convertire gli utenti anonimi).
3. Lascia il modello email predefinito: usa il link di conferma, non un codice.
   Non occorre modificarlo o configurare SMTP per cambiarne il contenuto.
   In Authentication → URL Configuration imposta Site URL su
   `https://uomospazio.github.io/bisca-online/` se è ancora localhost.
   Dopo il link torna nell'istanza originale del gioco e premi
   HO CONFERMATO L'EMAIL: il gioco legge l'utente da Supabase e consente
   la scelta della password solo se email e identità sono confermate.
4. Il servizio email predefinito è solo per test: invia agli indirizzi dei membri
   del team Supabase, con limiti stretti. Per altri giocatori occorre configurare
   SMTP proprio. Nessun servizio a pagamento è stato attivato da questo codice.

## Prova reale (non eseguita automaticamente)
- Avvia da Godot, annota UID e mazzo dell'ospite.
- Settings → Account → Salva i tuoi progressi → email autorizzata.
- Apri il link ricevuto, torna nel gioco, premi HO CONFERMATO L'EMAIL e scegli
  la password. UID e mazzo devono restare uguali.
- Riavvia, quindi prova Accedi in un altro browser/dispositivo con build aggiornata.
- Controlla stesso UID e mazzo. Le modifiche pendenti di un altro ospite non devono
  sovrascrivere l'account recuperato. Nessuna fusione automatica di account.
- Verifica password errata, link scaduto, conferma non ancora fatta, rete assente
  e uscita confermata.

## Limiti di questa fase
- Non ci sono ancora Apple/Google o recupero password dimenticata.
- Le password non vengono persistite o loggate. Il refresh token continua a
  usare il salvataggio locale ConfigFile esistente: prima della release mobile
  migrare le credenziali su Keychain/Keystore.
- La UI usa LineEdit Godot per email/password: verificare tastiera su device.
- Nuova esportazione necessaria per provare da browser; nessun deploy automatico.

Riferimenti ufficiali:
- https://supabase.com/docs/guides/auth/auth-anonymous
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/guides/auth/auth-smtp

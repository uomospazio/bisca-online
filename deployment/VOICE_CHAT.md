# Chat vocale BISCA — LiveKit

## Attivazione online (solo piano gratuito)

1. Crea un progetto su https://cloud.livekit.io/ selezionando **Build ($0)**.
   Non passare a Ship/Scale e non abilitare servizi a pagamento.
2. Nelle impostazioni del progetto recupera WebSocket URL, API key e API secret.
3. Nel servizio **Render bisca-server → Environment** aggiungi:
   - `LIVEKIT_URL`: URL `wss://…livekit.cloud`
   - `LIVEKIT_API_KEY`: API key del progetto
   - `LIVEKIT_API_SECRET`: secret del progetto
4. Ridistribuisci il server Render con il nuovo codice e pubblica l'export Web
   aggiornato di `docs/` su GitHub Pages. Servono entrambi gli aggiornamenti.
5. Due persone nella stessa lobby: VOCE → ATTIVA MICROFONO → consenti il microfono.

**Non inserire API secret nel progetto Godot, in Git, in chat o nell'HTML.**
Le variabili sono lette solo dal server. Il client riceve via WebSocket autenticato
un JWT valido 60 secondi, limitato alla stanza e identità assegnate dal server,
con pubblicazione solo microfono, nessun video/data/admin.
Il JWT breve serve a entrare; non interrompe una chiamata dopo 60 secondi.

Il piano Build ha quote rigide: al superamento falliscono le nuove richieste,
senza addebiti di eccedenza. Quote condivise tra progetti gratuiti dello stesso
utente, rinnovo il primo giorno del mese. Verificare nel dashboard limiti attuali:
https://docs.livekit.io/deploy/admin/quotas-and-limits/
Il codice non può verificare quale piano hai scelto: mantenere **Build**.
Non sono stati creati account, inserite chiavi, attivati piani o eseguiti deploy.

## Funzionamento

Il server del gioco autorizza l'accesso, l'audio passa dall'infrastruttura LiveKit.
La logica delle partite e il loro WebSocket non cambiano.
VOCE è sotto INFO; puoi silenziare il microfono e continuare ad ascoltare.
DISATTIVA CHAT arresta il microfono e abbandona la stanza vocale.
CHIUDI chiude solo il pannello; la chiamata e la partita continuano.
Ogni umano ha uno slider 0–100, anche nelle impostazioni in partita.
MAIN regola anche la voce; EFFECTS no. I volumi durano per la lobby.
SDK locale e versionato: vedi LIVEKIT_DEPENDENCY.md.

La richiesta token è autenticata tramite appartenenza alla lobby e limitata
nel tempo. Le stanze vocali hanno identificativi casuali separati dal codice lobby.
Uscita/disconnessione/espulsione richiedono RemoveParticipant al servizio.
Ogni rientro usa una nuova identità vocale di sessione, evitando conflitti con
rimozioni tardive. La revoca remota dipende dalla raggiungibilità di LiveKit.
La diagnostica non mostra token, segreti, SDP o nomi di stanze.
Senza variabili Render appare un messaggio di configurazione mancante.

## Compatibilità

Versione browser HTTPS, desktop e mobile (Safari iOS incluso tramite SDK web).
Il microfono viene richiesto solo su click esplicito del pulsante HTML.
AudioContext ripreso nel gesto; volumi tramite Web Audio per iOS.
Interruzioni telefoniche, scheda in background e blocco schermo possono
sospendere l'audio: torna al gioco e tocca il pannello o riconnetti.
La versione nativa Godot mantiene il messaggio di indisponibilità.
Non è attivata la cifratura E2EE opzionale: è una chiamata gestita da LiveKit
con trasporto WebRTC cifrato, non il vecchio collegamento P2P.

## Verifiche

- `node deployment/tests/livekit_transport_test.cjs`: lifecycle con SDK/media simulati,
  mute, gain, riconnessione, cambio lobby, cancellazione, token obsoleti e permessi.
- Godot headless `--script deployment/tests/livekit_auth_test.gd`: autorizzazioni,
  JWT, scadenza, bot, identità e separazione stanze. Solo credenziali fittizie.
- Godot headless `--script deployment/tests/voice_relay_test.gd`: WebSocket/RPC reali
  locali, token solo al richiedente, rate limit e accesso negato ai non membri.
- Godot headless `--script deployment/tests/voice_settings_test.gd`: slider e impostazioni.
- `deployment/tests/voice_transport_test.html`: smoke test SDK nel browser,
  senza microfono e senza servizio cloud.

Prima di dichiarare pronta la versione online: due dispositivi reali, prima sullo
stesso Wi-Fi poi Wi-Fi/rete mobile; testare ascolto bidirezionale, mute, volume 0,
uscita/rientro, espulsione e lobby separate. Richiede progetto LiveKit configurato.

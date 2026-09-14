# Chat vocale BISCA

## Utilizzo

Nella partita multiplayer: pausa → Settings → scorri fino a CHAT VOCALE.
Ogni partecipante preme ATTIVA AUDIO e consente il microfono. Il toggle
MICROFONO ACCESO interrompe la trasmissione senza interrompere l'ascolto.
DISATTIVA ferma le tracce del microfono e chiude le connessioni.
Ogni altro umano ha uno slider 0–100; 0 lo silenzia solo per te.
MAIN regola anche la voce, EFFECTS no. I volumi individuali durano per la lobby;
non sono salvati per nome (due persone possono avere lo stesso nome).

## Pubblicazione

Occorre aggiornare **sia il server Render sia l'export Web in docs/**:
il server aggiunge identità vocali pubbliche ai partecipanti e valida/inoltra
i messaggi WebRTC. Non invia mai i token privati di rientro ai giocatori.
Pubblicare solo l'HTML non aggiorna il server. Nessun servizio è stato attivato
e nessun deploy è stato eseguito da questa modifica.

## Compatibilità e limiti

Il trasporto implementato è quello della **versione browser HTTPS** su desktop,
iOS/iPadOS e Android con WebRTC/getUserMedia/Web Audio disponibili. Non è un
backend vocale per gli eseguibili nativi Godot: lì viene mostrato un messaggio
esplicito. Telefoni/tablet fisici non sono stati verificati in questo ambiente.
La ricezione usa GainNode, non audio.volume, per la regolazione su iOS.
Tab in background, schermo bloccato e interruzioni telefoniche possono sospendere
l'audio; tornare al gioco e premere RIPRENDI AUDIO. Se il microfono è terminato,
va autorizzato/attivato nuovamente. Usare cuffie evita il feedback tra dispositivi.

La configurazione predefinita usa STUN e audio diretto cifrato WebRTC, non un
relay audio sul server del gioco. Alcune reti mobili/NAT/firewall richiedono
**TURN**: senza un relay non è possibile garantire ogni combinazione di reti.
Il campo ProjectSettings `bisca/voice/ice_servers` può contenere un array di
configurazioni RTCIceServer. Non inserire segreti permanenti nell'export pubblico;
per TURN pubblico usare credenziali temporanee ottenute da un backend e limiti
di utilizzo. Non sono inclusi account o servizi a pagamento.

## Test locali

- Godot: `--headless --path . --script deployment/tests/voice_settings_test.gd`
- HTTP locale dalla root del progetto, poi aprire
  `/deployment/tests/voice_transport_test.html` e premere il pulsante di test.
  Usa oscillatori sintetici e due peer WebRTC reali: non cattura microfoni.
  Verifica tracce in entrambe le direzioni, pacchetti ricevuti, volumi, mute,
  isolamento della stanza, riattivazione e rilascio delle tracce.

Prima del rilascio generale verificare una partita tra Safari su iPhone,
Safari su iPad, Chrome su Android e desktop, prima su Wi-Fi e poi su reti diverse.

# Bisca — guida alle modifiche

Il progetto attivo è questa cartella `bisca-online`; il progetto Godot nella
cartella superiore è distinto. La scena iniziale è `scenes/balatro/balatro.tscn`.
I percorsi della tabella sono relativi a `scenes/balatro/scripts/`.

## Dove intervenire

| Cosa vuoi cambiare | File e punto di partenza |
| --- | --- |
| Home, personaggio, titolo, posizione pulsanti | `main_menu.gd`: costanti iniziali, `_ready`, `_switch_page` |
| Foto e nome personali | `main_menu.gd`: `_set_home_profile`, `_send_profile_name`; `profile_picker.gd` e `.js` per acquisizione foto |
| Schermata lobby e tessere | `network_lobby.gd`: `setup` crea il layout, `_update` riceve lo stato, `refresh_own_card` aggiorna la tua card |
| Vite, numero carte e bot da scegliere | `match_options.gd`; frecce in `option_stepper.gd` |
| Colori e stili comuni | `lexispell_style.gd`; alcuni colori di titolo, badge e popup web sono ancora definiti nei relativi file |
| Semi nello sfondo menu | `../shaders/menu_suits.gdshader`: `paper`, `ink_opacity`, passo griglia e velocità |
| Feltro verde in partita | `../shaders/cartoon_felt.gdshader`: base, bordi, centro |
| Attivazione dei due sfondi | `match_controller.gd`: materiali creati in `_ready`, segnale `game_ui.visibility_changed` |
| Estetica mazzo | `deck_selector.gd`; cartelle front e preferenze in `game_settings.gd` |
| Regole, punteggi, vite | `match_rules.gd` (non modificare le regole attraverso la UI) |
| Scelte bot | `bot_policy.gd`; esecuzione locale in `local_bot_policy.gd` |
| Flusso partita e animazioni | `match_controller.gd`; cercare la funzione relativa alla fase interessata |
| Posizione giocatori | `match_controller.gd`: `SEAT_POSITIONS` |
| Cuore, contatore e nome animato | `player_badge.gd`: `HEART_POSITION`, `HEART_SIZE`, `animate_life_change`, `_draw_idle_name` |
| Carte in mano e trascinamento | `hand.gd` gestisce la mano; `card.gd` la singola carta |
| Oggetti lanciabili | `throw_catalog.gd` per gli asset; `throw_objects.gd` per animazioni e cooldown |
| Timer turno | `match_controller.gd`: `TURN_SECONDS`, `_process`; il server ha la propria gestione dei turni |
| Pausa e conferme | `pause_menu.gd` |
| Suoni | `game_audio.gd`, `button_audio.gd`; volumi e preferenze in `game_settings.gd` |
| Chat vocale | `voice_chat.gd`, `voice_transport.js`; autenticazione/configurazione server nei file LiveKit |
| Messaggi multiplayer | `network_session.gd`: `request` valida i comandi, `_broadcast` invia lo stato |
| Visualizzazione partita online | `online_match.gd` e relativi handler in `match_controller.gd` |

## Flusso da tenere presente

Singleplayer: input → controller → regole locali → aggiornamento UI/animazioni.
Multiplayer: input → comando al server → validazione → snapshot → UI dei client.
La propria tessera lobby offre anche un aggiornamento locale immediato del profilo.
Cambiare solo la UI non cambia le regole del server: quando modifichi i comandi
di rete devi aggiornare anche il server pubblicato.

## Ottimizzazioni conservative (27 settembre 2026)

- Le carte ferme non eseguono più `_process`: il setter `following_mouse` lo
  abilita durante il drag e sincronizza subito l'ombra. I tween rimangono attivi.
- I nomi dei profili e i sottotitoli conservano le misure dei caratteri finché
  testo/font non cambiano. Il movimento delle lettere e le loro dimensioni restano uguali.
- I profili nascosti non richiedono continuamente un ridisegno e il menu nascosto
  non calcola il parallax. Il tempo dell'animazione dei nomi continua ad avanzare.
- La lobby ricostruisce gli slot solo quando cambiano partecipanti o identità
  locale; opzioni, foto e microfono continuano ad aggiornarsi separatamente.
- Le icone di stato vocale non ricaricano la stessa risorsa a ogni aggiornamento.

Non sono stati ridotti FPS, risoluzione, qualità immagini, tempi bot o frequenza
di rete. Non sono state eliminate cartelle o risorse: potrebbero servire ai tuoi
lavori futuri. Questi interventi riducono lavoro evitabile, ma non costituiscono
una misura del risparmio di batteria: va confrontato sullo stesso telefono,
con uguale luminosità, numero di giocatori, durata e chat vocale attiva/spenta.

## Verifica prima di pubblicare

I test si trovano in `deployment/tests/`. Esempio (dal progetto):

```sh
"/Users/iosonospace/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --script deployment/tests/ui_efficiency_test.gd
```

Controlla inoltre: trascinamento e ritorno carte, hover, Jolly, predizioni,
perdita vite, cambio foto/nome, ritorno lobby e chat su due dispositivi.
I test headless non verificano la resa grafica GPU né il consumo reale.

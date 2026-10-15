# Domande e risposte BISCA

## Funzionamento attuale

La chat è stata sostituita da un browser Q&A: il pulsante della home apre
le domande raggruppate in Regole e carte, Partite e multiplayer, Account e
profilo, Personalizzazione e Shop, Impostazioni e chat vocale. Ogni card
apre la risposta; Indietro torna all'elenco conservandone lo scorrimento.
La riapertura mostra sempre l'elenco. Non ci sono input libero o cronologia.

`assistant_chat.gd` legge direttamente `assistant_knowledge.json`: per
modificare una card usare `it/en.examples[0]`, per la risposta `it/en.answer`.
Le categorie `shop` e `custom` sono raggruppate nella stessa sezione.
Motore e contesto precedenti sono conservati ma non usati dall'interfaccia.
Il test `assistant_chat_test.gd` verifica gruppi, tutte le risposte, Indietro,
riapertura e layout. Le note sotto descrivono la precedente implementazione.

## Implementazione precedente (non attiva)

Nella home, il pulsante blu con punto interrogativo (in basso a sinistra) apre
la chat. Nessuna API, chiamata HTTP, scrittura di conversazioni su disco o
modifica a Supabase/Render. La memoria dura quanto il nodo della home e conserva
al massimo 60 messaggi; le domande sono limitate a 300 caratteri.

## Componenti

- `scenes/balatro/data/assistant_knowledge.json`: 25 argomenti bilingui,
  esempi, parole chiave/sinonimi, risposte ufficiali, categoria e correlati.
- `assistant_engine.gd`: normalizzazione, sinonimi, correzione di un errore
  su parole lunghe, punteggio lessicale, soglia e margine di ambiguità.
- `assistant_context.gd`: ultimo argomento e cronologia limitata in memoria.
- `assistant_chat.gd`: overlay, suggerimenti, invio, touch scroll e tastiera.
- `home_art_ui.gd`: pulsante con asset `assistenteUI/buttonAssistente.png`.

Per richiamarlo in futuro da un altro punto:

```gdscript
preload("res://scenes/balatro/scripts/assistant_chat.gd").open(host_control)
```

La funzione riusa il pannello dello stesso host e non mette SceneTree in pausa.
Non è stato aggiunto alcun ingresso in partita o nel tutorial. Prima di farlo
verificare i loro gestori `_input`, affinché non trattino input sopra l'overlay
come azioni di gioco. Timer e connessione non vengono modificati dall'assistente.

## Estensione del database

Ogni argomento contiene `id`, `category`, `context`, `related` e due voci `it`/`en`
con `examples`, `keywords` e `answer`. Le parole chiave comprendono anche
formulazioni alternative; le equivalenze morfologiche sono nel motore.
Aggiungere esempi e parole chiave distintive, non solo termini generici.
Usare soltanto risposte verificate nel codice. I prezzi sono quelli della
migrazione 018 e vanno aggiornati se cambia il catalogo.
Il JSON è incluso esplicitamente negli export Web, Android e iOS.
Non esiste sincronizzazione remota in questa versione.

## Test

Avviare con Godot `--headless --path . --script` seguito da:

- `deployment/tests/assistant_engine_test.gd`: esempi bilingui e domande
  indipendenti, refusi, ambiguità, fuori argomento, follow-up e limiti memoria.
- `deployment/tests/assistant_chat_test.gd`: layout desktop/mobile e spazio
  ridotto dalla tastiera simulato, invio, input vuoto, riapertura, nessuna pausa.
- `deployment/tests/home_art_ui_test.gd`: regressione home.

Con renderer grafico il test chat accetta `-- --snapshot` e salva
`/tmp/bisca-assistant.png`.

## Limiti

È ricerca locale di risposte, non comprensione linguistica generale. Non può
consultare saldo, transazioni, account o server, né eseguire operazioni.
I follow-up generici riprendono l'ultimo argomento e propongono correlati;
non viene dedotto arbitrariamente un intento mancante. Domande non riconosciute
o troppo ambigue richiedono chiarimenti. Non tutte le parafrasi sono coperte.
Safe area e altezza tastiera usano DisplayServer; il layout è testato in desktop,
ma apertura/chiusura della tastiera reale richiede verifica su iOS, Android e Web.

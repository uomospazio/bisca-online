# Italiano e inglese

La lingua e' salvata da `GameSettings` e si sceglie sia nell'intro sia nelle
impostazioni. L'italiano rimane il testo sorgente: il rendering inglese non
modifica le stringhe usate dalla logica del gioco.

## Immagini

Per qualsiasi immagine in `pngUI`, affiancare `nome_en.png` a `nome.png`.
`UiLocale.resource(path)` sceglie la variante inglese se esiste; altrimenti
usa l'originale, senza disegnare traduzioni sopra l'immagine. Nomi e maiuscole
devono corrispondere. Non vengono riconosciuti suffissi diversi da `_en`.
Le immagini gia' presenti a schermo vengono aggiornate al cambio lingua.

## Testi

Le traduzioni sono in `scenes/balatro/scripts/ui_english.gd`. Label, pulsanti,
tooltip e RichTextLabel usano il sistema di traduzione Godot. Sono gestiti
anche BBCode, maiuscole, paragrafi e messaggi formattati con valori variabili.
Per testo disegnato manualmente o inserito con `add_text`, usare
`UiLocale.text(testo)` e ridisegnare al cambio lingua. Non tradurre username,
codici, ID di rete o nomi scelti dagli utenti.

Test: `deployment/tests/ui_locale_test.gd`, `intro_art_ui_test.gd` e
`tutorial_test.gd`. Le prove cambiano lingua in memoria senza salvare le
preferenze dell'utente.

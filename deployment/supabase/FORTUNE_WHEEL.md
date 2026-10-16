# Ruota della fortuna

Applicare `026_fortune_wheel.sql` nel SQL Editor Supabase **dopo 025**.
La migrazione non e' stata pubblicata automaticamente.

- Corona/mazzo oro: 2%. Assegna `deck_back_13`; se gia' posseduto, 5000 monete.
- 5000 monete: 2%; 1000 monete: 7%; 50 monete: 14%.
- Pomodoro, poop, fazzoletti: 25% ciascuno, nessun oggetto o moneta.
- Ogni annuncio completato autorizza un giro; nessun limite giornaliero.
- `claim_id` conserva la stessa estrazione nei retry. Estrazione, inventario,
  saldo e ricevuta sono nella stessa transazione.
- Back13 non e' acquistabile e le rotazioni precedenti vengono riparate alla
  lettura. Gli eventuali proprietari preesistenti conservano il mazzo.
- Il front oro ha ID 3; l'ID 2 rimane ritirato. Front 3 richiede back13 sia
  nel selettore client che nel trigger sul profilo.

## Annunci e pubblicazione

Rimane il circuito **di test** gia' presente: ID AdMob test, consenso UMP e
whitelist `bisca_ad_testers`. La conferma dell'annuncio proviene ancora dal
client, **non da AdMob SSV**: prima della pubblicazione con premi reali serve
la verifica server-to-server. L'estrazione e l'accredito avvengono sul server,
ma questa migrazione non rende il circuito di test resistente a richieste
di annunci falsificate da un tester.

Non rieseguire le vecchie migrazioni catalogo per riattivare back13: il vincolo
`bisca_gold_wheel_exclusive` impedisce di rimetterlo in vendita.

## Verifiche locali

- `deployment/tests/fortune_wheel_sql.mjs`: distribuzione esatta, retry,
  nessun premio per oggetti perdenti, duplicato oro, esclusivita' e permessi.
- `deployment/tests/shop_page_test.gd`: hover separato, navigazione, settori,
  tutte le 40 carte oro e selezione vincolata all'inventario.
- `deployment/tests/rewarded_ads_test.gd`: nessuna animazione prima della
  conferma server, recupero offline, animazione monete e giri senza limite.

La composizione e' in `fortune_wheel.gd`. I settori doppi sono solo grafici:
il client sceglie un settore compatibile con l'esito ricevuto, non il premio.

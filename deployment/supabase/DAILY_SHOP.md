# Shop giornaliero — nuova UI

Applicare `025_shop_six_offers.sql` dopo le migrazioni fino alla 024, prima di distribuire il nuovo client. Non e' stata applicata automaticamente su Supabase.

- Sei offerte: due dorsi, due avatar, due oggetti lanciabili. Ogni colonna contiene una categoria.
- Solo articoli disponibili e non default; prezzi e inventari invariati.
- Rotazione condivisa giornaliera, reset a mezzanotte UTC. Countdown calcolato dalla durata restituita dal server.
- Re-roll personale con la stessa pubblicita' esistente, una volta al giorno. Mantiene 2/2/2 e preferisce articoli diversi se il catalogo lo consente.
- Le vecchie rotazioni con tre articoli vengono aggiornate alla prima lettura, senza ripristinare il re-roll gia' consumato.
- Servono almeno due articoli acquistabili per categoria; altrimenti la RPC restituisce SHOP_CATEGORY_INCOMPLETE invece di duplicare offerte.
- Video shop: **50 monete**. Solitaria 30 e bonus multiplayer 50 restano invariati. Si mantiene la conferma transazionale e l'animazione monete esistente.
- Annunci ancora limitati ai tester della migrazione 016; non viene rimossa alcuna restrizione e non viene aggiunta una verifica SSV di produzione.
- Ruota della fortuna: solo grafica/hover, nessun annuncio, premio o azione.

La schermata usa `shopUI/slotShop.png` come composizione intera, senza il vecchio banco/sfondo nero. Mantiene lo sfondo del menu, il supporto al creatore e le conferme acquisto. Si adatta alla safe area con scala uniforme.

Test: `deployment/tests/shop_page_test.gd` (anche `-- --visual`), `shop_rotation_sql.mjs` con PGlite. Gli acquisti restano validati dalla RPC atomica esistente; non vengono limitati esclusivamente alle offerte del giorno.

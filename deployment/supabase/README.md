# Profilo BISCA — prima configurazione

1. Nel progetto Supabase corretto apri SQL Editor → New query.
2. Incolla tutto `001_profiles.sql` ed esegui Run una sola volta.
3. Avvia il gioco aggiornato da Godot. In Table Editor → bisca_profiles
   comparirà una riga con lo stesso id dell'utente Authentication.
4. Conferma un altro dorso/front: controlla deck_back e deck_front nella riga.
5. Riavvia il gioco: deve usare lo stesso profilo.

La migrazione non è stata applicata automaticamente. Il client non dispone
di credenziali amministrative. Per il browser serve una nuova esportazione web.

## Organizzazione
- account_session.gd: identità ospite e rinnovo sessione.
- account_profile.gd: lettura cloud, creazione profilo e coda locale del mazzo.
- game_settings.gd: preferenze locali e audio, invariati.

Il profilo contiene username riservato per una futura schermata account (ora
NULL), non il nome o la foto della lobby. Non contiene crediti, XP o inventario.
Front 0–2, dorso 1–12. Aggiornare vincoli SQL se si aggiungono nuovi mazzi.
RLS e privilegi limitano lettura/scrittura al proprio id; il client può modificare
solo le preferenze del mazzo, non username o created_at. Nessuna chiave segreta
va nel gioco. Riferimento: https://supabase.com/docs/guides/database/postgres/row-level-security

## Conflitti e verifiche
Al primo caricamento prevale il cloud, salvo modifiche locali ancora da inviare.
Una conferma offline resta in coda; errori cloud ritentano dopo 60 secondi.
Dispositivi contemporanei: prevale l'ultima scrittura; niente realtime per ora.
L'identità è ancora quella ospite del dispositivo: il recupero su altri dispositivi
richiederà collegamento a un account. Prima di introdurre cambio account vanno
separate anche le code locali per identità.

Test locale con risposte simulate: deployment/tests/account_profile_test.gd.
Prima del rilascio verificare sul database con due utenti che ciascuno legga
solo la propria riga e non possa inserire/modificare quella dell'altro; verificare
anche che una richiesta senza sessione non possa leggere o scrivere profili.
I test locali non sostituiscono queste verifiche RLS sul progetto Supabase.

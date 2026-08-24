# TODO

Roadmap per riprendere in mano il progetto: raccoglie sia le **Issue GitHub aperte** sia le **criticità emerse dall'analisi del codice** non ancora tracciate altrove. Le sezioni sono ordinate per priorità d'attacco consigliata.

---

## 1. Quick wins — pipeline CI

Item piccoli, ad alto rendimento. Da fare per primi così la CI smette di rumoreggiare prima del lavoro grosso.

- [ ] **Fix typo `&` → `&&`** in `.github/workflows/template.yml` righe 157 e 166: il `push` runner finisce in background, lo step termina prima e i tag possono non essere effettivamente pushati.
- [ ] **Calcolare `MANGOS_SHA1` / `DATABASE_SHA1` una sola volta** e passarli da `build-builder` a `build-runner` via `outputs`. Oggi i due job rifetchano il SHA upstream indipendentemente: se nel frattempo arriva un commit, builder e runner finiscono disallineati.
- [ ] **Collassare `build-classic.yml` / `build-tbc.yml` / `build-wotlk.yml`** in un singolo workflow con `strategy.matrix.expansion: [classic, tbc, wotlk]`. Tre file identici al netto di una stringa.
- [ ] **Indagare la cache buildx** disabilitata in `a73c598`. Probabili soluzioni: `cache-from: type=registry,ref=...:cache` / `cache-to: type=registry,mode=max` oppure `type=gha`. Oggi ogni nightly ricompila tutto da zero × 3 espansioni.
- [ ] **Multi-arch images**: `--platform linux/amd64,linux/arm64` in buildx. ARM64 sempre più rilevante (Mac M-series, Pi5).
- [ ] **CI lint**: aggiungere step `shellcheck` (script in `builder/`, `runner/`, `cmangos-*.sh`) e `hadolint` (Dockerfile).
- [ ] **Dependabot / Renovate**: bump automatico per `mariadb:11.8`, `phpmyadmin:5.2`, action versions.

## 2. UX di setup — footgun da rimuovere

Frizioni che fanno perdere utenti al primo run.

- [x] **Issue "network not found" nel getting started** *(fatto 2026-07-25)*: `builder` è ora un servizio compose con profile (`docker compose run --rm builder …`) e i `run.sh` sono thin wrapper → la rete/volumi li crea sempre Compose, in qualsiasi ordine di passi. Aggiunti anche limiti CPU/RAM via env var (`*_CPUS_LIMIT`/`*_MEMORY_LIMIT`, default: mangosd 8g, mariadb 2g, realmd/phpmyadmin 512m). Wiki aggiornata in locale (`cmangos-docker.wiki/`): da pushare.
- [x] **Sincronizzare `.env.example` con `.env`** *(fatto 2026-07-25)*: aggiunti `THREADS`, `REALMD_PORT`, `MANGOSD_PORT`, `PHPMYADMIN_PORT` e le nuove variabili dei limiti risorse.
- [ ] **Smettere di committare `.env`**: rimuoverlo dal tracking e aggiungerlo a `.gitignore`. Le credenziali attuali sono throwaway ma il pattern è da non insegnare.
- [x] ~~**Documentare `mangosd_data` come volume `external`**~~ *(superato 2026-07-25)*: il volume non è più `external` ma compose-managed con `name:` esplicito (verificato: Compose adotta senza errori il volume pre-esistente senza label degli utenti già installati). #19 resta aperta per la pagina wiki dedicata al volume.
- [x] **Healthcheck su `mariadb`** *(fatto 2026-07-25)*: `healthcheck.sh --connect --innodb_initialized` + `depends_on: service_healthy` su `builder`/`mangosd`/`realmd`; aggiunti anche healthcheck TCP (bash `/dev/tcp`) su `mangosd` (start_period 10m per mappe+bot) e `realmd`. Verificato sul volume di produzione esistente.
- [x] **`restart: unless-stopped`** sui servizi di compose *(fatto 2026-07-25; escluso il one-off `builder`)*.
- [ ] **Aggiornare le immagini di terze parti in `docker-compose.yml`** *(stato al 2026-07-08)*: `phpmyadmin:5.2` è già l'ultima serie (patch 5.2.3) → basta un `docker compose pull` periodico. `mariadb:11.8` è l'LTS corrente (patch 11.8.8), ma esistono le serie rolling 12.2/12.3 (12.3 candidata prossima LTS) → decidere la policy: restare su LTS (pull periodico) o major bump. In caso di bump major su dati di produzione: backup preventivo + `MARIADB_AUTO_UPGRADE=1` nell'environment (l'immagine ufficiale esegue `mariadb-upgrade` sul volume esistente) e verificare la compatibilità del client `mariadb` nel builder. Collegato al punto Dependabot/Renovate in §1, che automatizzerebbe i bump futuri.
- [ ] **Flag `--yes` per `init-db`, `update-db --world`, `extract`** in `builder/entrypoint.sh`: oggi usano `read -p`, non automatizzabili in CI/cron.

## 3. Issue GitHub da chiudere

### 3.1 Refactoring abilitante

- [ ] **[#38](https://github.com/Byloth/cmangos-docker/issues/38)** — Migliorare la gestione dei file di configurazione: oggi `_replace_conf` (`runner/entrypoint.sh:8`) usa `sed` riga per riga, non gestisce sezioni `[Section]` né segnala chiavi sconosciute, e l'utente non vede mai la lista completa delle opzioni disponibili. Approccio: rendere il `.dist` accessibile come riferimento + parser sezione-aware.

### 3.2 Quick wins funzionali

- [ ] **[#7](https://github.com/Byloth/cmangos-docker/issues/7)** — Aggiungere metadata nel backup `.tar.gz`: versione script (`SCRIPT_VERSION` esiste già in `builder/entrypoint.sh:4`), versione server, SHA core/db, timestamp, espansione.
- [ ] **[#18](https://github.com/Byloth/cmangos-docker/issues/18)** — Comando per riusare `maps`/`vmaps`/`dbc` già estratti: aggiungere sotto-comando `import-resources <path>` in `builder/entrypoint.sh` accanto a `extract`. Riusa la stessa logica di destinazione (`${VOLUME_DIR}/{maps,vmaps,dbc,...}`).
- [ ] **[#30](https://github.com/Byloth/cmangos-docker/issues/30)** — Migrare gli Issue Templates a Issue Forms (YAML).

### 3.3 Bug

- [ ] **`update-db` non applica mai gli SQL dei PlayerBots** *(scoperto 2026-07-08)*: `InstallFullDB.sh -UpdateCore` e `-World` ignorano `PLAYERBOTS_DB="YES"` (upstream li applica solo con `-InstallAll` o con l'opzione 8 del menù "Advanced DB management"). Un DB inizializzato senza bots e aggiornato con `update-db --world` resta senza tabelle `ai_playerbot_*` → segfault di `mangosd` all'avvio ("Loading Fish locations"). Fix proposto: funzione `install_playerbots_db()` in `builder/entrypoint.sh` che, dopo `InstallFullDB.sh -World`, applica `src/modules/PlayerBots/sql/world/*.sql` + `world/<expansion>/*.sql` al world DB e `sql/characters/*.sql` al characters DB via `mysql_execute`, se `PLAYERBOTS_DB="YES"` nella config. Workaround manuale: `manage-db` → 5 → 8.
- [ ] **Collation mismatch delle tabelle PlayerBots su MariaDB 11** *(scoperto 2026-07-08)*: MariaDB 11 crea le nuove tabelle con `utf8mb3_uca1400_ai_ci`, mentre le tabelle storiche (`characters`, `account`, ...) sono `utf8mb3_general_ci`. Le JOIN del modulo PlayerBots (es. `ai_playerbot_names` ⋈ `characters`) falliscono con "Illegal mix of collations" e la creazione dei personaggi bot muore **in silenzio** ("No more names left for random bots"). Fix applicato a mano in produzione: `ALTER TABLE ... CONVERT TO CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci` su tutte le `ai_playerbot_*`/`ahbot_*`. Fix strutturale in `database/my.cnf` (`character-set-server`/`collation-server` + `character_set_collations = utf8mb3=utf8mb3_general_ci`, quest'ultima necessaria perché gli SQL dichiarano `DEFAULT CHARSET=utf8` esplicito): **applicato nel working tree il 2026-07-08**, verificato su container di test; richiede un riavvio del container `mariadb` per entrare in vigore e vale solo per le tabelle create da lì in poi. Resta da valutare la conversione automatica delle tabelle esistenti nella futura `install_playerbots_db()` di `builder/entrypoint.sh`.
- [ ] **Segfault di `mangosd` con mass-login dei PlayerBots** *(2026-07-08, ambiente di produzione)*: con `MinRandomBots = MaxRandomBots = 1000` (default del `.dist`) il server crasha con SIGSEGV ~110s dopo lo startup, riproducibile 3/3. Pattern compatibile con [cmangos/issues#3912](https://github.com/cmangos/issues/issues/3912) (bug di gestione grid al login dei bot, chiuso upstream come "not planned": login veloci → crash in minuti, diluiti → ore). Mitigazione applicata in `runner/config/aiplayerbot.conf`: 200 bot, `RandomBotLoginAtStartup = 0`, `RandomBotsMaxLoginsPerInterval = 5`. Se non basta: disattivare i random bot (`MinRandomBots = 0`) tenendo i bot on-demand. Follow-up utili: `restart: unless-stopped` nel compose (già in §2), build con simboli di debug + core dump leggibili per backtrace da segnalare upstream.
- [ ] **[#12](https://github.com/Byloth/cmangos-docker/issues/12)** — Malfunzione `mktemp` durante `ExtractResources.sh`. Probabile causa: `TMPDIR=${VOLUME_DIR}/tmp` (`Dockerfile:144`) finisce su un volume che non supporta tutte le syscall richieste. Tentare: `mkdir -p ${TMPDIR}` esplicito in entrypoint e/o non sovrascrivere `TMPDIR` per il sotto-processo `extract`.

### 3.4 Documentazione

- [ ] **[#5](https://github.com/Byloth/cmangos-docker/issues/5)** *(epic)* — Coordinatore generale della documentazione.
- [ ] **[#19](https://github.com/Byloth/cmangos-docker/issues/19)** — Pagina wiki dedicata al volume `mangosd_data`.
- [ ] **[#26](https://github.com/Byloth/cmangos-docker/issues/26)** — Guida AHBot / PlayerBots (anche solo "non supportato out-of-the-box, ecco come abilitarlo").
- [ ] **Completare wiki "Customization"** (oggi solo `TODO: Write this page.`).
- [ ] **Completare wiki "Use in Production"** (oggi solo `TODO: Write this page.`).
- [ ] **Completare wiki "Install Updates"** (la sezione "Updating the Working Directory" è `TBD`).

### 3.5 Feature grosse / epic

Da valutare a parte, non bloccanti per il resto.

- [ ] **[#27](https://github.com/Byloth/cmangos-docker/issues/27)** — Supporto interfaccia SOAP (build flag, esposizione porta `7878`, credenziali via env). Quando c'è: sostituire l'healthcheck TCP di `mangosd` con un check "profondo" via SOAP (il TCP check verifica solo il socket, non che il server risponda davvero).
- [ ] **[#28](https://github.com/Byloth/cmangos-docker/issues/28)** — Graceful shutdown via SOAP (dipende da #27, intercetta `SIGTERM`). *Nota 2026-07-25*: il prerequisito segnali è risolto — con `exec gosu` in `runner/entrypoint.sh` mangosd/realmd sono PID 1 e ricevono il `SIGTERM` di `docker stop` direttamente (verificato: exit 0 in 0.3s contro SIGKILL a ~10s di prima); nel compose c'è `stop_grace_period: 2m` su `mangosd` per dare tempo al world save. Resta la parte SOAP per lo shutdown "annunciato" (broadcast ai player, delay configurabile). Il fix è dormiente finché non viene ripubblicata l'immagine runner.
- [ ] **[#6](https://github.com/Byloth/cmangos-docker/issues/6)** — Web UI di gestione (epic, dipende da #27).
- [ ] **[#37](https://github.com/Byloth/cmangos-docker/issues/37)** — Immagine opzionale per AIPlayerbot + LLM.

## 4. Da decidere

- [ ] Mantenere il modello "container builder separato per manutenzione" o unificare/snellire? Oggi il `Dockerfile` produce due target distinti ma duplica installazione `tzdata`, `useradd`, env vars.
- [ ] Policy di versioning delle immagini: oggi `latest` + `<sha>` + `<ref>` + `<data>`; aggiungere `1.x` semver?

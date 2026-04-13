#!/usr/bin/env bash
# ============================================================
#  rsyslog-mgmt.sh  –  RSyslog-Server Verwaltungsscript
#
#  Muss als root auf dem RSyslog-Server ausgeführt werden.
#
# ── Voraussetzungen ─────────────────────────────────────────
#
#  Pakete installieren:
#    apt install acl mailutils rsyslog
#
#  Pakete & Zweck:
#    acl        – setfacl/getfacl für granulare Datei-Berechtigungen
#                 (User erhalten Lesezugriff nur auf zugewiesene Host-Verzeichnisse)
#    mailutils  – 'mail'-Befehl für den alert-Test; ommail nutzt direkten SMTP
#    rsyslog    – Syslog-Daemon mit ommail-Modul (in Debian-Paket enthalten)
#
#  Mail-Versand (alert-Funktionen):
#    RSyslog nutzt das eingebaute ommail-Modul (kein externes Tool nötig).
#    Ein lokaler MTA (z. B. postfix) oder ein SMTP-Relay muss erreichbar sein.
#    Standard-Konfiguration: SMTP-Server = localhost, Port 25.
#    Anpassen in /etc/rsyslog.d/15-mail-alerts.conf oder über die Variablen
#    ALERT_SMTP_SERVER / ALERT_SMTP_PORT / ALERT_MAIL_FROM weiter unten.
#
#  Dateisystem:
#    Das Filesystem, auf dem /var/log/remote/ liegt, muss ACL-Unterstützung
#    haben. Prüfen mit: tune2fs -l /dev/<gerät> | grep "Default mount options"
#    Falls nicht aktiv: mount -o remount,acl /var/log/remote
#    Dauerhaft in /etc/fstab: defaults,acl als Mount-Option eintragen.
#
# ── Befehle ─────────────────────────────────────────────────
#
#    user   add <name> [--host <hostname>]   – User anlegen (+optionale Quellbeschränkung)
#    user   del <name>                       – User löschen
#    user   list                             – Alle Log-User auflisten
#    user   grant <name> <hostname>          – Zugriff auf Host-Logs gewähren
#    user   revoke <name> <hostname>         – Zugriff auf Host-Logs entziehen
#    user   show <name>                      – Berechtigungen eines Users anzeigen
#
#    source list                             – Konfigurierte Quell-Hosts anzeigen
#    source add <ip> <hostname>              – Erlaubten Sender hinzufügen
#    source remove <ip>                      – Erlaubten Sender entfernen
#    source check                            – Aktive Sender (letzte 24h) anzeigen
#
#    log    show <hostname> [--follow]       – Logs eines Hosts anzeigen
#    log    search <hostname> <muster>       – In Logs eines Hosts suchen
#    log    disk  [hostname]                 – Speicherverbrauch anzeigen
#    log    rotate                           – Log-Rotation manuell auslösen
#    log    clean <tage>                     – Logs älter als N Tage löschen
#    log    archive <hostname> <tage>        – Logs eines Hosts archivieren (tar.gz)
#
#    alert  add <email> [--level <0-3>] [--host <hostname>]
#                                            – E-Mail-Alarmierung einrichten
#                                              Level: 0=emerg 1=alert 2=crit 3=err
#    alert  del <email>                      – Alarmierung für E-Mail entfernen
#    alert  list                             – Alle konfigurierten Alarme anzeigen
#    alert  test <email>                     – Test-Mail senden
#    alert  apply                            – RSyslog-Konfiguration neu generieren
#
#    service status                          – RSyslog-Status anzeigen
#    service restart                         – RSyslog neu starten
#    service check                           – Konfiguration prüfen (--syntax-check)
#    service stats                           – Interne Statistiken anzeigen
#    service errors                          – Fehler im RSyslog-Journal anzeigen
#
# ============================================================

set -euo pipefail

# ── Konfiguration ────────────────────────────────────────────
LOG_DIR="/var/log/remote"
LOG_GROUP="logviewers"
SOURCES_CONF="/etc/rsyslog.d/05-allowed-senders.conf"
ALERTS_DB="/etc/rsyslog-mgmt-alerts.conf"
ALERTS_CONF="/etc/rsyslog.d/15-mail-alerts.conf"
STATS_LOG="/var/log/rsyslog-stats.log"
ARCHIVE_DIR="/var/log/remote/_archive"

# Mail-Konfiguration (für ommail-Modul)
ALERT_SMTP_SERVER="localhost"
ALERT_SMTP_PORT="25"
ALERT_MAIL_FROM="rsyslog@$(hostname -f 2>/dev/null || echo 'syslog.local')"
# ────────────────────────────────────────────────────────────

# Farben
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

_info()    { echo -e "${GREEN}[INFO]${RESET}  $*"; }
_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
_head()    { echo -e "\n${BOLD}${CYAN}$*${RESET}"; echo "$(printf '─%.0s' {1..60})"; }
_require() { command -v "$1" &>/dev/null || { _error "Benötigt: $1 (apt install ${2:-$1})"; exit 1; }; }

_check_root() {
  [[ $EUID -eq 0 ]] || { _error "Dieses Script muss als root ausgeführt werden."; exit 1; }
}

_check_deps() {
  _require getfacl acl
  _require setfacl acl
}

_ensure_group() {
  if ! getent group "$LOG_GROUP" &>/dev/null; then
    groupadd --system "$LOG_GROUP"
    _info "Gruppe '$LOG_GROUP' angelegt."
  fi
}

# ══════════════════════════════════════════════════════════════
#  USER-VERWALTUNG
# ══════════════════════════════════════════════════════════════

_user_add() {
  local name="" host=""

  # Argumente parsen
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --host) host="$2"; shift 2 ;;
      *)      name="$1"; shift ;;
    esac
  done

  [[ -z "$name" ]] && { _error "Usage: user add <name> [--host <hostname>]"; exit 1; }

  _ensure_group

  if id "$name" &>/dev/null; then
    _warn "User '$name' existiert bereits."
  else
    useradd --system --no-create-home --shell /usr/sbin/nologin \
            --comment "RSyslog Log-Viewer" --gid "$LOG_GROUP" "$name"
    _info "User '$name' angelegt (Gruppe: $LOG_GROUP)."
  fi

  # Basis-Leserecht auf LOG_DIR-Root (nur Verzeichnisstruktur sehen)
  setfacl -m "u:${name}:r-x" "$LOG_DIR"

  if [[ -n "$host" ]]; then
    _user_grant_host "$name" "$host"
  else
    _info "Kein --host angegeben: User kann noch keine Logs lesen."
    _info "Berechtigungen setzen mit: $0 user grant $name <hostname>"
  fi

  echo ""
  _info "User '$name' fertig konfiguriert."
  _user_show "$name"
}

_user_del() {
  local name="${1:-}"
  [[ -z "$name" ]] && { _error "Usage: user del <name>"; exit 1; }
  id "$name" &>/dev/null || { _error "User '$name' nicht gefunden."; exit 1; }

  # Alle gesetzten ACLs entfernen
  find "$LOG_DIR" -exec getfacl --omit-header {} 2>/dev/null \; | \
    grep -l "user:${name}:" 2>/dev/null | \
    xargs -r -I{} setfacl -x "u:${name}" {} 2>/dev/null || true

  # Benutzer löschen
  userdel "$name"
  _info "User '$name' und alle seine Log-Berechtigungen wurden entfernt."
}

_user_list() {
  _head "Log-Viewer-Benutzer (Gruppe: $LOG_GROUP)"
  local members
  members=$(getent group "$LOG_GROUP" 2>/dev/null | cut -d: -f4)

  if [[ -z "$members" ]]; then
    _warn "Keine User in Gruppe '$LOG_GROUP'."
    return
  fi

  printf "%-20s %-10s %-s\n" "USER" "SHELL" "ZUGRIFF AUF HOSTS"
  printf "%-20s %-10s %-s\n" "$(printf '─%.0s' {1..20})" "$(printf '─%.0s' {1..10})" "$(printf '─%.0s' {1..30})"

  IFS=',' read -ra USERS <<< "$members"
  for u in "${USERS[@]}"; do
    local shell home_shell
    shell=$(getent passwd "$u" 2>/dev/null | cut -d: -f7 || echo "?")
    # Hosts, auf die der User ACL-Zugriff hat
    local hosts
    hosts=$(find "$LOG_DIR" -maxdepth 1 -mindepth 1 -type d \
      -exec bash -c 'getfacl --omit-header "$1" 2>/dev/null | grep -q "user:'"$u"':" && basename "$1"' _ {} \; 2>/dev/null | tr '\n' ',' | sed 's/,$//')
    [[ -z "$hosts" ]] && hosts="(keine)"
    printf "%-20s %-10s %-s\n" "$u" "$(basename "$shell")" "$hosts"
  done
}

_user_show() {
  local name="${1:-}"
  [[ -z "$name" ]] && { _error "Usage: user show <name>"; exit 1; }
  id "$name" &>/dev/null || { _error "User '$name' nicht gefunden."; exit 1; }

  _head "Berechtigungen: $name"
  echo -e "  ${BOLD}User:${RESET}   $name"
  echo -e "  ${BOLD}UID:${RESET}    $(id -u "$name")"
  echo -e "  ${BOLD}Gruppe:${RESET} $(id -gn "$name")"
  echo ""
  echo -e "  ${BOLD}Zugriff auf Host-Verzeichnisse:${RESET}"

  local found=0
  while IFS= read -r dir; do
    local host
    host=$(basename "$dir")
    if getfacl --omit-header "$dir" 2>/dev/null | grep -q "user:${name}:"; then
      local perm
      perm=$(getfacl --omit-header "$dir" 2>/dev/null | grep "^user:${name}:" | cut -d: -f3)
      echo "    ✔  $host  ($perm)"
      found=1
    fi
  done < <(find "$LOG_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)

  [[ $found -eq 0 ]] && echo "    (keine Host-Verzeichnisse freigegeben)"
}

_user_grant_host() {
  local name="$1"
  local host="$2"
  local host_dir="$LOG_DIR/$host"

  id "$name" &>/dev/null || { _error "User '$name' nicht gefunden."; exit 1; }

  if [[ ! -d "$host_dir" ]]; then
    _warn "Verzeichnis '$host_dir' existiert noch nicht – wird angelegt."
    mkdir -p "$host_dir"
    chown syslog:adm "$host_dir"
    chmod 750 "$host_dir"
  fi

  # ACL auf Host-Verzeichnis und alle Unterverzeichnisse/Dateien (Default-ACL für neue Dateien)
  setfacl -R -m "u:${name}:r-x" "$host_dir"
  setfacl -R -m "d:u:${name}:r-x" "$host_dir"
  # Traversal auf LOG_DIR selbst sicherstellen
  setfacl -m "u:${name}:r-x" "$LOG_DIR"

  _info "User '$name' hat jetzt Lesezugriff auf: $host_dir"
}

_user_grant() {
  local name="${1:-}" host="${2:-}"
  [[ -z "$name" || -z "$host" ]] && { _error "Usage: user grant <name> <hostname>"; exit 1; }
  _user_grant_host "$name" "$host"
}

_user_revoke() {
  local name="${1:-}" host="${2:-}"
  [[ -z "$name" || -z "$host" ]] && { _error "Usage: user revoke <name> <hostname>"; exit 1; }

  local host_dir="$LOG_DIR/$host"
  [[ ! -d "$host_dir" ]] && { _error "Verzeichnis '$host_dir' nicht gefunden."; exit 1; }

  setfacl -R -x "u:${name}" "$host_dir" 2>/dev/null || true
  setfacl -R -x "d:u:${name}" "$host_dir" 2>/dev/null || true
  _info "Zugriff von User '$name' auf '$host' wurde entfernt."
}

# ══════════════════════════════════════════════════════════════
#  SOURCE-VERWALTUNG (Erlaubte Sender)
# ══════════════════════════════════════════════════════════════

_sources_init() {
  if [[ ! -f "$SOURCES_CONF" ]]; then
    cat > "$SOURCES_CONF" <<'EOF'
# Managed by rsyslog-mgmt.sh – Erlaubte Sender
# Format: if $fromhost-ip == '<IP>' then set $!hostname = '<hostname>'; continue
# Zum Blockieren unbekannter Sender: letzte Regel auf 'stop' setzen
EOF
    _info "Sender-Konfiguration angelegt: $SOURCES_CONF"
  fi
}

_source_list() {
  _head "Konfigurierte Quell-Hosts"
  printf "%-20s %-s\n" "IP-ADRESSE" "HOSTNAME"
  printf "%-20s %-s\n" "$(printf '─%.0s' {1..20})" "$(printf '─%.0s' {1..30})"

  if [[ ! -f "$SOURCES_CONF" ]]; then
    _warn "Noch keine Sender-Konfiguration vorhanden."
    return
  fi

  grep -E '^\$fromhost-ip|fromhost-ip ==' "$SOURCES_CONF" 2>/dev/null | \
    grep -oP "fromhost-ip == '([^']+)'.+'([^']+)'" | \
    awk -F"'" '{printf "%-20s %-s\n", $2, $4}' || \
    echo "  (keine Einträge)"
}

_source_add() {
  local ip="${1:-}" host="${2:-}"
  [[ -z "$ip" || -z "$host" ]] && { _error "Usage: source add <ip> <hostname>"; exit 1; }

  _sources_init

  if grep -q "fromhost-ip == '$ip'" "$SOURCES_CONF" 2>/dev/null; then
    _warn "IP '$ip' ist bereits konfiguriert."
    return
  fi

  echo "if \$fromhost-ip == '$ip' then { set \$hostname = '$host'; }" >> "$SOURCES_CONF"
  _info "Sender hinzugefügt: $ip → $host"
  _info "RSyslog neu starten, um die Änderung zu aktivieren: $0 service restart"
}

_source_remove() {
  local ip="${1:-}"
  [[ -z "$ip" ]] && { _error "Usage: source remove <ip>"; exit 1; }

  [[ ! -f "$SOURCES_CONF" ]] && { _error "Keine Sender-Konfiguration gefunden."; exit 1; }

  if ! grep -q "fromhost-ip == '$ip'" "$SOURCES_CONF"; then
    _warn "IP '$ip' nicht in der Konfiguration gefunden."
    return
  fi

  # Zeile mit der IP entfernen (in-place)
  local escaped_ip
  escaped_ip=$(printf '%s\n' "$ip" | sed 's/[[\.*^$()+?{|]/\\&/g')
  sed -i "/fromhost-ip == '${escaped_ip}'/d" "$SOURCES_CONF"
  _info "Sender '$ip' entfernt."
  _info "RSyslog neu starten: $0 service restart"
}

_source_check() {
  _head "Aktive Sender (letzte 24 Stunden)"
  printf "%-30s %-s\n" "HOSTNAME / VERZEICHNIS" "LETZTE AKTIVITÄT"
  printf "%-30s %-s\n" "$(printf '─%.0s' {1..30})" "$(printf '─%.0s' {1..25})"

  local cutoff
  cutoff=$(date -d "24 hours ago" +%s)

  while IFS= read -r dir; do
    local host last_mod last_file
    host=$(basename "$dir")
    last_file=$(find "$dir" -name "*.log" -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1)
    if [[ -n "$last_file" ]]; then
      local ts file
      ts=$(echo "$last_file" | cut -d' ' -f1 | cut -d'.' -f1)
      file=$(echo "$last_file" | cut -d' ' -f2-)
      if [[ "$ts" -ge "$cutoff" ]]; then
        last_mod=$(date -d "@$ts" "+%Y-%m-%d %H:%M:%S")
        printf "${GREEN}%-30s${RESET} %-s\n" "$host" "$last_mod"
      else
        last_mod=$(date -d "@$ts" "+%Y-%m-%d %H:%M:%S")
        printf "${YELLOW}%-30s${RESET} %-s ${YELLOW}(inaktiv)${RESET}\n" "$host" "$last_mod"
      fi
    fi
  done < <(find "$LOG_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "_archive" 2>/dev/null | sort)
}

# ══════════════════════════════════════════════════════════════
#  LOG-VERWALTUNG
# ══════════════════════════════════════════════════════════════

_log_show() {
  local host="" follow=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --follow|-f) follow=1; shift ;;
      *)           host="$1"; shift ;;
    esac
  done

  [[ -z "$host" ]] && { _error "Usage: log show <hostname> [--follow]"; exit 1; }
  local host_dir="$LOG_DIR/$host"
  [[ ! -d "$host_dir" ]] && { _error "Kein Log-Verzeichnis für Host '$host' gefunden."; exit 1; }

  _head "Logs: $host"

  # Neueste Log-Datei finden
  local latest
  latest=$(find "$host_dir" -name "*.log" -printf "%T@ %p\n" 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)

  [[ -z "$latest" ]] && { _warn "Keine Log-Dateien gefunden für: $host"; return; }

  _info "Datei: $latest"
  echo ""

  if [[ $follow -eq 1 ]]; then
    tail -f "$latest"
  else
    tail -50 "$latest"
  fi
}

_log_search() {
  local host="${1:-}" pattern="${2:-}"
  [[ -z "$host" || -z "$pattern" ]] && { _error "Usage: log search <hostname> <muster>"; exit 1; }

  local host_dir="$LOG_DIR/$host"
  [[ ! -d "$host_dir" ]] && { _error "Kein Log-Verzeichnis für Host '$host' gefunden."; exit 1; }

  _head "Suche: '$pattern' in Logs von $host"
  grep -rn --color=always "$pattern" "$host_dir"/*.log "$host_dir"/**/*.log 2>/dev/null || \
    _warn "Kein Treffer für '$pattern' gefunden."
}

_log_disk() {
  local filter="${1:-}"
  _head "Speicherverbrauch: $LOG_DIR"

  echo -e "  ${BOLD}Gesamt:${RESET}  $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
  echo -e "  ${BOLD}Partition:${RESET}"
  df -h "$LOG_DIR" | tail -1 | awk '{printf "    Belegt: %s / %s (%s)\n", $3, $2, $5}'
  echo ""

  printf "  %-30s %-10s\n" "HOST" "GRÖßE"
  printf "  %-30s %-10s\n" "$(printf '─%.0s' {1..30})" "$(printf '─%.0s' {1..10})"

  while IFS= read -r dir; do
    local host size
    host=$(basename "$dir")
    [[ -n "$filter" && "$host" != "$filter" ]] && continue
    size=$(du -sh "$dir" 2>/dev/null | cut -f1)
    printf "  %-30s %-10s\n" "$host" "$size"
  done < <(find "$LOG_DIR" -maxdepth 1 -mindepth 1 -type d ! -name "_archive" 2>/dev/null | sort)
}

_log_rotate() {
  _head "Log-Rotation manuell auslösen"
  if [[ -f /etc/logrotate.d/rsyslog-remote ]]; then
    logrotate --force /etc/logrotate.d/rsyslog-remote
    _info "Log-Rotation abgeschlossen."
  else
    _warn "Keine logrotate-Konfiguration gefunden: /etc/logrotate.d/rsyslog-remote"
    _info "Führe Standard-logrotate aus..."
    logrotate /etc/logrotate.conf
  fi
}

_log_clean() {
  local days="${1:-}"
  [[ -z "$days" || ! "$days" =~ ^[0-9]+$ ]] && { _error "Usage: log clean <tage>"; exit 1; }

  _head "Alte Logs löschen (älter als $days Tage)"

  local count
  count=$(find "$LOG_DIR" -name "*.log.gz" -mtime +"$days" 2>/dev/null | wc -l)
  count=$((count + $(find "$LOG_DIR" -name "*.log" -mtime +"$days" 2>/dev/null | wc -l)))

  if [[ $count -eq 0 ]]; then
    _info "Keine Dateien älter als $days Tage gefunden."
    return
  fi

  echo -e "  ${YELLOW}Es werden $count Dateien gelöscht (älter als $days Tage).${RESET}"
  read -rp "  Fortfahren? [j/N] " confirm
  [[ "$confirm" =~ ^[jJyY]$ ]] || { _info "Abgebrochen."; return; }

  find "$LOG_DIR" -name "*.log.gz" -mtime +"$days" -delete
  find "$LOG_DIR" -name "*.log"    -mtime +"$days" -delete
  # Leere Verzeichnisse aufräumen
  find "$LOG_DIR" -mindepth 1 -type d ! -name "_archive" -empty -delete 2>/dev/null || true

  _info "$count Dateien gelöscht."
}

_log_archive() {
  local host="${1:-}" days="${2:-30}"
  [[ -z "$host" ]] && { _error "Usage: log archive <hostname> [tage]"; exit 1; }

  local host_dir="$LOG_DIR/$host"
  [[ ! -d "$host_dir" ]] && { _error "Kein Log-Verzeichnis für Host '$host' gefunden."; exit 1; }

  mkdir -p "$ARCHIVE_DIR"

  local archive_name="${host}_$(date +%Y%m%d_%H%M%S).tar.gz"
  local archive_path="$ARCHIVE_DIR/$archive_name"

  _head "Archivierung: $host (Logs älter als $days Tage)"

  # Dateien sammeln
  local files
  mapfile -t files < <(find "$host_dir" -name "*.log" -mtime +"$days" 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    _warn "Keine Dateien älter als $days Tage für '$host' gefunden."
    return
  fi

  _info "${#files[@]} Dateien werden archiviert → $archive_path"
  tar -czf "$archive_path" -C "$LOG_DIR" \
    $(find "$host_dir" -name "*.log" -mtime +"$days" -printf "%P\n" 2>/dev/null | xargs -I{} echo "$host/{}")

  local size
  size=$(du -sh "$archive_path" | cut -f1)
  _info "Archiv erstellt: $archive_path ($size)"

  read -rp "  Archivierte Quelldateien jetzt löschen? [j/N] " confirm
  if [[ "$confirm" =~ ^[jJyY]$ ]]; then
    find "$host_dir" -name "*.log" -mtime +"$days" -delete
    find "$host_dir" -mindepth 1 -type d -empty -delete 2>/dev/null || true
    _info "Quelldateien gelöscht."
  fi
}

# ══════════════════════════════════════════════════════════════
#  ALERT-VERWALTUNG (E-Mail bei Log-Level 0–3)
# ══════════════════════════════════════════════════════════════
#
#  Schweregrade:  0=emerg  1=alert  2=crit  3=err
#
#  Intern wird eine Datenbank-Datei geführt ($ALERTS_DB):
#    <email>  <max-level>  <host|*>
#  Daraus wird /etc/rsyslog.d/15-mail-alerts.conf generiert.
# ──────────────────────────────────────────────────────────────

_alert_level_name() {
  case "$1" in
    0) echo "emerg"  ;;
    1) echo "alert"  ;;
    2) echo "crit"   ;;
    3) echo "err"    ;;
    *) echo "unbekannt" ;;
  esac
}

_alert_db_init() {
  if [[ ! -f "$ALERTS_DB" ]]; then
    cat > "$ALERTS_DB" <<'EOF'
# rsyslog-mgmt Alert-Datenbank
# Format (TAB-getrennt): email  max-level  host (* = alle Hosts)
# Beispiel:
#   admin@example.com	3	*
#   ops@example.com	2	webserver1
EOF
    chmod 600 "$ALERTS_DB"
  fi
}

_alert_apply() {
  _alert_db_init

  # Prüfen ob aktive (nicht-kommentierte) Einträge vorhanden
  local entries
  entries=$(grep -v '^\s*#' "$ALERTS_DB" | grep -v '^\s*$' || true)

  # Konfigurationsdatei immer (neu) schreiben
  cat > "$ALERTS_CONF" <<'HEADER'
# Managed by rsyslog-mgmt.sh – NICHT manuell bearbeiten
# Neu generieren: rsyslog-mgmt.sh alert apply

module(load="ommail")

template(name="AlertMailBody" type="string"
  string="RSyslog-Alarm\n\nHost:      %HOSTNAME%\nZeit:      %TIMESTAMP:::date-rfc3339%\nSchwere:   %syslogseverity-text% (Level %syslogseverity%)\nFacility:  %syslogfacility-text%\nProgramm:  %PROGRAMNAME%[%procid%]\n\nNachricht:\n%msg%\n\n-- \nRSyslog Alarmierung\n")

template(name="AlertMailSubject" type="string"
  string="[RSyslog ALERT] %syslogseverity-text% auf %HOSTNAME%: %PROGRAMNAME%")

HEADER

  if [[ -z "$entries" ]]; then
    _info "Keine Alert-Empfänger konfiguriert – leere Konfiguration geschrieben."
    systemctl reload rsyslog 2>/dev/null || systemctl restart rsyslog
    return
  fi

  # Pro Eintrag eine ommail-Regel schreiben
  while IFS=$'\t' read -r email level host; do
    [[ -z "$email" || "$email" == \#* ]] && continue

    local level_cond host_cond

    # Severity-Bedingung: $syslogseverity <= level
    level_cond="\$syslogseverity <= ${level}"

    # Host-Bedingung (optional)
    if [[ "$host" == "*" || -z "$host" ]]; then
      host_cond=""
    else
      host_cond=" and (\$hostname == '${host}' or \$fromhost == '${host}')"
    fi

    cat >> "$ALERTS_CONF" <<EOF

# Alert: ${email}  Level<==$(_alert_level_name "$level") ($level)  Host: ${host:-*}
if ${level_cond}${host_cond} then {
    action(type="ommail"
           server="${ALERT_SMTP_SERVER}"
           port="${ALERT_SMTP_PORT}"
           mailfrom="${ALERT_MAIL_FROM}"
           mailto="${email}"
           subject.template="AlertMailSubject"
           template="AlertMailBody"
           action.execOnlyOnceEveryInterval="60")
}
EOF
  done < <(grep -v '^\s*#' "$ALERTS_DB" | grep -v '^\s*$')

  _info "RSyslog-Konfiguration generiert: $ALERTS_CONF"

  # Konfiguration prüfen bevor reload
  if rsyslogd -N1 2>&1 | grep -qi "error"; then
    _error "Konfigurationsfehler – RSyslog wird NICHT neu gestartet."
    rsyslogd -N1 2>&1
    return 1
  fi

  systemctl reload rsyslog 2>/dev/null || systemctl restart rsyslog
  _info "RSyslog neu geladen – Alarmierung aktiv."
}

_alert_add() {
  local email="" level=3 host="*"

  # Argumente parsen
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --level) level="$2"; shift 2 ;;
      --host)  host="$2";  shift 2 ;;
      *)       email="$1"; shift   ;;
    esac
  done

  [[ -z "$email" ]] && { _error "Usage: alert add <email> [--level <0-3>] [--host <hostname>]"; exit 1; }

  # E-Mail-Adresse grob validieren
  [[ "$email" =~ ^[^@]+@[^@]+\.[^@]+$ ]] || { _error "Ungültige E-Mail-Adresse: '$email'"; exit 1; }

  # Level validieren
  [[ "$level" =~ ^[0-3]$ ]] || { _error "Level muss 0–3 sein (0=emerg, 1=alert, 2=crit, 3=err)."; exit 1; }

  _alert_db_init

  # Prüfen ob E-Mail + Host-Kombination schon existiert
  if grep -qP "^${email}\t.*\t${host}$" "$ALERTS_DB" 2>/dev/null; then
    _warn "Eintrag für '$email' (Host: $host) existiert bereits – wird aktualisiert."
    # Alten Eintrag entfernen
    local escaped_email
    escaped_email=$(printf '%s\n' "$email" | sed 's/[[\.*^$()+?{|]/\\&/g')
    sed -i "/^${escaped_email}\t.*\t${host}$/d" "$ALERTS_DB"
  fi

  printf '%s\t%s\t%s\n' "$email" "$level" "$host" >> "$ALERTS_DB"
  _info "Alert hinzugefügt:"
  printf "  E-Mail:  %s\n" "$email"
  printf "  Level:   <= %s (%s)\n" "$level" "$(_alert_level_name "$level")"
  printf "  Host:    %s\n" "$host"

  echo ""
  _alert_apply
}

_alert_del() {
  local email="${1:-}"
  [[ -z "$email" ]] && { _error "Usage: alert del <email>"; exit 1; }

  [[ ! -f "$ALERTS_DB" ]] && { _warn "Keine Alert-Datenbank vorhanden."; return; }

  local escaped_email
  escaped_email=$(printf '%s\n' "$email" | sed 's/[[\.*^$()+?{|]/\\&/g')

  if grep -qP "^${escaped_email}\t" "$ALERTS_DB"; then
    sed -i "/^${escaped_email}\t/d" "$ALERTS_DB"
    _info "Alle Alerts für '$email' entfernt."
    _alert_apply
  else
    _warn "Kein Eintrag für '$email' gefunden."
  fi
}

_alert_list() {
  _head "Konfigurierte E-Mail-Alarme"

  if [[ ! -f "$ALERTS_DB" ]] || ! grep -qv '^\s*#' "$ALERTS_DB" 2>/dev/null; then
    _warn "Keine Alerts konfiguriert."
    echo "  Hinzufügen mit: $0 alert add <email> [--level <0-3>] [--host <hostname>]"
    return
  fi

  printf "  %-35s %-12s %-s\n" "E-MAIL" "MAX-LEVEL" "HOST"
  printf "  %-35s %-12s %-s\n" "$(printf '─%.0s' {1..35})" "$(printf '─%.0s' {1..12})" "$(printf '─%.0s' {1..20})"

  while IFS=$'\t' read -r email level host; do
    [[ -z "$email" || "$email" == \#* ]] && continue
    printf "  %-35s <= %-2s %-6s  %-s\n" \
      "$email" "$level" "($(_alert_level_name "$level"))" "${host:-*}"
  done < <(grep -v '^\s*#' "$ALERTS_DB" | grep -v '^\s*$')

  echo ""
  echo -e "  ${BOLD}SMTP:${RESET} ${ALERT_SMTP_SERVER}:${ALERT_SMTP_PORT}  From: ${ALERT_MAIL_FROM}"
}

_alert_test() {
  local email="${1:-}"
  [[ -z "$email" ]] && { _error "Usage: alert test <email>"; exit 1; }

  _head "Test-Mail senden an: $email"

  # Bevorzugt 'mail'-Befehl für den Test (einfacher als RSyslog zu triggern)
  if command -v mail &>/dev/null; then
    echo "Dies ist eine Test-Nachricht von rsyslog-mgmt.sh auf $(hostname).
Zeitstempel: $(date)
Konfigurierter SMTP: ${ALERT_SMTP_SERVER}:${ALERT_SMTP_PORT}

Wenn du diese Mail erhältst, funktioniert der Mail-Versand." \
      | mail -s "[RSyslog Test] Alert-Konfiguration $(hostname)" \
             -a "From: ${ALERT_MAIL_FROM}" \
             "$email" \
      && _info "Test-Mail gesendet an: $email" \
      || _error "Fehler beim Senden – MTA erreichbar?"
  else
    # Fallback: Test-Log per logger schreiben → RSyslog ommail triggern
    _warn "'mail'-Befehl nicht gefunden (apt install mailutils)."
    _info "Sende Test-Nachricht über RSyslog (logger -p emerg) ..."
    logger -p emerg "rsyslog-mgmt TEST: Alert-Mail-Test für $email ($(date))"
    _info "Nachricht mit Schweregrad 'emerg' injiziert – prüfe Posteingang von $email."
  fi
}

# ══════════════════════════════════════════════════════════════
#  SERVICE-VERWALTUNG
# ══════════════════════════════════════════════════════════════

_service_status() {
  _head "RSyslog Status"
  systemctl status rsyslog --no-pager || true

  echo ""
  _head "Port-Bindings (UDP/TCP 514)"
  ss -ulnp | grep 514 || echo "  UDP 514: nicht aktiv"
  ss -tlnp | grep 514 || echo "  TCP 514: nicht aktiv"

  echo ""
  _head "Verbundene Clients (TCP)"
  ss -tnp | grep ':514' | awk '{print "  " $5}' | sort -u || echo "  Keine aktiven TCP-Verbindungen."
}

_service_restart() {
  _head "RSyslog neu starten"
  _service_check_syntax && {
    systemctl restart rsyslog
    sleep 1
    if systemctl is-active rsyslog &>/dev/null; then
      _info "RSyslog erfolgreich neu gestartet."
    else
      _error "RSyslog konnte nicht gestartet werden."
      journalctl -u rsyslog --since "1 minute ago" --no-pager | tail -20
    fi
  }
}

_service_check_syntax() {
  _info "Konfigurationsprüfung..."
  if rsyslogd -N1 2>&1 | grep -q "error"; then
    _error "Konfigurationsfehler gefunden:"
    rsyslogd -N1 2>&1 | grep -i error
    return 1
  else
    _info "Konfiguration ist gültig."
    return 0
  fi
}

_service_check() {
  _head "RSyslog Konfigurationsprüfung"
  rsyslogd -N1 2>&1 || true
}

_service_stats() {
  _head "RSyslog interne Statistiken"
  if [[ -f "$STATS_LOG" ]]; then
    echo -e "  ${BOLD}Letzte Statistik:${RESET} $(tail -1 "$STATS_LOG" | cut -c1-30)..."
    echo ""
    tail -30 "$STATS_LOG"
  else
    _warn "Statistik-Log nicht gefunden: $STATS_LOG"
    _info "Impstats-Modul in /etc/rsyslog.d/20-stats.conf konfigurieren."
  fi
}

_service_errors() {
  _head "RSyslog Fehler (letzte 24h)"
  journalctl -u rsyslog --since "24 hours ago" --no-pager \
    | grep -iE "error|warning|failed|fatal|crit" \
    | tail -50 \
    || _info "Keine Fehler in den letzten 24 Stunden gefunden."
}

# ══════════════════════════════════════════════════════════════
#  HILFE
# ══════════════════════════════════════════════════════════════

_help() {
  cat <<EOF

${BOLD}rsyslog-mgmt.sh${RESET} – RSyslog Server Verwaltung

${BOLD}USER-VERWALTUNG:${RESET}
  user add <name> [--host <hostname>]   User anlegen (optionale Quellbeschränkung)
  user del <name>                       User löschen
  user list                             Alle Log-User auflisten
  user grant <name> <hostname>          Lesezugriff auf Host-Logs gewähren
  user revoke <name> <hostname>         Lesezugriff auf Host-Logs entziehen
  user show <name>                      Berechtigungen eines Users anzeigen

${BOLD}QUELL-HOSTS:${RESET}
  source list                           Konfigurierte Sender anzeigen
  source add <ip> <hostname>            Erlaubten Sender hinzufügen
  source remove <ip>                    Erlaubten Sender entfernen
  source check                          Aktive Sender (letzte 24h) prüfen

${BOLD}LOG-VERWALTUNG:${RESET}
  log show <hostname> [--follow]        Neueste Logs eines Hosts anzeigen
  log search <hostname> <muster>        In Logs eines Hosts suchen
  log disk [hostname]                   Speicherverbrauch anzeigen
  log rotate                            Log-Rotation manuell auslösen
  log clean <tage>                      Logs älter als N Tage löschen
  log archive <hostname> [tage]         Logs eines Hosts archivieren

${BOLD}E-MAIL-ALARMIERUNG (Level 0–3):${RESET}
  alert add <email> [--level <0-3>] [--host <h>]
                                        Alert einrichten (Default: level 3 = err+, alle Hosts)
                                        0=emerg  1=alert  2=crit  3=err
  alert del <email>                     Alle Alerts für diese E-Mail entfernen
  alert list                            Konfigurierte Alerts anzeigen
  alert test <email>                    Test-Mail senden
  alert apply                           RSyslog-Konfiguration neu generieren + reload

${BOLD}SERVICE:${RESET}
  service status                        RSyslog Status + Port-Bindings
  service restart                       Konfiguration prüfen + neu starten
  service check                         Nur Konfiguration prüfen
  service stats                         Interne Statistiken anzeigen
  service errors                        Fehler im Journal anzeigen

${BOLD}Beispiele:${RESET}
  $0 user add alice --host webserver1
  $0 user grant alice dbserver2
  $0 user revoke alice dbserver2
  $0 source add 192.168.30.110 webserver1
  $0 log show webserver1 --follow
  $0 log search webserver1 "error"
  $0 log clean 90
  $0 log archive webserver1 60
  $0 alert add admin@example.com
  $0 alert add ops@example.com --level 2 --host webserver1
  $0 alert test admin@example.com
  $0 alert list

EOF
}

# ══════════════════════════════════════════════════════════════
#  EINSTIEGSPUNKT
# ══════════════════════════════════════════════════════════════

_check_root
_check_deps

COMMAND="${1:-}"
SUBCOMMAND="${2:-}"
shift 2 2>/dev/null || true

case "$COMMAND" in
  user)
    case "$SUBCOMMAND" in
      add)    _user_add "$@"   ;;
      del)    _user_del "$@"   ;;
      list)   _user_list       ;;
      grant)  _user_grant "$@" ;;
      revoke) _user_revoke "$@";;
      show)   _user_show "$@"  ;;
      *)      _error "Unbekannter user-Befehl: '$SUBCOMMAND'"; _help; exit 1 ;;
    esac
    ;;
  source)
    case "$SUBCOMMAND" in
      list)   _source_list     ;;
      add)    _source_add "$@" ;;
      remove) _source_remove "$@" ;;
      check)  _source_check    ;;
      *)      _error "Unbekannter source-Befehl: '$SUBCOMMAND'"; _help; exit 1 ;;
    esac
    ;;
  log)
    case "$SUBCOMMAND" in
      show)    _log_show "$@"    ;;
      search)  _log_search "$@"  ;;
      disk)    _log_disk "$@"    ;;
      rotate)  _log_rotate       ;;
      clean)   _log_clean "$@"   ;;
      archive) _log_archive "$@" ;;
      *)       _error "Unbekannter log-Befehl: '$SUBCOMMAND'"; _help; exit 1 ;;
    esac
    ;;
  alert)
    case "$SUBCOMMAND" in
      add)    _alert_add "$@"   ;;
      del)    _alert_del "$@"   ;;
      list)   _alert_list       ;;
      test)   _alert_test "$@"  ;;
      apply)  _alert_apply      ;;
      *)      _error "Unbekannter alert-Befehl: '$SUBCOMMAND'"; _help; exit 1 ;;
    esac
    ;;
  service)
    case "$SUBCOMMAND" in
      status)  _service_status  ;;
      restart) _service_restart ;;
      check)   _service_check   ;;
      stats)   _service_stats   ;;
      errors)  _service_errors  ;;
      *)       _error "Unbekannter service-Befehl: '$SUBCOMMAND'"; _help; exit 1 ;;
    esac
    ;;
  help|--help|-h|"")
    _help
    ;;
  *)
    _error "Unbekannter Befehl: '$COMMAND'"
    _help
    exit 1
    ;;
esac

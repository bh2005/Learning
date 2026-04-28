#!/usr/bin/env bash
# ==============================================================================
# ntp-setup.sh — Automatisches Setup für NTP-Backup-VMs im Remote-DC
#
# Führt aus:
#   - Installation und Konfiguration von chrony
#   - Firewall-Konfiguration (ufw / iptables / keine)
#   - Deaktivierung des Hypervisor Time-Sync (VMware / Hyper-V / KVM)
#   - Erstsynchronisation und Verifikation
#
# Voraussetzung: Debian 12+ oder Ubuntu, sudo / root
# Verwendung:    sudo ./ntp-setup.sh
#
# Autor: bh2005
# ==============================================================================

set -euo pipefail

# ── Farben ────────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()   { echo -e "${CYAN}[INFO]${RESET}  $*"; }
ok()     { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()   { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()    { error "$*"; exit 1; }
header() { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}\n"; }
sep()    { echo -e "${CYAN}──────────────────────────────────────────────────${RESET}"; }

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

_prompt() {
    local prompt="$1" default="${2:-}" answer
    if [[ -n "$default" ]]; then
        read -r -p "$(echo -e "${BOLD}${prompt}${RESET} [${default}]: ")" answer
        echo "${answer:-$default}"
    else
        read -r -p "$(echo -e "${BOLD}${prompt}${RESET}: ")" answer
        echo "$answer"
    fi
}

_confirm() {
    local answer
    read -r -p "$(echo -e "${YELLOW}${1:-Fortfahren?} [j/N]${RESET} ")" answer
    [[ "${answer,,}" == "j" || "${answer,,}" == "y" ]]
}

# ── Vorprüfungen ──────────────────────────────────────────────────────────────

_check_root() {
    [[ $EUID -eq 0 ]] || die "Dieses Script muss als root ausgeführt werden. (sudo ./ntp-setup.sh)"
}

_check_os() {
    local id="unknown"
    [[ -f /etc/os-release ]] && id=$(. /etc/os-release; echo "${ID:-unknown}")
    case "$id" in
        debian|ubuntu) ok "Betriebssystem: ${id}" ;;
        *) warn "Getestet auf Debian/Ubuntu. Erkanntes OS: ${id}. Fortfahren auf eigenes Risiko." ;;
    esac
}

_detect_hypervisor() {
    HYPERVISOR="none"
    if command -v systemd-detect-virt &>/dev/null; then
        local virt; virt=$(systemd-detect-virt 2>/dev/null || echo "none")
        case "$virt" in
            vmware)    HYPERVISOR="vmware" ;;
            microsoft) HYPERVISOR="hyperv" ;;
            kvm|qemu)  HYPERVISOR="kvm"    ;;
            none)      HYPERVISOR="none"   ;;
            *)         HYPERVISOR="$virt"  ;;
        esac
    fi
    info "Hypervisor erkannt: ${HYPERVISOR}"
}

# ── Chrony-Konfiguration schreiben ────────────────────────────────────────────

_write_chrony_conf() {
    local upstream="$1" peer_ip="$2" allow_subnet="$3" stratum="$4"

    cat > /etc/chrony/chrony.conf << EOF
# Generiert von ntp-setup.sh – $(date '+%Y-%m-%d %H:%M')
# Primäre Quelle (Zentrales RZ)
server ${upstream} iburst prefer

# Peer: andere NTP-VM im Remote-DC
peer ${peer_ip} iburst

# Optionaler Internet-Fallback (auskommentiert; nur aktivieren wenn Internetzugang vorhanden)
# pool de.pool.ntp.org iburst

# Lokale Fallback-Funktion (Zeit wird auch ohne Upstream-Kontakt verteilt)
local stratum ${stratum}

# NTP-Anfragen aus dem Remote-DC-Subnetz erlauben
allow ${allow_subnet}

# Drift-Datei und Optimierungen
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync

# Logging
logdir /var/log/chrony
log tracking measurements statistics
EOF

    ok "chrony.conf geschrieben: /etc/chrony/chrony.conf"
}

# ── Firewall ──────────────────────────────────────────────────────────────────

_configure_ufw() {
    local allow_subnet="$1" mgmt_subnet="$2"

    if ! command -v ufw &>/dev/null; then
        info "ufw nicht installiert – installiere …"
        apt-get install -y ufw
    fi

    ufw default deny incoming
    ufw default allow outgoing
    ufw allow from "${allow_subnet}" to any port 123 proto udp comment "NTP Remote-DC"
    if [[ -n "$mgmt_subnet" ]]; then
        ufw allow from "${mgmt_subnet}" to any port 22 proto tcp comment "SSH Management"
    fi
    ufw --force enable
    ok "ufw konfiguriert."
    echo ""
    ufw status verbose
}

_configure_iptables() {
    local allow_subnet="$1"

    if ! dpkg -l iptables-persistent &>/dev/null 2>&1; then
        info "iptables-persistent nicht installiert – installiere …"
        DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iptables-persistent
    fi

    iptables -A INPUT  -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -p udp --dport 123 -j ACCEPT          # ausgehende NTP-Abfragen
    iptables -A INPUT  -s "${allow_subnet}" -p udp --dport 123 -j ACCEPT
    iptables -A INPUT  -p udp --dport 123 -j DROP

    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
    ok "iptables-Regeln gesetzt und in /etc/iptables/rules.v4 gespeichert."
}

# ── Hypervisor Time-Sync deaktivieren ─────────────────────────────────────────

_disable_hypervisor_timesync() {
    header "Hypervisor Time-Sync deaktivieren"
    case "$HYPERVISOR" in
        vmware)
            if command -v vmware-toolbox-cmd &>/dev/null; then
                vmware-toolbox-cmd timesync disable \
                    && ok "VMware Tools Time-Sync deaktiviert." \
                    || warn "vmware-toolbox-cmd fehlgeschlagen – manuell in der VM-Konfiguration prüfen."
            else
                warn "vmware-toolbox-cmd nicht gefunden."
                warn "Bitte in der .vmx-Datei des Hosts deaktivieren:"
                echo '    tools.syncTime = "FALSE"'
                echo '    time.synchronize.continue = "FALSE"'
                echo '    time.synchronize.restore = "FALSE"'
                echo '    time.synchronize.resume.disk = "FALSE"'
                echo '    time.synchronize.shrink = "FALSE"'
            fi
            ;;
        hyperv)
            warn "Hyper-V erkannt: Time-Sync muss auf dem Hyper-V-Host deaktiviert werden."
            warn "Auf dem Hyper-V-Host in PowerShell ausführen:"
            echo "    Disable-VMIntegrationService -VMName \"$(hostname -s)\" -Name \"Time Synchronization\""
            ;;
        kvm|qemu)
            warn "KVM/QEMU erkannt: Bitte in der libvirt-XML prüfen:"
            echo "    <clock offset='utc'>"
            echo "      <timer name='rtc' tickpolicy='catchup'/>"
            echo "    </clock>"
            ;;
        none)
            info "Kein Hypervisor erkannt (Bare Metal) – Schritt übersprungen."
            ;;
        *)
            warn "Unbekannter Hypervisor (${HYPERVISOR}) – Time-Sync bitte manuell prüfen."
            ;;
    esac
}

# ── Hauptprogramm ─────────────────────────────────────────────────────────────

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     K+S – NTP-VM Setup (chrony)                  ║"
echo "  ║     Remote Datacenter – Backup Zeitserver        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${RESET}"

_check_root
_check_os
_detect_hypervisor

header "Konfiguration"

DETECTED_HOSTNAME=$(hostname -s 2>/dev/null || echo "ntp01")
info "Erkannter Hostname: ${DETECTED_HOSTNAME}"

VM_ROLE=$(    _prompt "Rolle dieser VM (z.B. ntp01 oder ntp02)"       "${DETECTED_HOSTNAME}")
NTP_UPSTREAM=$(_prompt "FQDN / IP der zentralen NTP Appliance"         "ntp-appliance.haupt.dc")
NTP_PEER_IP=$( _prompt "IP-Adresse der anderen NTP-VM (Peer)"          "10.20.30.52")
NTP_ALLOW=$(   _prompt "Subnetz für NTP-Clients (CIDR)"                "10.20.30.0/24")
NTP_STRATUM=$( _prompt "Lokales Fallback-Stratum (Standard: 9)"        "9")

echo ""
echo -e "${BOLD}Firewall konfigurieren?${RESET}"
echo "  1) ufw        (empfohlen für Debian/Ubuntu)"
echo "  2) iptables   (klassisch)"
echo "  3) Überspringen"
FW_CHOICE=$(_prompt "Auswahl" "1")

MGMT_SUBNET=""
if [[ "$FW_CHOICE" == "1" ]]; then
    MGMT_SUBNET=$(_prompt "Management-Subnetz für SSH-Zugriff (leer = kein SSH-Allow)" "")
fi

echo ""
sep
echo -e "  ${BOLD}Zusammenfassung:${RESET}"
echo "    Rolle dieser VM     : ${VM_ROLE}"
echo "    Upstream NTP        : ${NTP_UPSTREAM}"
echo "    Peer (andere VM)    : ${NTP_PEER_IP}"
echo "    Clients (allow)     : ${NTP_ALLOW}"
echo "    Fallback-Stratum    : ${NTP_STRATUM}"
case "$FW_CHOICE" in
    1) echo "    Firewall            : ufw${MGMT_SUBNET:+ (SSH aus ${MGMT_SUBNET})}" ;;
    2) echo "    Firewall            : iptables" ;;
    *) echo "    Firewall            : keine Konfiguration" ;;
esac
sep
echo ""

_confirm "Setup jetzt starten?" || die "Abgebrochen."

# ── Installation ──────────────────────────────────────────────────────────────

header "chrony installieren"
apt-get update -qq
apt-get install -y chrony
ok "chrony installiert."

# ── Konfiguration ─────────────────────────────────────────────────────────────

header "chrony konfigurieren"

if [[ -f /etc/chrony/chrony.conf ]]; then
    BACKUP_FILE="/etc/chrony/chrony.conf.bak.$(date +%Y%m%d_%H%M%S)"
    cp /etc/chrony/chrony.conf "$BACKUP_FILE"
    ok "Originalkonfiguration gesichert: ${BACKUP_FILE}"
fi

mkdir -p /var/log/chrony
_write_chrony_conf "$NTP_UPSTREAM" "$NTP_PEER_IP" "$NTP_ALLOW" "$NTP_STRATUM"

# ── Dienst aktivieren ─────────────────────────────────────────────────────────

header "chrony aktivieren und starten"
systemctl enable chrony
systemctl restart chrony
ok "chrony gestartet und für Autostart aktiviert."

# ── Firewall ──────────────────────────────────────────────────────────────────

case "$FW_CHOICE" in
    1) header "Firewall (ufw)";      _configure_ufw      "$NTP_ALLOW" "$MGMT_SUBNET" ;;
    2) header "Firewall (iptables)"; _configure_iptables "$NTP_ALLOW" ;;
    *) warn "Firewall-Konfiguration übersprungen." ;;
esac

# ── Hypervisor Time-Sync ──────────────────────────────────────────────────────

_disable_hypervisor_timesync

# ── Erstsynchronisation ───────────────────────────────────────────────────────

header "Erstsynchronisation"
info "Warte 5 Sekunden auf erste NTP-Antworten …"
sleep 5

if chronyc makestep 2>/dev/null; then
    ok "Uhr wurde per makestep angepasst."
else
    warn "makestep ohne Wirkung – chrony synchronisiert ggf. noch. Später erneut prüfen."
fi

# ── Verifikation ──────────────────────────────────────────────────────────────

header "Verifikation"
echo -e "${BOLD}chronyc sources -v:${RESET}"
chronyc sources -v || warn "chronyc sources fehlgeschlagen – Dienst läuft ggf. noch nicht."
echo ""
echo -e "${BOLD}chronyc tracking:${RESET}"
chronyc tracking  || warn "chronyc tracking fehlgeschlagen."

# ── Abschlusszusammenfassung ──────────────────────────────────────────────────

header "Setup abgeschlossen"
ok "NTP-VM ${VM_ROLE} ist konfiguriert."

THIS_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "<IP dieser VM>")
echo ""
echo -e "  ${BOLD}Nächste Schritte:${RESET}"
echo "  1. Auf der anderen NTP-VM dieses Script ebenfalls ausführen"
echo "     → Peer-IP dort angeben: ${THIS_IP}"
echo "  2. Hypervisor Time-Sync auf dem Virtualisierungshost bestätigen"
echo "  3. Clients auf ${VM_ROLE}.remote.dc umstellen (Konzept Abschnitt 7)"
echo "     Linux:    server ${VM_ROLE}.remote.dc iburst"
echo "     Windows:  w32tm (PDC-Emulator – Konzept Abschnitt 7)"
echo "     ESXi:     esxcli system ntp set --server ${VM_ROLE}.remote.dc ..."
echo "  4. Monitoring einrichten (Konzept Abschnitt 8)"
echo "     Stratum Warning > 5 / Critical > 8"
echo "     Offset  Warning > 50 ms / Critical > 200 ms"
echo "  5. Failover-Test durchführen (Konzept Abschnitt 9)"
echo ""
sep
echo -e "  ${CYAN}Konfiguration:${RESET}  /etc/chrony/chrony.conf"
echo -e "  ${CYAN}Logs:${RESET}           /var/log/chrony/"
echo -e "  ${CYAN}Status:${RESET}         chronyc sources -v && chronyc tracking"
sep
echo ""

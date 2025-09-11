## Modul 0: Linux-Grundlagen für SDN

**Lernziel**: Verstehen, warum grundlegende Linux-Befehle für die Diagnose, Verwaltung und Fehlersuche in der Proxmox-Netzwerkinfrastruktur unerlässlich sind, und praktische Erfahrung mit der Kommandozeile (CLI) sammeln, um Netzwerkprobleme zu analysieren und grundlegende Systemaufgaben durchzuführen.

**Hintergrund**: Proxmox VE (Virtual Environment) ist ein leistungsstarkes Open-Source-Server-Betriebssystem, das auf Debian Linux basiert. Es bietet eine benutzerfreundliche grafische Benutzeroberfläche (GUI), die über einen Webbrowser zugänglich ist und grundlegende Verwaltungsaufgaben wie das Erstellen von virtuellen Maschinen (VMs), die Verwaltung von Speicher oder die Überwachung von Ressourcen erleichtert. Die GUI ist wie das Armaturenbrett eines Autos: Sie zeigt Ihnen wesentliche Informationen wie Geschwindigkeit (CPU-Auslastung), Tankfüllung (Speicher) oder Warnleuchten (Fehler) und ermöglicht grundlegende Steuerung. Für detaillierte Konfigurationen, präzise Diagnosen oder das Beheben komplexer Probleme müssen Sie jedoch auf die Kommandozeile (CLI) zugreifen. Die CLI ist vergleichbar mit dem Motorraum eines Autos: Sie erfordert technisches Wissen, bietet aber volle Kontrolle über alle Funktionen des Systems. In diesem Modul lernen Sie essentielle Linux-Befehle kennen, die für die Verwaltung und Fehlersuche in der Netzwerkinfrastruktur von Proxmox entscheidend sind. Diese Befehle sind das Fundament, um Netzwerkschnittstellen zu prüfen, Verbindungen zu testen und Dienste zu überwachen – alles Voraussetzungen für die Arbeit mit Software-Defined Networking (SDN).

### Praktische Übungen

#### Übung 1: System- und Netzwerkdiagnose

**Ziel**: Vertrautheit mit der Kommandozeile gewinnen, Netzwerkschnittstellen analysieren und die Netzwerkkonnektivität des Proxmox-Servers testen.

1. **Shell öffnen**:
   - Navigieren Sie in der Proxmox-GUI zu Ihrem Knoten (dem physischen Server, der Proxmox ausführt). Klicken Sie im Menü auf `>_ Shell`. Ein schwarzes Terminalfenster öffnet sich – dies ist die Kommandozeile (CLI).
   - **Warum ist das wichtig?**: Die Shell ist Ihr direkter Zugang zum Betriebssystem von Proxmox (Debian Linux). Während die GUI einfache Aufgaben vereinfacht, ermöglicht die CLI präzise Konfigurationen, detaillierte Diagnosen und das Ausführen von Befehlen, die in der GUI nicht verfügbar sind. Stellen Sie sich die Shell als das Steuerpult eines Raumschiffs vor: Sie haben Zugriff auf alle Funktionen des Servers, von der Netzwerkkonfiguration bis zur Dienstverwaltung.
   - **Zusätzlicher Kontext**: Die Shell in Proxmox kann entweder lokal (über eine angeschlossene Tastatur/Monitor) oder über die GUI (Webinterface) geöffnet werden. Alternativ können Sie sich per SSH (z. B. mit `ssh root@192.168.1.10`) verbinden, wenn dies konfiguriert ist.
   - **Möglicher Stolperstein**: Falls die Shell nicht öffnet, prüfen Sie, ob Sie als `root`-Benutzer oder ein Benutzer mit ausreichenden Berechtigungen angemeldet sind. Falls Sie eine Fehlermeldung wie „Permission denied“ erhalten, versuchen Sie, sich mit `sudo -i` als Root-Benutzer anzumelden.

2. **IP-Adresse überprüfen**:
   - Geben Sie den Befehl `ip a` (kurz für `ip address`) ein und drücken Sie Enter.
   - **Erwartete Ausgabe** (Beispiel):
     ```
     1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
         inet 127.0.0.1/8 scope host lo
            valid_lft forever preferred_lft forever
     2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default 
         inet 192.168.1.10/24 brd 192.168.1.255 scope global eno1
            valid_lft forever preferred_lft forever
     3: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
         inet 192.168.1.11/24 brd 192.168.1.255 scope global vmbr0
            valid_lft forever preferred_lft forever
     ```
   - **Ausgabe erklärt**:
     - **lo (Loopback)**: Diese Schnittstelle dient der internen Kommunikation des Servers mit sich selbst. Die Adresse `127.0.0.1/8` ist wie ein internes Telefon, das der Server verwendet, um mit seinen eigenen Diensten zu kommunizieren. Sie ist immer aktiv und für SDN irrelevant.
     - **eno1**: Dies ist die physische Netzwerkkarte, die mit einem Ethernet-Kabel an einen Switch oder Router angeschlossen ist. Der Name kann variieren (z. B. `eth0`, `ens18`), abhängig von der Hardware.
     - **vmbr0**: Eine virtuelle Bridge, die Proxmox erstellt, um virtuelle Maschinen (VMs) oder Container mit dem Netzwerk zu verbinden. Sie funktioniert wie ein virtueller Switch, der Datenverkehr zwischen VMs und der physischen Netzwerkkarte leitet.
     - **IP-Adresse**: Die Zeile `inet 192.168.1.10/24` zeigt die IPv4-Adresse des Servers (`192.168.1.10`) und die Subnetzmaske (`/24`, entspricht `255.255.255.0`). Die Subnetzmaske definiert den Adressbereich des Netzwerks: `/24` bedeutet, dass die ersten drei Teile der Adresse (`192.168.1`) das Netzwerk identifizieren und die letzte Zahl (`10`) den individuellen Host (den Server) kennzeichnet. Dies ermöglicht bis zu 256 Adressen im Netzwerk (von `192.168.1.0` bis `192.168.1.255`).
     - **Status**: `state UP` bedeutet, dass die Schnittstelle aktiv und betriebsbereit ist. `state DOWN` würde auf ein Problem hinweisen, z. B. ein nicht angeschlossenes Kabel, eine defekte Netzwerkkarte oder eine fehlerhafte Konfiguration.
   - **Bedeutung für SDN**: Der Befehl `ip a` ist wie ein „Personalausweis“ Ihres Servers. Er zeigt Ihnen, welche Netzwerkadressen der Server verwendet, wie er mit dem Netzwerk verbunden ist und ob die Schnittstellen korrekt funktionieren. Für SDN ist es entscheidend, die richtigen Schnittstellen (z. B. `vmbr0`) zu identifizieren, da diese später für virtuelle Netzwerke und Bridges verwendet werden.
   - **Zusätzlicher Tipp**: Um nur eine spezifische Schnittstelle zu prüfen, verwenden Sie `ip a show dev eno1`. Um die Konfiguration zu ändern, bearbeiten Sie die Datei `/etc/network/interfaces` (z. B. mit `nano /etc/network/interfaces`).
   - **Möglicher Stolperstein**: Falls keine IP-Adresse angezeigt wird oder die Schnittstelle `DOWN` ist, prüfen Sie:
     - Die physische Verbindung (Kabel, Switch-Port).
     - Die Netzwerkkonfiguration in `/etc/network/interfaces`. Beispiel für eine statische IP:
       ```plaintext
       auto eno1
       iface eno1 inet static
           address 192.168.1.10
           netmask 255.255.255.0
           gateway 192.168.1.1
       ```
     - Starten Sie die Netzwerkschnittstelle neu: `sudo systemctl restart networking` oder `sudo ifdown eno1 && sudo ifup eno1`.

3. **Internetverbindung testen**:
   - Geben Sie den Befehl `ping google.com` ein und drücken Sie Enter.
   - **Erwartete Ausgabe**:
     - Bei Erfolg:
       ```
       PING google.com (142.250.190.78) 56(84) bytes of data.
       64 bytes from fra16s56-in-f14.1e100.net (142.250.190.78): icmp_seq=1 ttl=117 time=12.3 ms
       64 bytes from fra16s56-in-f14.1e100.net (142.250.190.78): icmp_seq=2 ttl=117 time=11.9 ms
       ```
     - Bei Misserfolg:
       ```
       ping: google.com: Name or service not known
       ```
       oder keine Antwort nach mehreren Sekunden.
   - **Ausgabe erklärt**:
     - Der Befehl `ping` sendet kleine Datenpakete (ICMP-Pakete) an einen Zielrechner (hier `google.com`) und wartet auf eine Antwort. Jede Zeile wie `64 bytes from ...` zeigt eine erfolgreiche Antwort. Der Wert `time=12.3 ms` gibt die Latenzzeit an (wie lange das Paket für Hin- und Rückweg benötigt).
     - Wenn `google.com` in eine IP-Adresse (z. B. `142.250.190.78`) aufgelöst wird, funktioniert die DNS-Auflösung. Ein Fehler wie „Name or service not known“ deutet auf ein DNS-Problem hin.
   - **Bedeutung für SDN**: Der `ping`-Befehl ist ein grundlegendes Diagnosetool, um die Netzwerkkonnektivität zu prüfen. In SDN-Umgebungen ist es wichtig, sicherzustellen, dass der Server mit dem Netzwerk und dem Internet kommunizieren kann, da SDN-Komponenten oft auf externe Dienste (z. B. für Updates oder DNS) angewiesen sind. Ein erfolgreicher Ping zeigt, dass die grundlegende Netzwerkkonfiguration korrekt ist.
   - **Zusätzlicher Kontext**: `ping` verwendet das ICMP-Protokoll (Internet Control Message Protocol), das oft von Firewalls blockiert wird. Wenn `ping google.com` fehlschlägt, testen Sie `ping 8.8.8.8` (Google’s öffentlicher DNS-Server), um DNS-Probleme auszuschließen. Ein erfolgreicher Ping zu `8.8.8.8`, aber ein fehlgeschlagener Ping zu `google.com`, deutet auf ein Problem mit dem DNS-Server hin.
   - **Möglicher Stolperstein**:
     - **DNS-Fehler**: Prüfen Sie die DNS-Konfiguration in `/etc/resolv.conf`:
       ```plaintext
       nameserver 8.8.8.8
       nameserver 8.8.4.4
       ```
     - **Firewall blockiert ICMP**: Überprüfen Sie die Firewall-Regeln mit `iptables -L` oder `ufw status`.
     - **Keine Internetverbindung**: Prüfen Sie die Routing-Tabelle mit `ip route`. Die Standardroute sollte wie folgt aussehen:
       ```plaintext
       default via 192.168.1.1 dev eno1
       ```
       Falls die Standardroute fehlt, fügen Sie sie hinzu: `sudo ip route add default via 192.168.1.1`.

#### Übung 2: Paketverwaltung und Dienststatus

**Ziel**: Verstehen, wie Software-Pakete in Debian verwaltet werden, und lernen, den Status kritischer Proxmox-Dienste zu überprüfen, um die Systemstabilität sicherzustellen.

1. **Software-Katalog aktualisieren**:
   - Führen Sie den Befehl `sudo apt update` aus.
   - **Erwartete Ausgabe** (Auszug):
     ```
     Hit:1 http://deb.debian.org/debian bullseye InRelease
     Hit:2 http://download.proxmox.com/debian/pve bullseye InRelease
     Reading package lists... Done
     Building dependency tree... Done
     All packages are up to date.
     ```
   - **Bedeutung**:
     - `apt` ist der Paketmanager von Debian, der Software-Pakete installiert, aktualisiert oder entfernt. Der Befehl `sudo apt update` aktualisiert die Liste der verfügbaren Software-Pakete und ihrer Versionen aus den konfigurierten Repositories (Softwarequellen). Es werden keine Programme heruntergeladen oder installiert, sondern nur der Katalog aktualisiert – ähnlich wie das Aktualisieren der App-Liste in einem App-Store, bevor Sie eine App herunterladen.
     - **Warum wichtig für SDN?**: Ein aktueller Paketkatalog ist notwendig, um die neuesten Versionen von SDN-Komponenten (z. B. `pve-sdn`) oder Sicherheitsupdates zu installieren. Veraltete Pakete können zu Inkompatibilitäten oder Sicherheitslücken führen.
   - **Zusätzlicher Kontext**: Die Repositories sind in `/etc/apt/sources.list` oder in Dateien unter `/etc/apt/sources.list.d/` definiert. Für Proxmox sollten Sie das Proxmox-Repository eingetragen haben, z. B.:
     ```plaintext
     deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription
     ```
   - **Möglicher Stolperstein**:
     - Falls `sudo apt update` fehlschlägt (z. B. „Could not resolve ...“), prüfen Sie:
       - Die Internetverbindung: `ping 8.8.8.8`.
       - Die Repository-URLs in `/etc/apt/sources.list`.
       - Die DNS-Konfiguration in `/etc/resolv.conf`.
     - Falls Sie eine Fehlermeldung wie „Permission denied“ erhalten, stellen Sie sicher, dass Sie `sudo` verwenden oder als `root` angemeldet sind.

2. **Dienststatus prüfen**:
   - Führen Sie den Befehl `sudo systemctl status pve-cluster` aus.
   - **Erwartete Ausgabe** (Beispiel):
     ```
     ● pve-cluster.service - The Proxmox VE cluster service
        Loaded: loaded (/lib/systemd/system/pve-cluster.service; enabled; vendor preset: enabled)
        Active: active (running) since Tue 2025-08-19 13:00:00 CEST; 1h ago
        Process: 1234 ExecStart=/usr/bin/pve-cluster (code=exited, status=0/SUCCESS)
        Main PID: 1235 (pve-cluster)
        Tasks: 2 (limit: 4915)
        Memory: 10.2M
        CPU: 1.234s
        CGroup: /system.slice/pve-cluster.service
                └─1235 /usr/bin/pve-cluster
     ```
   - **Ausgabe erklärt**:
     - **Loaded**: Zeigt, dass der Dienst korrekt geladen ist und aktiviert (`enabled`) ist, d. h., er startet automatisch beim Systemstart.
     - **Active: active (running)**: Der Dienst läuft einwandfrei.
     - **Main PID**: Die Prozess-ID des Dienstes, nützlich für weitere Diagnosen.
     - Falls der Status `inactive (dead)` oder `failed` ist, liegt ein Problem vor (z. B. Konfigurationsfehler oder Abhängigkeiten).
   - **Bedeutung für SDN**: Proxmox besteht aus mehreren Diensten, die im Hintergrund laufen, um Funktionen wie Cluster-Management (`pve-cluster`), virtuelle Maschinen oder SDN bereitzustellen. Der `pve-cluster`-Dienst ist für die Kommunikation zwischen Knoten in einem Proxmox-Cluster verantwortlich. Wenn dieser Dienst nicht läuft, können Funktionen wie SDN oder Hochverfügbarkeit beeinträchtigt sein. Der Befehl `systemctl status` ist ein Standardwerkzeug, um den Zustand solcher Dienste zu überprüfen.
   - **Zusätzlicher Kontext**: Für detailliertere Informationen können Sie die Logs des Dienstes mit `journalctl -u pve-cluster` prüfen. Um den Dienst neu zu starten, verwenden Sie `sudo systemctl restart pve-cluster`.
   - **Möglicher Stolperstein**:
     - Falls der Dienst nicht läuft (`inactive` oder `failed`):
       - Prüfen Sie die Logs: `journalctl -u pve-cluster -b` (zeigt Logs seit dem letzten Boot).
       - Starten Sie den Dienst neu: `sudo systemctl restart pve-cluster`.
       - Stellen Sie sicher, dass keine Konfigurationsfehler in `/etc/pve` vorliegen.
     - Falls der Befehl nicht funktioniert, prüfen Sie, ob `systemd` korrekt funktioniert: `systemctl --version`.

---

### Zusätzliche Tipps für Modul 0

- **Wichtige Linux-Befehle für Anfänger**:
  - `whoami`: Zeigt den aktuellen Benutzer (z. B. `root`).
  - `pwd`: Zeigt das aktuelle Verzeichnis.
  - `ls`: Listet Dateien im Verzeichnis auf.
  - `man <Befehl>`: Zeigt die Dokumentation für einen Befehl (z. B. `man ip`).
- **Sicherheitshinweis**: Arbeiten Sie als `root`-Benutzer vorsichtig, da Fehler schwerwiegende Konsequenzen haben können. Verwenden Sie `sudo` für einzelne Befehle, wenn möglich.
- **Nützliche Dateien für Netzwerkdiagnose**:
  - `/etc/network/interfaces`: Konfiguration der Netzwerkschnittstellen.
  - `/etc/resolv.conf`: DNS-Server-Einstellungen.
  - `/proc/net/dev`: Statistik über Netzwerkschnittstellen.
- **Praxisübung für Fortgeschrittene**: Versuchen Sie, die Netzwerkkonfiguration temporär zu ändern, ohne die Dateien zu bearbeiten:
  - IP-Adresse setzen: `sudo ip addr add 192.168.1.99/24 dev eno1`.
  - Standardroute hinzufügen: `sudo ip route add default via 192.168.1.1`.
  - Hinweis: Diese Änderungen sind nicht dauerhaft und verschwinden nach einem Neustart.

---

Dieses Modul legt den Grundstein für die Arbeit mit SDN in Proxmox, indem es Ihnen die essentiellen Linux-Befehle und deren Bedeutung für die Netzwerkdiagnose und -verwaltung näherbringt. Die praktischen Übungen sind so gestaltet, dass Sie Vertrauen in die Arbeit mit der Kommandozeile gewinnen und grundlegende Probleme identifizieren können. Wenn Sie weitere Fragen zu bestimmten Befehlen oder Konzepten haben, lassen Sie es mich wissen!

**[Modul 1: Grundlagen von TCP/IP, Routing und VLANs](Modul01_TCP.md)**   oder **[zurück zur Übersicht](00_Übersicht_SDN.md)**
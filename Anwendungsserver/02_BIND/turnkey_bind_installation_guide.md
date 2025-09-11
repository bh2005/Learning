
# Lernprojekt: Installation eines TurnKey Linux BIND DNS-Servers als LXC-Container

## Vorbereitung: Umgebung einrichten
1. **Proxmox VE prüfen**:
   - Melde dich an der Proxmox-Weboberfläche an: `https://192.168.30.2:8006`.
   - Stelle sicher, dass LXC-Unterstützung aktiviert ist:
     ```bash
     pveam update
     pveam list
     ```
   - Prüfe verfügbare Speicherorte (z. B. `local-lvm` oder `local-zfs`).
2. **DNS in OPNsense konfigurieren**:
   - Öffne die OPNsense-Weboberfläche: `http://192.168.30.1`.
   - Gehe zu `Services > Unbound DNS > General`.
   - Füge einen Host-Eintrag für den neuen DNS-Server hinzu:
     - Host: `dns`
     - Domäne: `homelab.local`
     - IP: `192.168.30.109`
     - Beschreibung: `BIND DNS Server`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup dns.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.109`.
3. **Ansible-Umgebung prüfen**:
   - Auf der Ubuntu-VM (`192.168.30.101`):
     ```bash
     ssh ubuntu@192.168.30.101
     ansible --version
     ```
   - Stelle sicher, dass SSH-Zugriff auf OPNsense möglich ist:
     ```bash
     ssh root@192.168.30.1
     ```
4. **Projektverzeichnis erstellen**:
   - Auf `192.168.30.101`:
     ```bash
     mkdir ~/turnkey-bind-install
     cd ~/turnkey-bind-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey BIND

**Ziel**: Installiere den TurnKey Linux BIND-Server als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey BIND-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey BIND-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey BIND-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-bind_18.0-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-bind_18.0-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `dns`
     - Template: `debian-12-turnkey-bind_18.0-1_amd64`
     - IP-Adresse: `192.168.30.109/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1` (vorläufig, wird später auf `192.168.30.109` geändert)
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 1 Kern, RAM: 512 MB, Disk: 8 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `dns > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **BIND initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.109
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Konfiguriere Webmin (Port 10000) und installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den BIND-Dienst:
     ```bash
     systemctl status named
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die DNS-Funktionalität:
     ```bash
     dig @192.168.30.109 homelab.local
     ```
     - Erwartete Ausgabe: Antwort mit Standard-DNS-Einträgen (kann leer sein, bis Zonen konfiguriert sind).
   - Teste die Webmin-Oberfläche:
     ```bash
     curl https://dns.homelab.local:10000
     ```
     - Erwartete Ausgabe: HTML der Webmin-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.109:10000` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).

**Erkenntnis**: Die TurnKey BIND Appliance vereinfacht die Installation eines autoritativen DNS-Servers mit BIND 9 und Webmin.

**Quelle**: https://www.turnkeylinux.org/dns

## Übung 2: Konfiguration von DNS-Zonen und -Einträgen mit Ansible

**Ziel**: Konfiguriere eine DNS-Zone für `homelab.local` und füge Einträge für bestehende Dienste (Etherpad, OpenLDAP, Mattermost) hinzu.

**Aufgabe**: Erstelle ein Ansible-Playbook, um die DNS-Zone und -Einträge zu konfigurieren und OPNsense auf den neuen DNS-Server umzustellen.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           dns_servers:
             hosts:
               dns:
                 ansible_host: 192.168.30.109
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_python_interpreter: /usr/bin/python3
           network_devices:
             hosts:
               opnsense:
                 ansible_host: 192.168.30.1
                 ansible_user: root
                 ansible_connection: ssh
                 ansible_network_os: freebsd
       ```

2. **Ansible-Playbook für DNS-Konfiguration**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_bind.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure BIND DNS server
         hosts: dns_servers
         become: yes
         vars:
           domain: "homelab.local"
           bind_zone_file: "/etc/bind/zones/db.homelab.local"
         tasks:
           - name: Install bind9utils
             ansible.builtin.apt:
               name: bind9utils
               state: present
               update_cache: yes
           - name: Create zone directory
             ansible.builtin.file:
               path: /etc/bind/zones
               state: directory
               mode: '0755'
           - name: Configure BIND zone for homelab.local
             ansible.builtin.copy:
               dest: "{{ bind_zone_file }}"
               content: |
                 $TTL 3600
                 @ IN SOA dns.homelab.local. admin.homelab.local. (
                   2025091001 ; Serial
                   3600       ; Refresh
                   1800       ; Retry
                   604800     ; Expire
                   3600       ; Minimum TTL
                 )
                 @ IN NS dns.homelab.local.
                 dns       IN A 192.168.30.109
                 etherpad  IN A 192.168.30.107
                 ldap      IN A 192.168.30.106
                 mattermost IN A 192.168.30.108
           - name: Update BIND configuration
             ansible.builtin.blockinfile:
               path: /etc/bind/named.conf.local
               marker: "// {mark} homelab.local Zone"
               block: |
                 zone "{{ domain }}" {
                   type master;
                   file "{{ bind_zone_file }}";
                 };
           - name: Check BIND configuration
             ansible.builtin.command: named-checkconf
             register: checkconf_result
           - name: Check zone file
             ansible.builtin.command: named-checkzone {{ domain }} {{ bind_zone_file }}
             register: checkzone_result
           - name: Restart BIND service
             ansible.builtin.service:
               name: named
               state: restarted
           - name: Test DNS resolution
             ansible.builtin.command: dig @192.168.30.109 {{ domain }}
             register: dig_result
           - name: Display DNS test result
             ansible.builtin.debug:
               msg: "{{ dig_result.stdout }}"
       - name: Configure OPNsense to use BIND DNS server
         hosts: network_devices
         tasks:
           - name: Update DNS resolver settings
             ansible.builtin.command: >
               configctl unbound set dns_servers 192.168.30.109
             register: unbound_result
           - name: Restart Unbound service
             ansible.builtin.command: configctl unbound restart
           - name: Test DNS resolution via OPNsense
             ansible.builtin.command: nslookup mattermost.homelab.local 192.168.30.1
             register: nslookup_result
           - name: Display OPNsense DNS test result
             ansible.builtin.debug:
               msg: "{{ nslookup_result.stdout }}"
       ```
   - **Erklärung**:
     - Erstellt eine DNS-Zone für `homelab.local` mit A-Records für `dns`, `etherpad`, `ldap` und `mattermost`.
     - Konfiguriert BIND, um die Zone zu verwalten, und überprüft die Konfiguration.
     - Stellt OPNsense so ein, dass es den neuen BIND-Server (`192.168.30.109`) als primären DNS-Server verwendet.
     - Testet die DNS-Auflösung lokal und über OPNsense.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_bind.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display DNS test result] **************************************************
       ok: [dns] => {
           "msg": "... ANSWER SECTION: homelab.local. 3600 IN SOA dns.homelab.local. ..."
       }
       TASK [Display OPNsense DNS test result] *****************************************
       ok: [opnsense] => {
           "msg": "... mattermost.homelab.local 3600 IN A 192.168.30.108 ..."
       }
       ```
   - Prüfe in Webmin:
     - Öffne `https://192.168.30.109:10000`, melde dich an.
     - Gehe zu `Servers > BIND DNS Server > homelab.local`.
     - Erwartete Ausgabe: Zone mit Einträgen für `dns`, `etherpad`, `ldap`, `mattermost`.
   - Teste die DNS-Auflösung:
     ```bash
     nslookup mattermost.homelab.local 192.168.30.109
     ```
     - Erwartete Ausgabe: `192.168.30.108`.

**Erkenntnis**: Ansible automatisiert die Konfiguration von DNS-Zonen und -Einträgen, während BIND eine robuste DNS-Lösung bietet.

**Quelle**: https://www.isc.org/bind/

## Übung 3: Backup der BIND-Daten auf TrueNAS

**Ziel**: Sichere die BIND-Konfiguration und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_bind.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey BIND configuration
         hosts: dns_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-bind-install/backups/dns"
           backup_file: "{{ backup_dir }}/bind-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop BIND service
             ansible.builtin.service:
               name: named
               state: stopped
           - name: Backup BIND configuration
             ansible.builtin.command: >
               tar -czf /tmp/bind-backup-{{ ansible_date_time.date }}.tar.gz /etc/bind
             register: backup_result
           - name: Start BIND service
             ansible.builtin.service:
               name: named
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/bind-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t bind-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-bind-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den `named`-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/etc/bind` (BIND-Konfiguration und Zonen).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_bind.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [dns] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-bind-install/backups/dns/bind-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-bind-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `bind-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-bind-install
       ansible-playbook -i inventory.yml backup_bind.yml >> backup.log 2>&1
       ```
     - Ausführbar machen:
       ```bash
       chmod +x run_backup.sh
       ```
   - Plane einen Cronjob:
     ```bash
     crontab -e
     ```
     - Füge hinzu:
       ```
       0 3 * * * /home/ubuntu/turnkey-bind-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der BIND-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Konfiguriere Firewall-Regeln für DNS (Port 53) und Webmin (Port 10000):
     ```bash
     nano configure_firewall_bind.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for BIND
         hosts: network_devices
         tasks:
           - name: Add firewall rule for DNS (53)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp/udp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.109",
                 "destination_port":"53",
                 "description":"Allow DNS to BIND Server"
               }'
           - name: Add firewall rule for Webmin (10000)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.109",
                 "destination_port":"10000",
                 "description":"Allow Webmin to BIND Server"
               }'
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_bind.yml
     ```
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den BIND-Server:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den BIND-Server als Host hinzu:
       - Hostname: `dns`, IP: `192.168.30.109`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `named`, `webmin`.
     - Erstelle eine benutzerdefinierte Überprüfung für BIND:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/bind
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         dig @192.168.30.109 homelab.local > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 BIND - DNS server is operational"
         else
           echo "2 BIND - DNS server is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/bind
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `BIND` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Dynamische DNS (DDNS)**:
   - Konfiguriere BIND für DDNS mit einem DHCP-Server:
     ```bash
     nano configure_ddns.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure BIND for DDNS
         hosts: dns_servers
         become: yes
         vars:
           domain: "homelab.local"
         tasks:
           - name: Generate TSIG key
             ansible.builtin.command: tsig-keygen -a hmac-sha256 ddns-update
             register: tsig_key
           - name: Add TSIG key to BIND configuration
             ansible.builtin.blockinfile:
               path: /etc/bind/named.conf.local
               marker: "// {mark} DDNS TSIG Key"
               block: |
                 key "ddns-update" {
                   algorithm hmac-sha256;
                   secret "{{ tsig_key.stdout_lines | select('match', '^secret.*') | first | split(':') | last | trim }}";
                 };
                 zone "{{ domain }}" {
                   type master;
                   file "/etc/bind/zones/db.homelab.local";
                   allow-update { key "ddns-update"; };
                 };
           - name: Restart BIND service
             ansible.builtin.service:
               name: named
               state: restarted
       ```
   - **Hinweis**: Für eine vollständige DDNS-Integration ist ein DHCP-Server erforderlich (z. B. `isc-dhcp-server`).

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-bind-install/backups/dns
     git init
     git add .
     git commit -m "Initial BIND backup"
     ```

## Best Practices für Schüler

- **DNS-Design**:
  - Verwende klare Zonennamen (z. B. `homelab.local`) und halte Zonen-Dateien übersichtlich.
  - Nutze Webmin (`https://192.168.30.109:10000`) für einfache Verwaltung.
- **Sicherheit**:
  - Schränke DNS-Zugriff ein:
    ```bash
    ssh root@192.168.30.109 "ufw allow from 192.168.30.0/24 to any port 53 proto tcp"
    ssh root@192.168.30.109 "ufw allow from 192.168.30.0/24 to any port 53 proto udp"
    ssh root@192.168.30.109 "ufw allow from 192.168.30.0/24 to any port 10000"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
  - Ersetze selbstsignierte Zertifikate für Webmin:
    ```bash
    ssh root@192.168.30.109 "turnkey-letsencrypt dns.homelab.local"
    ```
    - Siehe https://www.turnkeylinux.org/dns für Details.
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe BIND-Logs:
    ```bash
    ssh root@192.168.30.109 "cat /var/log/syslog | grep named"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-bind-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/dns, https://www.isc.org/bind/

## Empfehlungen für Schüler

- **Setup**: TurnKey BIND, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: BIND-Installation, DNS-Zonenkonfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Zentraler DNS-Server für HomeLab-Dienste.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen Zone, erweitere zu DDNS oder DNSSEC.
- **Übung**: Experimentiere mit weiteren DNS-Records (z. B. MX, CNAME).
- **Fehlerbehebung**: Nutze `dig`, `nslookup` und `named-checkzone` für Tests.
- **Lernressourcen**: https://www.turnkeylinux.org/dns, https://www.isc.org/bind/, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines BIND DNS-Servers mit TurnKey.
- **Skalierbarkeit**: Automatisierte DNS- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von DNS-Konzepten und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zur Integration von BIND mit OpenLDAP für benutzerbasierte DNS-Regeln, DDNS mit einem DHCP-Server, oder Monitoring mit Wazuh/Fluentd/Checkmk?

**Quellen**:
- TurnKey Linux BIND-Dokumentation: https://www.turnkeylinux.org/dns
- BIND-Dokumentation: https://www.isc.org/bind/
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
```
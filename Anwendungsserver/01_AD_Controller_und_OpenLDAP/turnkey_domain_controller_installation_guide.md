# Lernprojekt: Installation eines TurnKey Linux Domain Controllers als LXC-Container

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
   - Aktiviere DNS-Resolver und füge einen Host-Eintrag hinzu:
     - Host: `dc`
     - Domäne: `homelab.local`
     - IP: `192.168.30.105`
     - Beschreibung: `Domain Controller`
   - Teste den DNS-Eintrag:
     ```bash
     nslookup dc.homelab.local 192.168.30.1
     ```
     - Erwartete Ausgabe: `192.168.30.105`.
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
     mkdir ~/turnkey-dc-install
     cd ~/turnkey-dc-install
     ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

## Übung 1: Einrichten des LXC-Containers mit TurnKey Domain Controller

**Ziel**: Installiere den TurnKey Linux Domain Controller als LXC-Container auf Proxmox.

**Aufgabe**: Lade die TurnKey Domain Controller-Vorlage herunter, erstelle einen LXC-Container und konfiguriere die Basis-Einstellungen.

1. **TurnKey Domain Controller-Vorlage herunterladen**:
   - Öffne die Proxmox-Weboberfläche.
   - Gehe zu `Storage > local > Content > Templates`.
   - Lade die neueste TurnKey Domain Controller-Vorlage herunter:
     - URL: `http://mirror.turnkeylinux.org/turnkeylinux/images/proxmox/debian-12-turnkey-domain-controller_18.1-1_amd64.tar.gz`
     - Alternativ per CLI auf dem Proxmox-Host:
       ```bash
       pveam download local debian-12-turnkey-domain-controller_18.1-1_amd64.tar.gz
       ```
2. **LXC-Container erstellen**:
   - In Proxmox: `Create CT`:
     - Hostname: `dc`
     - Template: `debian-12-turnkey-domain-controller_18.1-1_amd64`
     - IP-Adresse: `192.168.30.105/24`
     - Gateway: `192.168.30.1`
     - DNS-Server: `192.168.30.1`
     - Speicher: `local-lvm` oder `local-zfs`
     - CPU: 2 Kerne, RAM: 2 GB, Disk: 10 GB
   - Starte den Container:
     - In der Proxmox-Weboberfläche: `dc > Start`.
     - Bei der ersten Anmeldung wirst du aufgefordert, die Initialkonfiguration durchzuführen.
3. **Domain Controller initial konfigurieren**:
   - Verbinde dich mit dem Container:
     ```bash
     ssh root@192.168.30.105
     ```
   - Führe die Ersteinrichtung durch (TurnKey Firstboot):
     - Setze das Root-Passwort.
     - Setze das Samba-Admin-Passwort (z. B. `securepassword123`).
     - Setze den Domänennamen: `HOMELAB.LOCAL`.
     - Überspringe TurnKey Backup und Migration (optional, kann später konfiguriert werden).
     - Installiere Sicherheitsupdates, wenn gefragt.
   - Prüfe den Samba-Dienst:
     ```bash
     systemctl status samba-ad-dc
     ```
     - Erwartete Ausgabe: `active (running)`.
   - Teste die Webmin-Oberfläche:
     ```bash
     curl https://dc.homelab.local:12321
     ```
     - Erwartete Ausgabe: HTML der Webmin-Anmeldeseite.
     - Öffne im Browser: `https://192.168.30.105:12321` (ignoriere SSL-Warnungen für selbstsignierte Zertifikate).
   - Teste die AD-Funktionalität:
     ```bash
     samba-tool domain info 192.168.30.105
     ```
     - Erwartete Ausgabe: Informationen wie `Domain: HOMELAB`, `Netbios domain: HOMELAB`.

**Erkenntnis**: Die TurnKey Domain Controller Appliance vereinfacht die Installation eines Active Directory-kompatiblen Servers mit Samba4.[](https://www.turnkeylinux.org/docs/domain-controller)

**Quelle**: https://www.turnkeylinux.org/domain-controller

## Übung 2: Konfiguration von Firewall-Regeln mit Ansible

**Ziel**: Konfiguriere Firewall-Regeln auf OPNsense, um Zugriff auf Samba-Dienste (AD, SMB) und Webmin zu erlauben.

**Aufgabe**: Erstelle ein Ansible-Playbook, um Firewall-Regeln für den Domain Controller zu konfigurieren.

1. **Ansible-Inventar erstellen**:
   - Erstelle eine Inventar-Datei:
     ```bash
     nano inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         children:
           dc_servers:
             hosts:
               dc:
                 ansible_host: 192.168.30.105
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

2. **Ansible-Playbook für Firewall-Regeln**:
   - Erstelle ein Playbook:
     ```bash
     nano configure_firewall_dc.yml
     ```
     - Inhalt:
       ```yaml
       - name: Configure OPNsense firewall for Domain Controller
         hosts: network_devices
         tasks:
           - name: Add firewall rule for Samba (AD/SMB, ports 445, 137-139)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp/udp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.105",
                 "destination_port":"137-139,445",
                 "description":"Allow Samba AD/SMB to Domain Controller"
               }'
             register: samba_result
           - name: Add firewall rule for Webmin (port 12321)
             ansible.builtin.command: >
               configctl firewall rule add '{
                 "action":"pass",
                 "interface":"lan",
                 "direction":"in",
                 "protocol":"tcp",
                 "source_net":"192.168.30.0/24",
                 "destination":"192.168.30.105",
                 "destination_port":"12321",
                 "description":"Allow Webmin to Domain Controller"
               }'
             register: webmin_result
           - name: Verify firewall rules
             ansible.builtin.command: configctl firewall list_rules
             register: rules_list
           - name: Display firewall rules
             ansible.builtin.debug:
               msg: "{{ rules_list.stdout }}"
       ```
   - **Erklärung**:
     - Fügt Firewall-Regeln für Samba (AD/SMB, Ports 137-139, 445) und Webmin (Port 12321) hinzu.
     - Erlaubt Verkehr von `192.168.30.0/24` zu `192.168.30.105`.

3. **Playbook ausführen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml configure_firewall_dc.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display firewall rules] ****************************************************
       ok: [opnsense] => {
           "msg": "... Allow Samba AD/SMB to Domain Controller ... Allow Webmin to Domain Controller ..."
       }
       ```
   - Prüfe in der OPNsense-Weboberfläche:
     - Gehe zu `Firewall > Rules > LAN`.
     - Erwartete Regeln: `pass` für `192.168.30.105:137-139,445` und `192.168.30.105:12321`.

**Erkenntnis**: Ansible automatisiert die Firewall-Konfiguration, um sicheren Zugriff auf den Domain Controller zu gewährleisten.

**Quelle**: https://docs.opnsense.org/manual/firewall.html

## Übung 3: Backup der Domain Controller-Daten auf TrueNAS

**Ziel**: Sichere die Samba-Konfiguration und AD-Datenbank und versioniere sie auf TrueNAS.

**Aufgabe**: Erstelle ein Ansible-Playbook für Backups und begrenze sie auf maximal fünf Versionen.

1. **Ansible-Playbook für Backup**:
   - Erstelle ein Playbook:
     ```bash
     nano backup_dc.yml
     ```
     - Inhalt:
       ```yaml
       - name: Backup TurnKey Domain Controller configuration and data
         hosts: dc_servers
         become: yes
         vars:
           backup_dir: "/home/ubuntu/turnkey-dc-install/backups/dc"
           backup_file: "{{ backup_dir }}/dc-backup-{{ ansible_date_time.date }}.tar.gz"
         tasks:
           - name: Create backup directory
             ansible.builtin.file:
               path: "{{ backup_dir }}"
               state: directory
               mode: '0755'
             delegate_to: localhost
           - name: Stop Samba service
             ansible.builtin.service:
               name: samba-ad-dc
               state: stopped
           - name: Backup Samba configuration and AD database
             ansible.builtin.command: >
               tar -czf /tmp/dc-backup-{{ ansible_date_time.date }}.tar.gz /etc/samba /var/lib/samba
             register: backup_result
           - name: Start Samba service
             ansible.builtin.service:
               name: samba-ad-dc
               state: started
           - name: Fetch backup file
             ansible.builtin.fetch:
               src: /tmp/dc-backup-{{ ansible_date_time.date }}.tar.gz
               dest: "{{ backup_file }}"
               flat: yes
           - name: Limit backups to 5
             ansible.builtin.command: >
               bash -c "cd {{ backup_dir }} && ls -t dc-backup-*.tar.gz | tail -n +6 | xargs -I {} rm {}"
             delegate_to: localhost
           - name: Sync backups to TrueNAS
             ansible.builtin.command: >
               rsync -av {{ backup_dir }}/ root@192.168.30.100:/mnt/tank/backups/turnkey-dc-install/
             delegate_to: localhost
           - name: Display backup status
             ansible.builtin.debug:
               msg: "Backup saved to {{ backup_file }} and synced to TrueNAS"
       ```
   - **Erklärung**:
     - Stoppt den Samba-Dienst, um konsistente Backups zu gewährleisten.
     - Sichert `/etc/samba` (Konfiguration) und `/var/lib/samba` (AD-Datenbank).
     - Begrenzt Backups auf fünf durch Entfernen älterer Dateien.
     - Synchronisiert Backups mit TrueNAS.

2. **Playbook testen**:
   - Führe das Playbook aus:
     ```bash
     ansible-playbook -i inventory.yml backup_dc.yml
     ```
     - Erwartete Ausgabe:
       ```
       TASK [Display backup status] ****************************************************
       ok: [dc] => {
           "msg": "Backup saved to /home/ubuntu/turnkey-dc-install/backups/dc/dc-backup-<date>.tar.gz and synced to TrueNAS"
       }
       ```
   - Prüfe auf TrueNAS:
     ```bash
     ssh root@192.168.30.100 ls /mnt/tank/backups/turnkey-dc-install/
     ```
     - Erwartete Ausgabe: Maximal fünf `dc-backup-<date>.tar.gz`.

3. **Backup automatisieren**:
   - Erstelle ein Shell-Skript:
     ```bash
     nano run_backup.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd /home/ubuntu/turnkey-dc-install
       ansible-playbook -i inventory.yml backup_dc.yml >> backup.log 2>&1
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
       0 3 * * * /home/ubuntu/turnkey-dc-install/run_backup.sh
       ```
     - **Erklärung**: Führt das Backup täglich um 03:00 Uhr aus.

**Erkenntnis**: Ansible automatisiert die Sicherung der Domain Controller-Daten, während TrueNAS externe Speicherung bietet.

**Quelle**: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/fetch_module.html

## Schritt 4: Integration mit HomeLab
1. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regeln aktiv sind (siehe Übung 2).
   - Prüfe OPNsense-Logs:
     ```bash
     ansible-playbook -i inventory.yml -m ansible.builtin.command -a "cat /var/log/system/latest.log" opnsense
     ```

2. **Monitoring mit Checkmk (optional)**:
   - Konfiguriere Checkmk für den Domain Controller:
     - Öffne Checkmk: `http://192.168.30.101:5000/homelab`.
     - Füge den Domain Controller als Host hinzu:
       - Hostname: `dc`, IP: `192.168.30.105`.
       - Speichern und `Discover services`.
     - Prüfe Services:
       - Gehe zu `Monitor > All services`.
       - Erwartete Ausgabe: Services wie `Samba`, `Webmin`.
     - Erstelle eine benutzerdefinierte Überprüfung für AD:
       ```bash
       nano /omd/sites/homelab/local/share/check_mk/checks/samba_ad
       ```
       - Inhalt:
         ```bash
         #!/bin/bash
         samba-tool domain info 192.168.30.105 > /dev/null
         if [ $? -eq 0 ]; then
           echo "0 Samba_AD - Active Directory is operational"
         else
           echo "2 Samba_AD - Active Directory is not operational"
         fi
         ```
       - Ausführbar machen:
         ```bash
         chmod +x /omd/sites/homelab/local/share/check_mk/checks/samba_ad
         ```
       - In Checkmk: `Setup > Services > Manual checks > Custom checks`, füge `Samba_AD` hinzu.

## Schritt 5: Erweiterung der Übungen
1. **Erweiterte Samba-Konfiguration**:
   - Erstelle ein Playbook, um einen Benutzer zur AD-Domäne hinzuzufügen:
     ```bash
     nano add_ad_user.yml
     ```
     - Inhalt:
       ```yaml
       - name: Add user to Active Directory
         hosts: dc_servers
         become: yes
         vars:
           ad_user: "testuser"
           ad_password: "SecurePass123!"
         tasks:
           - name: Add AD user
             ansible.builtin.command: >
               samba-tool user create {{ ad_user }} {{ ad_password }} --given-name=Test --surname=User
             register: user_result
           - name: Display user creation status
             ansible.builtin.debug:
               msg: "{{ user_result.stdout }}"
       ```

2. **Backup-Versionierung mit Git**:
   - Initialisiere ein Git-Repository für Backups:
     ```bash
     cd ~/turnkey-dc-install/backups/dc
     git init
     git add .
     git commit -m "Initial Domain Controller backup"
     ```

## Best Practices für Schüler

- **Domain Controller-Design**:
  - Verwende einen statischen IP-Eintrag und DNS für zuverlässigen AD-Zugriff.
  - Teste die AD-Funktionalität mit `samba-tool` vor der Produktion.
- **Sicherheit**:
  - Schränke Zugriff ein:
    ```bash
    ssh root@192.168.30.105 "ufw allow from 192.168.30.0/24 to any port 137-139,445,12321"
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Samba-Logs:
    ```bash
    ssh root@192.168.30.105 "cat /var/log/samba/log.samba"
    ```
  - Prüfe Ansible-Logs:
    ```bash
    cat ~/turnkey-dc-install/backup.log
    ```

**Quelle**: https://www.turnkeylinux.org/domain-controller, https://wiki.samba.org

## Empfehlungen für Schüler

- **Setup**: TurnKey Domain Controller, Proxmox LXC, Ansible, TrueNAS-Backups.
- **Workloads**: AD-Installation, Firewall-Konfiguration, Backups.
- **Integration**: Proxmox (LXC), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Samba4-basierter AD-Server für Windows-Clients.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen AD-Domäne, erweitere zu Benutzer- und Gruppenverwaltung.
- **Übung**: Experimentiere mit dem Beitritt eines Windows-Clients zur Domäne.
- **Fehlerbehebung**: Nutze `ansible-playbook --check` und `samba-tool domain info`.
- **Lernressourcen**: https://www.turnkeylinux.org/domain-controller, https://wiki.samba.org, https://docs.ansible.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Schnelle Installation eines Samba4-basierten Domain Controllers.
- **Skalierbarkeit**: Automatisierte Firewall- und Backup-Konfigurationen.
- **Lernwert**: Verständnis von Active Directory und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu Integration mit Wazuh für Sicherheitsüberwachung, Log-Aggregation mit Fluentd, oder erweitertem Monitoring mit Checkmk?

**Quellen**:
- TurnKey Linux Domain Controller-Dokumentation: https://www.turnkeylinux.org/domain-controller
- Samba-Dokumentation: https://wiki.samba.org
- Ansible-Dokumentation: https://docs.ansible.com
- OPNsense-Dokumentation: https://docs.opnsense.org/manual
- Webquellen:,,[](https://www.turnkeylinux.org/docs/domain-controller)[](https://github.com/turnkeylinux-apps/domain-controller)[](https://www.turnkeylinux.org/updates/new-turnkey-domain-controller-version-170)
```
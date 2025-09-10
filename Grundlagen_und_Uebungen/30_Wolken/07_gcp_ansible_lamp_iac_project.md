# Lernprojekt: Infrastructure as Code mit Ansible für einen LAMP-Stack auf GCP

## Einführung

**Infrastructure as Code (IaC)** ermöglicht die Automatisierung und Verwaltung von Infrastruktur durch Code, was Konsistenz, Wiederholbarkeit und Skalierbarkeit fördert. **Ansible** ist ein Open-Source-Tool für IaC, das einfache, deklarative Playbooks in YAML verwendet, um Serverkonfigurationen zu automatisieren. Dieses Lernprojekt führt Schüler in IaC ein, indem es Ansible nutzt, um einen LAMP-Stack (Linux, Apache, MySQL/MariaDB, PHP) mit Let’s Encrypt für HTTPS auf einer GCP-VM (`lamp-vm`, Ubuntu 22.04 LTS) einzurichten. Es baut auf den vorherigen Anleitungen auf, insbesondere `01_gcp_cloud_computing_intro_guide.md` und `02_gcp_lamp_letsencrypt_guide.md`, und integriert Google Cloud Storage für Backups sowie die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Das Projekt umfasst die Erstellung von Ansible-Playbooks, die Automatisierung der VM-Konfiguration, die Sicherung von Konfigurationsdateien und die Integration mit TrueNAS. Es ist schülerfreundlich und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- GCP-VM (`lamp-vm`, Ubuntu 22.04 LTS, IP: z. B. `34.123.45.67`) mit SSH-Zugriff, wie in `01_gcp_cloud_computing_intro_guide.md`.
- Grundkenntnisse in Linux (z. B. SSH, `apt`), YAML und Netzwerkkonfiguration (z. B. Firewall, DNS).
- Google Cloud Storage Bucket (`homelab-lamp-backups`) für Backups, wie in `03_gcp_lamp_cloud_storage_backup_guide.md`.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Eine registrierte Domain (z. B. `mylampproject.tk`), wie in `02_gcp_lamp_letsencrypt_guide.md`.
- Lokale Maschine (z. B. Proxmox-VM oder eigener PC) mit Ansible installiert oder die GCP-VM als Ansible-Steuerknoten.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`).

**Ziele**:
- Verstehen von IaC und Ansible-Konzepten (z. B. Playbooks, Roles, Inventory).
- Automatisieren der LAMP-Stack-Installation mit Let’s Encrypt auf einer GCP-VM.
- Sichern von Ansible-Konfigurationen in Google Cloud Storage und TrueNAS.
- Vergleich von Cloud-IaC (Ansible auf GCP) mit HomeLab-Automatisierung (z. B. Proxmox).

**Hinweis**: Ansible ist kostenlos und erfordert keine GCP-Ressourcen außer der VM. Der Free Tier (e2-micro) reicht für die VM, und das $300-Guthaben ermöglicht Tests.

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- GCP-Dokumentation: https://cloud.google.com/compute/docs
- Let’s Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Automatisierung eines LAMP-Stacks mit Ansible

### Projektübersicht
- **Ziel**: Automatische Einrichtung eines LAMP-Stacks (Apache, MariaDB, PHP) mit Let’s Encrypt auf einer GCP-VM (`lamp-vm`) mittels Ansible-Playbooks.
- **Komponenten**: Ansible-Playbooks für Installation, Konfiguration und Backup; Integration mit BigQuery (optional).
- **Tools**: Ansible für IaC, GCP Compute Engine für die VM, Google Cloud Storage für Backups.
- **Ausgabe**: Eine voll automatisierte LAMP-VM, erreichbar über HTTPS, mit gesicherten Konfigurationen.

### Schritt 1: Ansible vorbereiten
1. **Ansible auf der lokalen Maschine oder VM installieren**:
   - Auf der GCP-VM (`lamp-vm`) als Steuerknoten:
     ```bash
     ssh ubuntu@34.123.45.67
     sudo apt update
     sudo apt install ansible -y
     ansible --version  # Erwartet: ansible 2.x
     ```
   - Alternativ auf einer lokalen Maschine (z. B. Proxmox-VM):
     ```bash
     sudo apt update
     sudo apt install ansible -y
     ```
2. **SSH-Schlüssel konfigurieren**:
   - Erzeuge einen SSH-Schlüssel (falls nicht vorhanden):
     ```bash
     ssh-keygen -t rsa -b 4096
     ```
   - Kopiere den öffentlichen Schlüssel zur `lamp-vm`:
     ```bash
     ssh-copy-id ubuntu@34.123.45.67
     ```
   - Teste passwordlosen SSH-Zugriff:
     ```bash
     ssh ubuntu@34.123.45.67
     ```
3. **Ansible-Inventory erstellen**:
   ```bash
   mkdir ~/ansible-lamp
   cd ~/ansible-lamp
   nano inventory.yml
   ```
   - Inhalt:
     ```yaml
     all:
       hosts:
         lamp-vm:
           ansible_host: 34.123.45.67
           ansible_user: ubuntu
           ansible_ssh_private_key_file: ~/.ssh/id_rsa
     ```
4. **Inventory testen**:
   ```bash
   ansible -i inventory.yml all -m ping
   ```
   - Erwartete Ausgabe:
     ```
     lamp-vm | SUCCESS => {
         "changed": false,
         "ping": "pong"
     }
     ```

**Tipp**: Verwende die GCP-VM als Steuerknoten für Einfachheit oder eine lokale Maschine (z. B. Proxmox-VM) für HomeLab-Integration.

**Quelle**: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

### Schritt 2: Ansible-Playbooks für LAMP-Stack erstellen
1. **Projektstruktur erstellen**:
   ```bash
   mkdir -p ~/ansible-lamp/roles/lamp/tasks
   mkdir -p ~/ansible-lamp/roles/lamp/templates
   ```
2. **Haupt-Playbook erstellen**:
   ```bash
   nano ~/ansible-lamp/lamp-playbook.yml
   ```
   - Inhalt:
     ```yaml
     - name: Configure LAMP Stack with Let's Encrypt
       hosts: lamp-vm
       become: yes
       roles:
         - lamp
       vars:
         domain_name: mylampproject.tk
         email_address: user@example.com
         db_name: wordpress
         db_user: wpuser
         db_password: wpsecurepassword
     ```
3. **Role-Tasks für LAMP und Let’s Encrypt**:
   ```bash
   nano ~/ansible-lamp/roles/lamp/tasks/main.yml
   ```
   - Inhalt:
     ```yaml
     - name: Update apt cache
       apt:
         update_cache: yes
         cache_valid_time: 3600

     - name: Install LAMP packages
       apt:
         name:
           - apache2
           - mariadb-server
           - mariadb-client
           - php
           - libapache2-mod-php
           - php-mysql
           - php-gd
           - php-curl
           - php-mbstring
           - php-xml
         state: present

     - name: Start and enable Apache
       systemd:
         name: apache2
         state: started
         enabled: yes

     - name: Start and enable MariaDB
       systemd:
         name: mariadb
         state: started
         enabled: yes

     - name: Secure MariaDB installation
       command: mysql_secure_installation
       args:
         creates: /root/.mysql_secure_installed
       environment:
         MYSQL_ROOT_PASSWORD: "{{ db_password }}"
       register: mysql_secure
       changed_when: mysql_secure.rc == 0
       ignore_errors: yes

     - name: Create MariaDB database
       mysql_db:
         name: "{{ db_name }}"
         state: present

     - name: Create MariaDB user
       mysql_user:
         name: "{{ db_user }}"
         password: "{{ db_password }}"
         priv: "{{ db_name }}.*:ALL"
         state: present

     - name: Install snapd for Certbot
       apt:
         name: snapd
         state: present

     - name: Install Certbot
       snap:
         name: certbot
         classic: yes

     - name: Create Certbot symlink
       file:
         src: /snap/bin/certbot
         dest: /usr/bin/certbot
         state: link

     - name: Obtain Let's Encrypt certificate
       command: certbot --apache -n --agree-tos --email {{ email_address }} -d {{ domain_name }} -d www.{{ domain_name }}
       args:
         creates: /etc/letsencrypt/live/{{ domain_name }}/fullchain.pem

     - name: Configure Apache HTTPS virtual host
       template:
         src: vhost-ssl.j2
         dest: /etc/apache2/sites-available/000-default-le-ssl.conf
         mode: '0644'
       notify: Restart Apache

     - name: Enable HTTP to HTTPS redirect
       template:
         src: vhost-http.j2
         dest: /etc/apache2/sites-available/000-default.conf
         mode: '0644'
       notify: Restart Apache

     - name: Install UFW and configure firewall
       apt:
         name: ufw
         state: present

     - name: Allow HTTP, HTTPS, and SSH in UFW
       ufw:
         rule: allow
         port: "{{ item }}"
         proto: tcp
       loop:
         - 80
         - 443
         - 22

     - name: Enable UFW
       ufw:
         state: enabled
         policy: deny
     ```
4. **Apache-Virtual-Host-Vorlagen erstellen**:
   - HTTPS-Virtual-Host:
     ```bash
     nano ~/ansible-lamp/roles/lamp/templates/vhost-ssl.j2
     ```
     - Inhalt:
       ```apache
       <VirtualHost *:443>
           ServerName {{ domain_name }}
           ServerAlias www.{{ domain_name }}
           DocumentRoot /var/www/html
           SSLEngine on
           SSLCertificateFile /etc/letsencrypt/live/{{ domain_name }}/fullchain.pem
           SSLCertificateKeyFile /etc/letsencrypt/live/{{ domain_name }}/privkey.pem
           <Directory /var/www/html>
               AllowOverride All
           </Directory>
       </VirtualHost>
       ```
   - HTTP-Redirect-Virtual-Host:
     ```bash
     nano ~/ansible-lamp/roles/lamp/templates/vhost-http.j2
     ```
     - Inhalt:
       ```apache
       <VirtualHost *:80>
           ServerName {{ domain_name }}
           ServerAlias www.{{ domain_name }}
           Redirect permanent / https://www.{{ domain_name }}/
       </VirtualHost>
       ```
5. **Handler für Apache-Neustart**:
   ```bash
   nano ~/ansible-lamp/roles/lamp/handlers/main.yml
   ```
   - Inhalt:
     ```yaml
     - name: Restart Apache
       systemd:
         name: apache2
         state: restarted
     ```

**Tipp**: Passe `domain_name`, `email_address`, `db_name`, `db_user` und `db_password` in `lamp-playbook.yml` an deine Umgebung an.

**Quelle**: https://docs.ansible.com/ansible/latest/user_guide/playbooks.html

### Schritt 3: Playbook ausführen
1. **Playbook testen**:
   ```bash
   ansible-playbook -i inventory.yml lamp-playbook.yml --check
   ```
   - Prüft die Syntax und simuliert die Ausführung.
2. **Playbook ausführen**:
   ```bash
   ansible-playbook -i inventory.yml lamp-playbook.yml
   ```
   - Erwartete Ausgabe: LAMP-Stack wird installiert, MariaDB gesichert, Let’s Encrypt-Zertifikat erstellt, Apache für HTTPS konfiguriert, UFW aktiviert.
3. **Webserver testen**:
   - Öffne `https://www.mylampproject.tk` im Browser.
   - Erwartete Ausgabe: Apache-Standardseite oder Fehler (falls `/var/www/html` leer).

**Tipp**: Falls Fehler auftreten, prüfe Logs:
```bash
ssh ubuntu@34.123.45.67
sudo tail -f /var/log/apache2/error.log
```

### Schritt 4: WordPress-Installation automatisieren (optional)
1. **Role-Tasks für WordPress erweitern**:
   ```bash
   nano ~/ansible-lamp/roles/lamp/tasks/wordpress.yml
   ```
   - Inhalt:
     ```yaml
     - name: Download WordPress
       get_url:
         url: https://wordpress.org/latest.tar.gz
         dest: /tmp/wordpress.tar.gz

     - name: Extract WordPress
       unarchive:
         src: /tmp/wordpress.tar.gz
         dest: /var/www/html
         remote_src: yes

     - name: Move WordPress files
       command: mv /var/www/html/wordpress/* /var/www/html/
       args:
         creates: /var/www/html/wp-config.php

     - name: Remove WordPress archive
       file:
         path: /tmp/wordpress.tar.gz
         state: absent

     - name: Configure WordPress
       template:
         src: wp-config.j2
         dest: /var/www/html/wp-config.php
         mode: '0644'

     - name: Set WordPress permissions
       file:
         path: /var/www/html
         owner: www-data
         group: www-data
         recurse: yes
         mode: '0755'
     ```
2. **WordPress-Konfigurationsvorlage erstellen**:
   ```bash
   nano ~/ansible-lamp/roles/lamp/templates/wp-config.j2
   ```
   - Inhalt:
     ```php
     <?php
     define('DB_NAME', '{{ db_name }}');
     define('DB_USER', '{{ db_user }}');
     define('DB_PASSWORD', '{{ db_password }}');
     define('DB_HOST', 'localhost');
     define('DB_CHARSET', 'utf8');
     define('DB_COLLATE', '');
     define('FORCE_SSL_ADMIN', true);
     $table_prefix = 'wp_';
     define('WP_DEBUG', false);
     if ( !defined('ABSPATH') )
         define('ABSPATH', dirname(__FILE__) . '/');
     require_once(ABSPATH . 'wp-settings.php');
     ```
3. **WordPress-Tasks in Haupt-Playbook einfügen**:
   - Bearbeite `lamp-playbook.yml`:
     ```yaml
     - name: Configure LAMP Stack with Let's Encrypt and WordPress
       hosts: lamp-vm
       become: yes
       roles:
         - lamp
       vars:
         domain_name: mylampproject.tk
         email_address: user@example.com
         db_name: wordpress
         db_user: wpuser
         db_password: wpsecurepassword
       tasks:
         - include_role:
             name: lamp
             tasks_from: wordpress.yml
     ```
4. **Playbook erneut ausführen**:
   ```bash
   ansible-playbook -i inventory.yml lamp-playbook.yml
   ```
5. **WordPress testen**:
   - Öffne `https://www.mylampproject.tk/wp-admin/install.php` und folge dem Installationsassistenten.

### Schritt 5: Konfigurationen sichern
1. **Ansible-Konfigurationen exportieren**:
   ```bash
   tar -czf ~/ansible-lamp-backup-$(date +%F).tar.gz ~/ansible-lamp
   gsutil cp ~/ansible-lamp-backup-$(date +%F).tar.gz gs://homelab-lamp-backups/ansible/
   ```
2. **Bucket-Inhalt prüfen**:
   ```bash
   gsutil ls gs://homelab-lamp-backups/ansible/
   ```

### Schritt 6: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   ```bash
   gsutil cp gs://homelab-lamp-backups/ansible/ansible-lamp-backup-$(date +%F).tar.gz /home/ubuntu/
   rsync -av /home/ubuntu/ansible-lamp-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/ansible/
   ```
   - Automatisiere im Backup-Skript (`/home/ubuntu/backup.sh` aus `03_gcp_lamp_cloud_storage_backup_guide.md`):
     ```bash
     # Am Ende des Skripts hinzufügen
     tar -czf $BACKUP_DIR/ansible-lamp-backup-$DATE.tar.gz ~/ansible-lamp
     gsutil cp $BACKUP_DIR/ansible-lamp-backup-$DATE.tar.gz $BUCKET/ansible/
     rsync -av $BACKUP_DIR/ansible-lamp-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/ansible/
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt TrueNAS mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Sicherheit durch IAM:
     - In der GCP-Konsole: `Cloud Storage > homelab-lamp-backups > Permissions`.
     - Rolle `Storage Object Viewer` nur für `lamp-backup-sa` und deine Google-Konto-E-Mail.
   - Überwache Zugriffe:
     ```bash
     gsutil logging get gs://homelab-lamp-backups
     ```
3. **Wiederherstellung testen**:
   - Lade die Ansible-Konfiguration herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/ansible/ansible-lamp-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/ansible-lamp-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Playbook erneut aus:
     ```bash
     ansible-playbook -i ~/ansible-lamp/inventory.yml ~/ansible-lamp/lamp-playbook.yml
     ```

### Schritt 7: Erweiterung des Projekts
1. **BigQuery-Integration (optional)**:
   - Erweitere die Webanwendung um BigQuery-Daten (z. B. Temperaturvorhersagen aus `gcp_bigquery_ml_weather_prediction_project.md`):
     ```yaml
     - name: Install Node.js for BigQuery integration
       apt:
         name: nodejs
         state: present
     - name: Install Google Cloud SDK
       apt:
         name: google-cloud-sdk
         state: present
     - name: Copy BigQuery credentials
       copy:
         src: "{{ lookup('env', 'GOOGLE_APPLICATION_CREDENTIALS') }}"
         dest: /home/ubuntu/gcp-credentials.json
         mode: '0600'
     ```
2. **Automatisierung mit Cron**:
   - Erstelle ein Skript für regelmäßige Playbook-Ausführung:
     ```bash
     nano /home/ubuntu/run-ansible.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd ~/ansible-lamp
       ansible-playbook -i inventory.yml lamp-playbook.yml
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/run-ansible.sh
       ```
     - Cron-Job (wöchentlich, Sonntag 03:00):
       ```bash
       crontab -e
       0 3 * * 0 /home/ubuntu/run-ansible.sh
       ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Bleibe im Free Tier (e2-micro für `lamp-vm`).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Stoppe die VM bei Nichtgebrauch:
    ```bash
    gcloud compute instances stop lamp-vm
    ```
- **Sicherheit**:
  - Schränke SSH-Zugriff ein:
    ```bash
    sudo nano /etc/ssh/sshd_config
    ```
    - Setze:
      ```ini
      PermitRootLogin prohibit-password
      PasswordAuthentication no
      ```
    - Neustart:
      ```bash
      sudo systemctl restart ssh
      ```
  - Verwende sichere Variablen in Ansible:
    ```bash
    nano ~/ansible-lamp/vars/vault.yml
    ```
    - Inhalt:
      ```yaml
      db_password: !vault |
        $ANSIBLE_VAULT;1.1;AES256
        <verschlüsseltes Passwort>
      ```
    - Verschlüsseln:
      ```bash
      ansible-vault encrypt ~/ansible-lamp/vars/vault.yml
      ```
  - Schränke Bucket-Zugriff ein:
    ```bash
    gsutil iam ch allUsers:legacyObjectReader gs://homelab-lamp-backups
    ```
- **Automatisierung**:
  - Teste Playbooks mit `--check`:
    ```bash
    ansible-playbook -i inventory.yml lamp-playbook.yml --check
    ```
  - Überwache Cron-Jobs:
    ```bash
    sudo tail -f /var/log/syslog | grep CRON
    ```
- **Lernziele**:
  - Verstehe IaC-Konzepte (z. B. deklarative Konfiguration, Idempotenz).
  - Vergleiche Cloud-IaC (Ansible auf GCP) mit HomeLab-Automatisierung (z. B. Proxmox-Skripte).
  - Übe YAML und Ansible-Module.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Ansible-Konfiguration, Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html

## Empfehlungen für Schüler

- **Setup**:
  - **Ansible**: Playbooks für LAMP-Stack und Let’s Encrypt auf `lamp-vm`.
  - **GCP**: e2-micro-VM, Cloud Storage Bucket `homelab-lamp-backups`.
  - **Workloads**: Automatisierter LAMP-Stack mit WordPress, erreichbar über HTTPS.
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben für Tests.
  - HomeLab: Sichere Ansible-Konfigurationen auf TrueNAS (`/mnt/tank/backups/ansible`).
- **Beispiel**:
  - Automatisierte Einrichtung von Apache, MariaDB, PHP und Let’s Encrypt via Ansible.
  - Backups in Cloud Storage und TrueNAS.

## Tipps für den Erfolg

- **Free Tier**: Nutze e2-micro für die VM, um Kosten zu minimieren.
- **Ansible-Übung**: Experimentiere mit weiteren Rollen (z. B. Fail2Ban, Node.js).
- **Fehlerbehebung**: Prüfe Ansible-Logs:
  ```bash
  ansible-playbook -i inventory.yml lamp-playbook.yml -vvv
  ```
- **Lernressourcen**: Nutze https://docs.ansible.com und Qwiklabs (https://www.qwiklabs.com).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt mit Ansible für IaC bietet:
- **Praxisorientiert**: Automatisierte Einrichtung eines LAMP-Stacks mit HTTPS.
- **Einfachheit**: Free Tier und Ansible-Playbooks erleichtern den Einstieg.
- **Lernwert**: Verständnis von IaC, Automatisierung und Cloud-Integration.

Es ist ideal für Schüler, die Cloud Computing und IaC lernen möchten, und verbindet GCP-Konzepte mit HomeLab-Erfahrungen (z. B. TrueNAS-Backups).

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring mit Zabbix/Prometheus, zu fortgeschrittenen Ansible-Features (z. B. Ansible Galaxy, Vault) oder zu einer anderen GCP-Dienst (z. B. Cloud Run)?

**Quellen**:
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- GCP-Dokumentation: https://cloud.google.com/compute/docs
- Let’s Encrypt-Dokumentation: https://letsencrypt.org/docs/
- Webquellen:,,,,,,,,,,,,,,
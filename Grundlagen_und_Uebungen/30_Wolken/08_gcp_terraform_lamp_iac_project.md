# Lernprojekt: Infrastructure as Code mit Terraform für einen LAMP-Stack auf GCP

## Einführung

**Infrastructure as Code (IaC)** ermöglicht die Automatisierung und Verwaltung von Infrastruktur durch deklarativen Code, was Konsistenz, Wiederholbarkeit und Skalierbarkeit fördert. **Terraform** ist ein Open-Source-IaC-Tool von HashiCorp, das Infrastruktur in Clouds wie GCP über HCL (HashiCorp Configuration Language) definiert. Dieses Lernprojekt führt Schüler in IaC mit Terraform ein, indem es eine LAMP-Stack-VM (Linux, Apache, MySQL/MariaDB, PHP) mit Let’s Encrypt für HTTPS auf GCP bereitstellt. Es baut auf den vorherigen Anleitungen auf, insbesondere `01_gcp_cloud_computing_intro_guide.md`, `02_gcp_lamp_letsencrypt_guide.md` und `07_gcp_ansible_lamp_iac_project.md`, und integriert Ansible für die Softwarekonfiguration. Das Projekt umfasst die Erstellung von Terraform-Konfigurationen für eine VM, einen Cloud Storage Bucket und Firewall-Regeln, die Integration mit Google Cloud Storage und TrueNAS für Backups und die optionale Verbindung zur HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense). Es ist schülerfreundlich und nutzt den GCP Free Tier sowie das $300-Aktionsguthaben.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Grundkenntnisse in Linux (z. B. SSH, `apt`), YAML/HCL und Netzwerkkonfiguration (z. B. Firewall, DNS).
- Eine registrierte Domain (z. B. `mylampproject.tk`), wie in `02_gcp_lamp_letsencrypt_guide.md`.
- Lokale Maschine (z. B. Proxmox-VM oder eigener PC) oder GCP-VM (`lamp-vm`, Ubuntu 22.04 LTS, IP: z. B. `34.123.45.67`) mit Ansible installiert, wie in `07_gcp_ansible_lamp_iac_project.md`.
- Google Cloud SDK (`gcloud`) installiert (lokal oder auf der VM).
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`).

**Ziele**:
- Verstehen von IaC und Terraform-Konzepten (z. B. Provider, Ressourcen, State).
- Automatisieren der Bereitstellung einer LAMP-Stack-VM mit Terraform und Ansible.
- Sichern von Terraform-Konfigurationen in Google Cloud Storage und TrueNAS.
- Vergleich von Cloud-IaC (Terraform auf GCP) mit HomeLab-Automatisierung (z. B. Proxmox).

**Hinweis**: Terraform ist kostenlos und erfordert keine GCP-Ressourcen außer der VM und dem Bucket. Der Free Tier (e2-micro) reicht für die VM, und das $300-Guthaben ermöglicht Tests.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- GCP Terraform Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Automatisierte Bereitstellung eines LAMP-Stacks mit Terraform

### Projektübersicht
- **Ziel**: Automatische Bereitstellung einer LAMP-Stack-VM mit Firewall-Regeln und Cloud Storage Bucket via Terraform, Konfiguration der Software (Apache, MariaDB, PHP, Let’s Encrypt) via Ansible.
- **Komponenten**: Terraform-Konfigurationen für VM, Bucket und Firewall; Ansible-Playbooks für Software; Backups in Cloud Storage und TrueNAS.
- **Tools**: Terraform für Infrastruktur, Ansible für Softwarekonfiguration, GCP Compute Engine, Cloud Storage.
- **Ausgabe**: Eine voll automatisierte LAMP-VM, erreichbar über HTTPS, mit gesicherten Konfigurationen.

### Schritt 1: Terraform vorbereiten
1. **Terraform lokal oder auf der VM installieren**:
   - Auf der GCP-VM (`lamp-vm`) oder lokal (z. B. Proxmox-VM):
     ```bash
     wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
     unzip terraform_1.5.7_linux_amd64.zip
     sudo mv terraform /usr/local/bin/
     terraform version  # Erwartet: Terraform v1.5.7
     ```
2. **GCP-Servicekonto erstellen** (falls nicht vorhanden, siehe `03_gcp_lamp_cloud_storage_backup_guide.md`):
   - In der GCP-Konsole: `IAM & Admin > Service Accounts > Create Service Account`.
     - Name: `terraform-sa`.
     - Rolle: `Compute Admin`, `Storage Admin`.
     - Erstelle und lade JSON-Schlüssel herunter (z. B. `homelab-lamp-123456-abc123.json`).
   - Kopiere die JSON-Datei:
     ```bash
     scp homelab-lamp-123456-abc123.json ubuntu@34.123.45.67:/home/ubuntu/
     ```
   - Setze Umgebungsvariable:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS=/home/ubuntu/homelab-lamp-123456-abc123.json
     echo 'export GOOGLE_APPLICATION_CREDENTIALS=/home/ubuntu/homelab-lamp-123456-abc123.json' >> ~/.bashrc
     ```
3. **Terraform-Projektstruktur erstellen**:
   ```bash
   mkdir ~/terraform-lamp
   cd ~/terraform-lamp
   ```

**Tipp**: Verwende die GCP-VM als Steuerknoten für Einfachheit oder eine lokale Maschine (z. B. Proxmox-VM) für HomeLab-Integration.

**Quelle**: https://www.terraform.io/docs/cli/install/apt.html

### Schritt 2: Terraform-Konfigurationen erstellen
1. **Haupt-Konfigurationsdatei**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     provider "google" {
       project = "homelab-lamp"
       region  = "europe-west1"
       zone    = "europe-west1-b"
     }

     resource "google_compute_instance" "lamp_vm" {
       name         = "lamp-vm"
       machine_type = "e2-micro"
       zone         = "europe-west1-b"

       boot_disk {
         initialize_params {
           image = "ubuntu-2204-jammy-v20250901"
           size  = 10
         }
       }

       network_interface {
         network = "default"
         access_config {
           // Ephemeral public IP
         }
       }

       metadata = {
         ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
       }

       tags = ["http-server", "https-server"]
     }

     resource "google_compute_firewall" "lamp_firewall" {
       name    = "allow-http-https-ssh"
       network = "default"

       allow {
         protocol = "tcp"
         ports    = ["80", "443", "22"]
       }

       source_ranges = ["0.0.0.0/0"]
       target_tags   = ["http-server", "https-server"]
     }

     resource "google_storage_bucket" "lamp_backups" {
       name     = "homelab-lamp-backups-${random_id.bucket_suffix.hex}"
       location = "europe-west1"
       storage_class = "STANDARD"
     }

     resource "random_id" "bucket_suffix" {
       byte_length = 8
     }

     output "vm_public_ip" {
       value = google_compute_instance.lamp_vm.network_interface[0].access_config[0].nat_ip
     }
     ```
2. **Terraform initialisieren**:
   ```bash
   terraform init
   ```
   - Lädt den GCP-Provider herunter.
3. **Plan prüfen**:
   ```bash
   terraform plan
   ```
   - Zeigt an, welche Ressourcen erstellt werden (VM, Firewall, Bucket).
4. **Infrastruktur bereitstellen**:
   ```bash
   terraform apply -auto-approve
   ```
   - Erwartete Ausgabe: VM (`lamp-vm`), Firewall-Regel und Bucket werden erstellt; die öffentliche IP der VM wird ausgegeben.

**Tipp**: Der `random_id`-Ressource sorgt für einen eindeutigen Bucket-Namen. Passe `project`, `region` und `zone` an deine Umgebung an.

**Quelle**: https://registry.terraform.io/providers/hashicorp/google/latest/docs

### Schritt 3: Ansible für Softwarekonfiguration integrieren
1. **Ansible-Inventory dynamisch aktualisieren**:
   - Nutze die Terraform-Ausgabe (`vm_public_ip`):
     ```bash
     nano ~/ansible-lamp/inventory.yml
     ```
     - Inhalt:
       ```yaml
       all:
         hosts:
           lamp-vm:
             ansible_host: "{{ terraform_output_vm_public_ip }}"
             ansible_user: ubuntu
             ansible_ssh_private_key_file: ~/.ssh/id_rsa
       ```
   - Ersetze `terraform_output_vm_public_ip` mit der Ausgabe von `terraform apply` (z. B. `34.123.45.67`).
2. **Ansible-Playbook ausführen** (aus `gcp_ansible_lamp_iac_project.md`):
   ```bash
   cd ~/ansible-lamp
   ansible-playbook -i inventory.yml lamp-playbook.yml
   ```
   - Installiert LAMP-Stack, Let’s Encrypt und konfiguriert HTTPS.
3. **Webserver testen**:
   - Öffne `https://www.mylampproject.tk` im Browser.
   - Erwartete Ausgabe: Apache-Standardseite oder WordPress (falls installiert).

**Tipp**: Stelle sicher, dass die Domain (`mylampproject.tk`) auf die VM-IP zeigt (DNS A-Record).

### Schritt 4: Konfigurationen sichern
1. **Terraform-State sichern**:
   ```bash
   tar -czf ~/terraform-lamp-backup-$(date +%F).tar.gz ~/terraform-lamp
   gsutil cp ~/terraform-lamp-backup-$(date +%F).tar.gz gs://homelab-lamp-backups/terraform/
   ```
2. **Bucket-Inhalt prüfen**:
   ```bash
   gsutil ls gs://homelab-lamp-backups/terraform/
   ```

### Schritt 5: Integration mit HomeLab
1. **Backups auf TrueNAS sichern**:
   ```bash
   gsutil cp gs://homelab-lamp-backups/terraform/terraform-lamp-backup-$(date +%F).tar.gz /home/ubuntu/
   rsync -av /home/ubuntu/terraform-lamp-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
   ```
   - Automatisiere im Backup-Skript (`/home/ubuntu/backup.sh` aus `03_gcp_lamp_cloud_storage_backup_guide.md`):
     ```bash
     # Am Ende des Skripts hinzufügen
     tar -czf $BACKUP_DIR/terraform-lamp-backup-$DATE.tar.gz ~/terraform-lamp
     gsutil cp $BACKUP_DIR/terraform-lamp-backup-$DATE.tar.gz $BUCKET/terraform/
     rsync -av $BACKUP_DIR/terraform-lamp-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
2. **Vergleich mit OPNsense**:
   - HomeLab: OPNsense schützt TrueNAS mit Firewall-Regeln und Suricata IDS/IPS.
   - GCP: Simuliere OPNsense-Sicherheit durch IAM:
     - In der GCP-Konsole: `Cloud Storage > homelab-lamp-backups > Permissions`.
     - Rolle `Storage Object Viewer` nur für `terraform-sa` und deine Google-Konto-E-Mail.
   - Überwache Zugriffe:
     ```bash
     gsutil logging get gs://homelab-lamp-backups
     ```
3. **Wiederherstellung testen**:
   - Lade die Terraform-Konfiguration herunter:
     ```bash
     gsutil cp gs://homelab-lamp-backups/terraform/terraform-lamp-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-lamp-backup-2025-09-09.tar.gz -C ~/
     ```
   - Stelle die Infrastruktur wieder her:
     ```bash
     cd ~/terraform-lamp
     terraform init
     terraform apply -auto-approve
     ```

### Schritt 6: Erweiterung des Projekts
1. **Terraform für GKE (optional)**:
   - Erweitere `main.tf` für einen GKE-Cluster (wie in `gcp_kubernetes_scalable_web_app_project.md`):
     ```hcl
     resource "google_container_cluster" "homelab_k8s_cluster" {
       name     = "homelab-k8s-cluster"
       location = "europe-west1-b"
       initial_node_count = 1
       node_config {
         machine_type = "e2-small"
       }
     }
     ```
   - Führe `terraform apply` erneut aus.
2. **Automatisierung mit Cron**:
   - Erstelle ein Skript für regelmäßige Terraform-Überprüfung:
     ```bash
     nano /home/ubuntu/run-terraform.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       cd ~/terraform-lamp
       terraform plan
       terraform apply -auto-approve
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/run-terraform.sh
       ```
     - Cron-Job (wöchentlich, Sonntag 03:00):
       ```bash
       crontab -e
       0 3 * * 0 /home/ubuntu/run-terraform.sh
       ```

## Best Practices für Schüler

- **Kostenmanagement**:
  - Bleibe im Free Tier (e2-micro für VM, 5 GB Standard-Bucket).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Zerstöre Ressourcen nach dem Test:
    ```bash
    terraform destroy -auto-approve
    ```
- **Sicherheit**:
  - Schränke SSH-Zugriff ein:
    ```bash
    nano ~/terraform-lamp/firewall.tf
    ```
    - Füge hinzu:
      ```hcl
      resource "google_compute_firewall" "restrict_ssh" {
        name    = "allow-ssh-restricted"
        network = "default"
        allow {
          protocol = "tcp"
          ports    = ["22"]
        }
        source_ranges = ["192.168.20.0/24"] # HomeLab-Management
        target_tags   = ["http-server"]
      }
      ```
  - Verwende Terraform-State-Verschlüsselung:
    ```bash
    terraform init -backend-config="bucket=homelab-lamp-backups" -backend-config="prefix=terraform/state"
    ```
  - Schränke Bucket-Zugriff ein:
    ```bash
    gsutil iam ch allUsers:legacyObjectReader gs://homelab-lamp-backups
    ```
- **Automatisierung**:
  - Teste Terraform-Konfigurationen:
    ```bash
    terraform validate
    terraform plan
    ```
  - Überwache Cron-Jobs:
    ```bash
    sudo tail -f /var/log/syslog | grep CRON
    ```
- **Lernziele**:
  - Verstehe IaC-Konzepte (z. B. deklarative Konfiguration, State-Management).
  - Vergleiche Terraform (Infrastruktur) mit Ansible (Softwarekonfiguration).
  - Übe HCL und Integration mit GCP.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Terraform-Konfiguration, Cloud Storage, TrueNAS.
    - 2 Medien: GCP Persistent Disk, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.

**Quelle**: https://www.terraform.io/docs/language/index.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Konfigurationen für VM, Bucket, Firewall.
  - **Ansible**: Playbooks für LAMP-Stack und Let’s Encrypt.
  - **GCP**: e2-micro-VM, Cloud Storage Bucket `homelab-lamp-backups`.
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben für Tests.
  - HomeLab: Sichere Terraform-Konfigurationen auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Beispiel**:
  - Automatisierte Bereitstellung einer LAMP-VM mit HTTPS, gesichert in Cloud Storage und TrueNAS.

## Tipps für den Erfolg

- **Free Tier**: Nutze e2-micro und 5 GB Standard-Bucket, um Kosten zu minimieren.
- **Terraform-Übung**: Experimentiere mit weiteren Ressourcen (z. B. GKE, BigQuery).
- **Fehlerbehebung**: Prüfe Terraform-Logs:
  ```bash
  terraform plan -out=tfplan
  terraform show tfplan
  ```
- **Lernressourcen**: Nutze https://www.terraform.io/docs und Qwiklabs (https://www.qwiklabs.com).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt mit Terraform für IaC bietet:
- **Praxisorientiert**: Automatisierte Bereitstellung eines LAMP-Stacks mit HTTPS.
- **Einfachheit**: Free Tier und Terraform/Ansible erleichtern den Einstieg.
- **Lernwert**: Verständnis von IaC, Cloud-Infrastruktur und HomeLab-Integration.

Es ist ideal für Schüler, die Cloud Computing und IaC lernen möchten, und verbindet GCP-Konzepte mit HomeLab-Erfahrungen (z. B. TrueNAS-Backups).

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring mit Zabbix/Prometheus, zu fortgeschrittenen Terraform-Features (z. B. Modules, Workspaces) oder zu einer anderen GCP-Dienst (z. B. Cloud Run)?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- GCP Terraform Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- Webquellen:,,,,,,,,,,,,,,

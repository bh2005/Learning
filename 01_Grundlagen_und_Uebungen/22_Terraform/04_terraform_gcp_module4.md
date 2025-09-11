# Lernprojekt: Terraform mit Cloud-Anbietern (Modul 4: GCP-Integration)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet. Dieses Lernprojekt (Modul 4) überträgt die Konzepte aus Modul 1–3 (`01_terraform_basics_module1.md`, `02_terraform_advanced_module2.md`, `03_terraform_advanced_module3.md`) auf die Google Cloud Platform (GCP), nutzt den Free Tier und das $300-Aktionsguthaben und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Es umfasst drei Übungen: die Einrichtung des GCP-Providers mit Authentifizierung, die Bereitstellung einer e2-micro-VM und die Modularisierung der VM-Konfiguration. Das Projekt ist für Anfänger mit Grundkenntnissen in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces) geeignet und kann auf einer lokalen Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) ausgeführt werden.

**Voraussetzungen**:
- GCP-Konto mit aktiviertem Free Tier oder $300-Guthaben, Projekt `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
- Terraform installiert (Version 1.5.7, wie in Modul 1):
  ```bash
  terraform version  # Erwartet: Terraform v1.5.7
  ```
- Google Cloud SDK (`gcloud`) installiert (lokal oder auf einer VM):
  ```bash
  gcloud version  # Erwartet: Google Cloud SDK
  ```
- Grundkenntnisse in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces aus Modul 1–3) und Linux (z. B. `bash`, `nano`).
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Browser für die GCP-Konsole (`https://console.cloud.google.com`).

**Ziele**:
- Verstehen der Einrichtung des GCP-Providers mit Authentifizierung.
- Bereitstellen einer e2-micro-VM in GCP mit Terraform.
- Modularisieren der VM-Konfiguration für Wiederverwendbarkeit.

**Hinweis**: Das Projekt nutzt den GCP Free Tier (e2-micro-VM) und das $300-Guthaben, um Kosten zu minimieren.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- GCP Terraform Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GCP-Dokumentation: https://cloud.google.com/docs
- Webquellen:,,,,,,,,,,,,,,

## Modul 4: Terraform mit Cloud-Anbietern (GCP)

### Vorbereitung: Projekt einrichten
1. **Terraform installieren** (falls nicht vorhanden, siehe Modul 1):
   ```bash
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version  # Erwartet: Terraform v1.5.7
   ```
2. **Google Cloud SDK installieren**:
   ```bash
   sudo apt update
   sudo apt install apt-transport-https ca-certificates gnupg
   echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
   curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
   sudo apt update && sudo apt install google-cloud-sdk
   gcloud init
   ```
   - Folge den Anweisungen, um dich mit deinem GCP-Konto zu verbinden und das Projekt `homelab-lamp` auszuwählen.
3. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-gcp
   cd ~/terraform-gcp
   ```

**Tipp**: Arbeite auf einer lokalen Maschine (z. B. Proxmox-VM) oder einer bestehenden GCP-VM.

### Übung 4: Provider und Authentifizierung

**Ziel**: Die Verbindung zwischen Terraform und GCP herstellen.

**Aufgabe**: Richte ein GCP-Projekt ein, aktiviere die Compute Engine API, erstelle ein Service-Konto und konfiguriere den GCP-Provider in `main.tf`.

1. **GCP-Projekt einrichten**:
   - In der GCP-Konsole (`https://console.cloud.google.com`):
     - Erstelle ein Projekt namens `homelab-lamp` (Projekt-ID: z. B. `homelab-lamp-123456`).
     - Aktiviere die Compute Engine API:
       - Gehe zu `APIs & Services > Library`, suche nach `Compute Engine API` und aktiviere sie.
2. **Service-Konto erstellen**:
   - In der GCP-Konsole: `IAM & Admin > Service Accounts > Create Service Account`.
     - Name: `terraform-sa`.
     - Rolle: `Compute Admin` (für VM-Management).
     - Erstelle und lade JSON-Schlüssel herunter (z. B. `homelab-lamp-123456-abc123.json`).
   - Kopiere die JSON-Datei ins Projektverzeichnis:
     ```bash
     mv ~/Downloads/homelab-lamp-123456-abc123.json ~/terraform-gcp/
     ```
   - Setze Umgebungsvariable:
     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-gcp/homelab-lamp-123456-abc123.json
     echo 'export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-gcp/homelab-lamp-123456-abc123.json' >> ~/.bashrc
     ```
3. **Terraform-Provider konfigurieren**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         google = {
           source  = "hashicorp/google"
           version = "~> 5.0"
         }
       }
     }

     provider "google" {
       project     = "homelab-lamp-123456"
       region      = "europe-west1"
       zone        = "europe-west1-b"
       credentials = file("${path.module}/homelab-lamp-123456-abc123.json")
     }
     ```
   - **Erklärung**:
     - `required_providers`: Spezifiziert den GCP-Provider.
     - `provider "google"`: Konfiguriert die Verbindung zu GCP mit Projekt-ID, Region, Zone und Service-Konto-Schlüssel.

4. **Terraform initialisieren**:
   ```bash
   terraform init
   ```
   - Lädt den GCP-Provider herunter.

**Erkenntnis**: Die Konfiguration des GCP-Providers mit einem Service-Konto ermöglicht Terraform, Ressourcen in GCP zu verwalten. Die JSON-Schlüssel-Datei authentifiziert Terraform gegenüber der GCP-API.

**Quelle**: https://registry.terraform.io/providers/hashicorp/google/latest/docs

### Übung 5: Bereitstellung einer virtuellen Maschine (VM)

**Ziel**: Eine erste reale Cloud-Ressource bereitstellen.

**Aufgabe**: Schreibe eine Terraform-Konfiguration, die eine e2-micro-VM in GCP erstellt, und demonstriere den Plan > Apply-Workflow.

1. **Terraform-Konfiguration erweitern**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         google = {
           source  = "hashicorp/google"
           version = "~> 5.0"
         }
       }
     }

     provider "google" {
       project     = "homelab-lamp-123456"
       region      = "europe-west1"
       zone        = "europe-west1-b"
       credentials = file("${path.module}/homelab-lamp-123456-abc123.json")
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

     output "vm_public_ip" {
       value       = google_compute_instance.lamp_vm.network_interface[0].access_config[0].nat_ip
       description = "Öffentliche IP der VM"
     }
     ```
   - **Erklärung**:
     - `google_compute_instance`: Erstellt eine e2-micro-VM mit Ubuntu 22.04 LTS.
     - `google_compute_firewall`: Öffnet Ports 80, 443 und 22 für HTTP, HTTPS und SSH.
     - `output`: Gibt die öffentliche IP der VM aus.

2. **Plan > Apply-Workflow**:
   - Prüfe den Plan:
     ```bash
     terraform plan
     ```
     - Zeigt, dass eine VM und eine Firewall-Regel erstellt werden.
   - Wende an:
     ```bash
     terraform apply -auto-approve
     ```
     - Erwartete Ausgabe:
       ```
       Outputs:
       vm_public_ip = "34.123.45.67"
       ```

3. **VM in der GCP-Konsole prüfen**:
   - Öffne `https://console.cloud.google.com/compute/instances`.
   - Suche nach `lamp-vm` im Projekt `homelab-lamp`.
   - Erwartete Ausgabe: VM mit Status `Running`, öffentliche IP (z. B. `34.123.45.67`).
   - Teste SSH-Zugriff:
     ```bash
     ssh ubuntu@34.123.45.67
     ```

**Erkenntnis**: Der Plan > Apply-Workflow ermöglicht die deklarative Bereitstellung von Cloud-Ressourcen. Terraform interagiert mit der GCP-API, um die VM zu erstellen, und die Konsole zeigt die Ergebnisse in Echtzeit.

**Quelle**: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance

### Übung 6: Module für skalierbare Konfigurationen

**Ziel**: Skalierbare und wartbare Infrastruktur-Konfigurationen erstellen.

**Aufgabe**: Modularisiere die VM-Bereitstellung aus Übung 5 in ein Modul `modules/vm` und rufe es in der Hauptkonfiguration auf.

1. **Modulstruktur erstellen**:
   ```bash
   mkdir -p modules/vm
   ```
2. **Modul-Konfiguration erstellen**:
   - Erstelle `modules/vm/main.tf`:
     ```bash
     nano modules/vm/main.tf
     ```
     - Inhalt:
       ```hcl
       resource "google_compute_instance" "vm" {
         name         = var.vm_name
         machine_type = var.machine_type
         zone         = var.zone

         boot_disk {
           initialize_params {
             image = var.image
             size  = var.disk_size
           }
         }

         network_interface {
           network = "default"
           access_config {
             // Ephemeral public IP
           }
         }

         metadata = {
           ssh-keys = "ubuntu:${file(var.ssh_key_path)}"
         }

         tags = var.tags
       }

       resource "google_compute_firewall" "firewall" {
         name    = "allow-${var.vm_name}"
         network = "default"

         allow {
           protocol = "tcp"
           ports    = var.ports
         }

         source_ranges = ["0.0.0.0/0"]
         target_tags   = var.tags
       }

       output "vm_public_ip" {
         value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
         description = "Öffentliche IP der VM"
       }
       ```
   - Erstelle `modules/vm/variables.tf`:
     ```bash
     nano modules/vm/variables.tf
     ```
     - Inhalt:
       ```hcl
       variable "vm_name" {
         type        = string
         description = "Name der VM"
       }

       variable "machine_type" {
         type        = string
         description = "Maschinentyp der VM"
         default     = "e2-micro"
       }

       variable "zone" {
         type        = string
         description = "Zone der VM"
       }

       variable "image" {
         type        = string
         description = "Betriebssystem-Image der VM"
         default     = "ubuntu-2204-jammy-v20250901"
       }

       variable "disk_size" {
         type        = number
         description = "Größe der Boot-Disk in GB"
         default     = 10
       }

       variable "ssh_key_path" {
         type        = string
         description = "Pfad zur öffentlichen SSH-Schlüssel-Datei"
       }

       variable "tags" {
         type        = list(string)
         description = "Tags für die VM und Firewall"
         default     = ["http-server", "https-server"]
       }

       variable "ports" {
         type        = list(string)
         description = "Zu öffnende Ports in der Firewall"
         default     = ["80", "443", "22"]
       }
       ```
   - Erstelle `modules/vm/outputs.tf`:
     ```bash
     nano modules/vm/outputs.tf
     ```
     - Inhalt:
       ```hcl
       output "vm_name" {
         value       = google_compute_instance.vm.name
         description = "Name der erstellten VM"
       }

       output "vm_public_ip" {
         value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
         description = "Öffentliche IP der VM"
       }
       ```

3. **Haupt-Konfiguration anpassen**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         google = {
           source  = "hashicorp/google"
           version = "~> 5.0"
         }
       }
     }

     provider "google" {
       project     = "homelab-lamp-123456"
       region      = "europe-west1"
       zone        = "europe-west1-b"
       credentials = file("${path.module}/homelab-lamp-123456-abc123.json")
     }

     module "lamp_vm" {
       source        = "./modules/vm"
       vm_name       = "lamp-vm"
       machine_type  = "e2-micro"
       zone          = "europe-west1-b"
       image         = "ubuntu-2204-jammy-v20250901"
       disk_size     = 10
       ssh_key_path  = "~/.ssh/id_rsa.pub"
       tags          = ["http-server", "https-server"]
       ports         = ["80", "443", "22"]
     }

     output "vm_public_ip" {
       value       = module.lamp_vm.vm_public_ip
       description = "Öffentliche IP der VM"
     }
     ```

4. **Terraform ausführen**:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
   - Erwartete Ausgabe:
     ```
     Outputs:
     vm_public_ip = "34.123.45.67"
     ```

5. **VM in der GCP-Konsole prüfen**:
   - Öffne `https://console.cloud.google.com/compute/instances`.
   - Suche nach `lamp-vm` im Projekt `homelab-lamp`.
   - Teste SSH-Zugriff:
     ```bash
     ssh ubuntu@34.123.45.67
     ```

**Erkenntnis**: Module vermeiden Code-Wiederholung und ermöglichen skalierbare, wartbare Konfigurationen. Das `vm`-Modul kapselt VM- und Firewall-Ressourcen und ist durch Variablen flexibel anpassbar.

**Quelle**: https://www.terraform.io/docs/language/modules/develop/index.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-gcp-backup-$(date +%F).tar.gz ~/terraform-gcp
     rsync -av ~/terraform-gcp-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-gcp-backup-$DATE.tar.gz ~/terraform-gcp
       rsync -av /home/ubuntu/terraform-gcp-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-gcp-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-gcp-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-gcp
     terraform init
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Remote State mit GCS**:
   - Erstelle einen Google Cloud Storage Bucket für den State:
     ```bash
     nano main.tf
     ```
     - Füge hinzu:
       ```hcl
       terraform {
         backend "gcs" {
           bucket  = "homelab-lamp-backups"
           prefix  = "terraform/state"
         }
       }
       ```
   - Initialisiere:
     ```bash
     terraform init -reconfigure
     ```
2. **Provisioner für VM-Konfiguration**:
   - Erweitere `modules/vm/main.tf` um einen `local-exec`-Provisioner:
     ```hcl
     resource "null_resource" "configure_vm" {
       provisioner "local-exec" {
         command = "ssh ubuntu@${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip} 'sudo apt update && sudo apt install -y apache2'"
       }
       depends_on = [google_compute_instance.vm]
     }
     ```
   - **Erklärung**: Installiert Apache2 auf der VM nach der Erstellung.

## Best Practices für Schüler

- **Kostenmanagement**:
  - Nutze den Free Tier (e2-micro-VM).
  - Überwache Kosten: `Billing > Overview` in der GCP-Konsole.
  - Zerstöre Ressourcen nach dem Test:
    ```bash
    terraform destroy -auto-approve
    ```
- **Sicherheit**:
  - Schränke SSH-Zugriff ein:
    ```bash
    nano modules/vm/main.tf
    ```
    - Passe die Firewall an:
      ```hcl
      source_ranges = ["192.168.20.0/24"] # HomeLab-Management
      ```
  - Sichere die Service-Konto-Schlüssel-Datei:
    ```bash
    chmod 600 ~/terraform-gcp/homelab-lamp-123456-abc123.json
    ```
- **Fehlerbehebung**:
  - Validiere Konfigurationen:
    ```bash
    terraform validate
    terraform fmt
    ```
  - Prüfe detaillierte Pläne:
    ```bash
    terraform plan -out=tfplan
    terraform show tfplan
    ```
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, Google Cloud Storage.
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: Google Cloud Storage.
- **Modul-Organisation**:
  - Strukturiere Module klar (`main.tf`, `variables.tf`, `outputs.tf`).
  - Verwende sprechende Variablen- und Output-Namen.

**Quelle**: https://www.terraform.io/docs/language/settings/backends/gcs.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: GCP-Provider, e2-micro-VM, modularisierte Konfiguration.
  - **Workloads**: Bereitstellung einer VM mit HTTP/HTTPS/SSH-Zugriff.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - GCP: Nutze Free Tier und $300-Guthaben.
  - HomeLab: Sichere Konfigurationen auf TrueNAS.
- **Beispiel**:
  - VM-Bereitstellung mit modularisierter Konfiguration, erreichbar über SSH.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einzelnen VM und erweitere schrittweise.
- **Übung**: Experimentiere mit weiteren GCP-Ressourcen (z. B. Cloud Storage, GKE).
- **Fehlerbehebung**: Nutze `terraform console` für Debugging:
  ```bash
  terraform console
  > module.lamp_vm.vm_public_ip
  ```
- **Lernressourcen**: Nutze https://learn.hashicorp.com/terraform und https://www.qwiklabs.com.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt (Modul 4: Terraform mit Cloud-Anbietern) bietet:
- **Praxisorientiert**: Bereitstellung einer VM in GCP mit modularer Konfiguration.
- **Einfachheit**: Free Tier und klare Schritte erleichtern den Einstieg.
- **Lernwert**: Verständnis von Provider-Authentifizierung, Cloud-Ressourcen und Modularisierung.

Es ist ideal für Schüler, die IaC mit Cloud-Anbietern lernen möchten, und verbindet Terraform-Konzepte mit GCP und HomeLab.

**Nächste Schritte**: Möchtest du ein Modul 5 mit weiteren GCP-Ressourcen (z. B. Cloud Storage, GKE), eine Anleitung zu Monitoring mit Check_MK/Prometheus, oder eine Integration mit Ansible für Softwarekonfiguration?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- GCP Terraform Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- GCP-Dokumentation: https://cloud.google.com/docs
- Webquellen:,,,,,,,,,,,,,,
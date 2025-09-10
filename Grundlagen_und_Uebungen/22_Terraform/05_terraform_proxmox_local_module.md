# Lernprojekt: Terraform mit Proxmox (lokale HomeLab-Integration)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet. Dieses Lernprojekt überträgt die Konzepte aus den vorherigen Modulen (`01_terraform_basics_module1.md`, `02_terraform_advanced_module2.md`, `03_terraform_advanced_module3.md`, `04_terraform_gcp_module4.md`) auf einen lokalen Proxmox VE-Server in einer HomeLab-Umgebung. Es nutzt den Proxmox-Provider (`telmate/proxmox`), um virtuelle Maschinen (VMs) bereitzustellen, und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Das Projekt umfasst drei Übungen: die Einrichtung des Proxmox-Providers mit Authentifizierung, die Bereitstellung einer Ubuntu-VM und die Modularisierung der VM-Konfiguration. Es ist für Anfänger mit Grundkenntnissen in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces) und Proxmox geeignet und wird lokal auf einer Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) ausgeführt.

**Voraussetzungen**:
- Proxmox VE-Server (z. B. Version 8.x) in der HomeLab, erreichbar unter einer IP (z. B. `192.168.30.10`).
- Proxmox-Benutzer mit API-Zugriff (z. B. `terraform@pve`) und Token.
- Terraform installiert (Version 1.5.7, wie in Modul 1):
  ```bash
  terraform version  # Erwartet: Terraform v1.5.7
  ```
- Grundkenntnisse in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces aus Modul 1–4) und Linux (z. B. `bash`, `nano`).
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Ubuntu-ISO-Image auf Proxmox hochgeladen (z. B. `ubuntu-22.04.5-server-amd64.iso` in Storage `local`).
- Lokale Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) mit SSH-Zugang.

**Ziele**:
- Einrichten des Proxmox-Providers mit API-Authentifizierung.
- Bereitstellen einer Ubuntu-VM auf Proxmox mit Terraform.
- Modularisieren der VM-Konfiguration für Wiederverwendbarkeit.

**Hinweis**: Das Projekt ist kostenlos, da es lokal in der HomeLab ausgeführt wird und keine Cloud-Ressourcen benötigt.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Proxmox-Provider: https://registry.terraform.io/providers/telmate/proxmox/latest/docs
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Terraform mit Proxmox

### Vorbereitung: Projekt einrichten
1. **Terraform installieren** (falls nicht vorhanden, siehe Modul 1):
   ```bash
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version  # Erwartet: Terraform v1.5.7
   ```
2. **Proxmox-API-Zugriff einrichten**:
   - Melde dich in der Proxmox-Weboberfläche an (`https://192.168.30.10:8006`).
   - Erstelle einen Benutzer:
     - Gehe zu `Datacenter > Permissions > Users > Add`.
     - Name: `terraform@pve`, Passwort setzen (z. B. `securepassword123`).
   - Erstelle einen API-Token:
     - Gehe zu `Datacenter > Permissions > API Tokens > Add`.
     - Benutzer: `terraform@pve`, Token-ID: `terraform-token`, Privilege Separation: deaktivieren.
     - Notiere den Token-Secret (z. B. `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
   - Füge Berechtigungen hinzu:
     - Gehe zu `Datacenter > Permissions > Add > User Permission`.
     - Path: `/`, Benutzer: `terraform@pve`, Rolle: `PVEAdmin`.
3. **ISO-Image hochladen**:
   - Lade `ubuntu-22.04.5-server-amd64.iso` herunter:
     ```bash
     wget https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso -P /tmp
     ```
   - Kopiere es nach Proxmox (Storage `local`):
     ```bash
     scp /tmp/ubuntu-22.04.5-live-server-amd64.iso root@192.168.30.10:/var/lib/vz/template/iso/
     ```
   - Prüfe in der Proxmox-Weboberfläche: `local > ISO Images`.
4. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-proxmox
   cd ~/terraform-proxmox
   ```

**Tipp**: Arbeite auf einer lokalen Maschine (z. B. Proxmox-VM oder PC) mit Zugriff auf den Proxmox-Server.

### Übung 1: Proxmox-Provider und Authentifizierung

**Ziel**: Die Verbindung zwischen Terraform und Proxmox herstellen.

**Aufgabe**: Konfiguriere den Proxmox-Provider mit API-Token-Authentifizierung in `main.tf`.

1. **Terraform-Konfiguration erstellen**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         proxmox = {
           source  = "telmate/proxmox"
           version = "~> 2.9"
         }
       }
     }

     provider "proxmox" {
       pm_api_url          = "https://192.168.30.10:8006/api2/json"
       pm_api_token_id     = "terraform@pve!terraform-token"
       pm_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       pm_tls_insecure     = true # Für selbstsignierte Zertifikate
     }
     ```
   - **Erklärung**:
     - `required_providers`: Spezifiziert den Proxmox-Provider.
     - `provider "proxmox"`: Konfiguriert die Verbindung mit der Proxmox-API, Token-ID und Secret.
     - `pm_tls_insecure`: Überspringt TLS-Prüfung für selbstsignierte Zertifikate (nur für Testumgebungen).

2. **Terraform initialisieren**:
   ```bash
   terraform init
   ```
   - Lädt den Proxmox-Provider herunter.

3. **Provider testen**:
   ```bash
   terraform plan
   ```
   - Erwartete Ausgabe: Keine Änderungen, da noch keine Ressourcen definiert sind.

**Erkenntnis**: Der Proxmox-Provider ermöglicht Terraform, mit der Proxmox-API zu interagieren. Die API-Token-Authentifizierung ist sicherer als Passwort-Authentifizierung und ideal für Automatisierung.

**Quelle**: https://registry.terraform.io/providers/telmate/proxmox/latest/docs

### Übung 2: Bereitstellung einer virtuellen Maschine (VM)

**Ziel**: Eine Ubuntu-VM auf Proxmox mit Terraform bereitstellen.

**Aufgabe**: Schreibe eine Terraform-Konfiguration, die eine Ubuntu-VM erstellt, und demonstriere den Plan > Apply-Workflow.

1. **Terraform-Konfiguration erweitern**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         proxmox = {
           source  = "telmate/proxmox"
           version = "~> 2.9"
         }
       }
     }

     provider "proxmox" {
       pm_api_url          = "https://192.168.30.10:8006/api2/json"
       pm_api_token_id     = "terraform@pve!terraform-token"
       pm_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       pm_tls_insecure     = true
     }

     resource "proxmox_vm_qemu" "ubuntu_vm" {
       name        = "ubuntu-vm"
       target_node = "pve" # Name des Proxmox-Knotens
       vmid        = 100   # Eindeutige VM-ID

       clone = "ubuntu-2204-template" # Optional: Vorhandenes Template, falls erstellt

       os_type   = "ubuntu"
       cores     = 2
       sockets   = 1
       cpu       = "host"
       memory    = 2048
       scsihw    = "virtio-scsi-pci"
       bootdisk  = "scsi0"

       disk {
         size    = "10G"
         type    = "scsi"
         storage = "local-lvm"
       }

       network {
         model  = "virtio"
         bridge = "vmbr0"
       }

       iso = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"

       # Cloud-Init-Einstellungen
       ciuser     = "ubuntu"
       cipassword = "securepassword123"
       sshkeys    = file("~/.ssh/id_rsa.pub")
     }

     output "vm_id" {
       value       = proxmox_vm_qemu.ubuntu_vm.vmid
       description = "ID der erstellten VM"
     }
     ```
   - **Erklärung**:
     - `proxmox_vm_qemu`: Erstellt eine QEMU-VM mit Ubuntu 22.04.5.
     - `target_node`: Name des Proxmox-Knotens (z. B. `pve`).
     - `clone`: Optional, wenn ein Template vorhanden ist (hier auskommentiert).
     - `iso`: Verweist auf das hochgeladene ISO-Image.
     - `disk`: 10 GB Festplatte im Storage `local-lvm`.
     - `network`: Netzwerkadapter mit Bridge `vmbr0` (Standard in Proxmox).
     - `ciuser`, `cipassword`, `sshkeys`: Cloud-Init für Benutzer und SSH-Zugriff.
     - `output`: Gibt die VM-ID aus.

2. **Plan > Apply-Workflow**:
   - Prüfe den Plan:
     ```bash
     terraform plan
     ```
     - Zeigt, dass eine VM erstellt wird.
   - Wende an:
     ```bash
     terraform apply -auto-approve
     ```
     - Erwartete Ausgabe:
       ```
       Outputs:
       vm_id = 100
       ```

3. **VM in der Proxmox-Weboberfläche prüfen**:
   - Öffne `https://192.168.30.10:8006`.
   - Gehe zu `pve > ubuntu-vm`.
   - Erwartete Ausgabe: VM `ubuntu-vm` (ID 100) mit Status `Running`.
   - Starte die VM (falls nicht automatisch gestartet) und verbinde dich über die Konsole oder SSH:
     ```bash
     ssh ubuntu@<VM-IP> # IP aus Proxmox-Weboberfläche oder DHCP
     ```

**Hinweis**: Stelle sicher, dass `vmbr0` mit deinem Netzwerk (z. B. via OPNsense) verbunden ist, damit die VM eine IP erhält.

**Erkenntnis**: Terraform kann Proxmox-VMs deklarativ erstellen, ähnlich wie Cloud-Ressourcen. Der Plan > Apply-Workflow automatisiert die Bereitstellung, und Cloud-Init erleichtert die VM-Konfiguration.

**Quelle**: https://registry.terraform.io/providers/telmate/proxmox/latest/docs/resources/vm_qemu

### Übung 3: Module für skalierbare Konfigurationen

**Ziel**: Skalierbare und wartbare VM-Konfigurationen erstellen.

**Aufgabe**: Modularisiere die VM-Bereitstellung aus Übung 2 in ein Modul `modules/proxmox-vm` und rufe es in der Hauptkonfiguration auf.

1. **Modulstruktur erstellen**:
   ```bash
   mkdir -p modules/proxmox-vm
   ```
2. **Modul-Konfiguration erstellen**:
   - Erstelle `modules/proxmox-vm/main.tf`:
     ```bash
     nano modules/proxmox-vm/main.tf
     ```
     - Inhalt:
       ```hcl
       resource "proxmox_vm_qemu" "vm" {
         name        = var.vm_name
         target_node = var.target_node
         vmid        = var.vmid

         os_type   = var.os_type
         cores     = var.cores
         sockets   = var.sockets
         cpu       = var.cpu
         memory    = var.memory
         scsihw    = var.scsihw
         bootdisk  = var.bootdisk

         disk {
           size    = var.disk_size
           type    = "scsi"
           storage = var.storage
         }

         network {
           model  = "virtio"
           bridge = var.network_bridge
         }

         iso = var.iso

         ciuser     = var.ciuser
         cipassword = var.cipassword
         sshkeys    = file(var.ssh_key_path)
       }

       output "vm_id" {
         value       = proxmox_vm_qemu.vm.vmid
         description = "ID der erstellten VM"
       }
       ```
   - Erstelle `modules/proxmox-vm/variables.tf`:
     ```bash
     nano modules/proxmox-vm/variables.tf
     ```
     - Inhalt:
       ```hcl
       variable "vm_name" {
         type        = string
         description = "Name der VM"
       }

       variable "target_node" {
         type        = string
         description = "Proxmox-Knoten"
         default     = "pve"
       }

       variable "vmid" {
         type        = number
         description = "Eindeutige VM-ID"
       }

       variable "os_type" {
         type        = string
         description = "Betriebssystem-Typ"
         default     = "ubuntu"
       }

       variable "cores" {
         type        = number
         description = "Anzahl der CPU-Kerne"
         default     = 2
       }

       variable "sockets" {
         type        = number
         description = "Anzahl der CPU-Sockets"
         default     = 1
       }

       variable "cpu" {
         type        = string
         description = "CPU-Typ"
         default     = "host"
       }

       variable "memory" {
         type        = number
         description = "RAM in MB"
         default     = 2048
       }

       variable "scsihw" {
         type        = string
         description = "SCSI-Controller"
         default     = "virtio-scsi-pci"
       }

       variable "bootdisk" {
         type        = string
         description = "Boot-Disk"
         default     = "scsi0"
       }

       variable "disk_size" {
         type        = string
         description = "Größe der Festplatte"
         default     = "10G"
       }

       variable "storage" {
         type        = string
         description = "Storage für die Festplatte"
         default     = "local-lvm"
       }

       variable "network_bridge" {
         type        = string
         description = "Netzwerk-Bridge"
         default     = "vmbr0"
       }

       variable "iso" {
         type        = string
         description = "Pfad zum ISO-Image"
       }

       variable "ciuser" {
         type        = string
         description = "Cloud-Init-Benutzer"
         default     = "ubuntu"
       }

       variable "cipassword" {
         type        = string
         description = "Cloud-Init-Passwort"
         sensitive   = true
       }

       variable "ssh_key_path" {
         type        = string
         description = "Pfad zur öffentlichen SSH-Schlüssel-Datei"
       }
       ```
   - Erstelle `modules/proxmox-vm/outputs.tf`:
     ```bash
     nano modules/proxmox-vm/outputs.tf
     ```
     - Inhalt:
       ```hcl
       output "vm_id" {
         value       = proxmox_vm_qemu.vm.vmid
         description = "ID der erstellten VM"
       }

       output "vm_name" {
         value       = proxmox_vm_qemu.vm.name
         description = "Name der erstellten VM"
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
         proxmox = {
           source  = "telmate/proxmox"
           version = "~> 2.9"
         }
       }
     }

     provider "proxmox" {
       pm_api_url          = "https://192.168.30.10:8006/api2/json"
       pm_api_token_id     = "terraform@pve!terraform-token"
       pm_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       pm_tls_insecure     = true
     }

     module "ubuntu_vm" {
       source        = "./modules/proxmox-vm"
       vm_name       = "ubuntu-vm"
       vmid          = 100
       iso           = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
       cipassword    = "securepassword123"
       ssh_key_path  = "~/.ssh/id_rsa.pub"
     }

     output "vm_id" {
       value       = module.ubuntu_vm.vm_id
       description = "ID der erstellten VM"
     }

     output "vm_name" {
       value       = module.ubuntu_vm.vm_name
       description = "Name der erstellten VM"
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
     vm_id = 100
     vm_name = "ubuntu-vm"
     ```

5. **VM in der Proxmox-Weboberfläche prüfen**:
   - Öffne `https://192.168.30.10:8006`.
   - Gehe zu `pve > ubuntu-vm`.
   - Starte die VM und verbinde dich über die Konsole oder SSH:
     ```bash
     ssh ubuntu@<VM-IP>
     ```

**Erkenntnis**: Module machen Proxmox-VM-Konfigurationen wiederverwendbar und skalierbar. Das `proxmox-vm`-Modul kapselt VM-Parameter und erleichtert die Verwaltung mehrerer VMs.

**Quelle**: https://www.terraform.io/docs/language/modules/develop/index.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-proxmox-backup-$(date +%F).tar.gz ~/terraform-proxmox
     rsync -av ~/terraform-proxmox-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-proxmox-backup-$DATE.tar.gz ~/terraform-proxmox
       rsync -av /home/ubuntu/terraform-proxmox-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-proxmox-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-proxmox-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-proxmox
     terraform init
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Remote State mit TrueNAS**:
   - Nutze TrueNAS als Remote State Backend (simuliert via NFS):
     ```bash
     sudo apt install nfs-common
     sudo mkdir /mnt/terraform-state
     sudo mount 192.168.30.100:/mnt/tank/terraform-state /mnt/terraform-state
     ```
   - Passe `main.tf` an:
     ```hcl
     terraform {
       backend "local" {
         path = "/mnt/terraform-state/terraform.tfstate"
       }
     }
     ```
   - Initialisiere:
     ```bash
     terraform init -reconfigure
     ```
2. **Provisioner für VM-Konfiguration**:
   - Erweitere `modules/proxmox-vm/main.tf` um einen `remote-exec`-Provisioner:
     ```hcl
     resource "proxmox_vm_qemu" "vm" {
       # ... Bestehende Konfiguration ...
       provisioner "remote-exec" {
         connection {
           type        = "ssh"
           user        = var.ciuser
           private_key = file(var.ssh_key_path)
           host        = "VM-IP" # Muss manuell gesetzt werden oder via Proxmox-API
         }
         inline = [
           "sudo apt update",
           "sudo apt install -y apache2"
         ]
       }
     }
     ```
   - **Hinweis**: Ersetze `"VM-IP"` durch die tatsächliche IP der VM (aus Proxmox-Weboberfläche).

## Best Practices für Schüler

- **Sicherheit**:
  - Sichere den API-Token:
    ```bash
    chmod 600 main.tf # Falls Token in Datei
    ```
  - Verwende Umgebungsvariablen für sensible Daten:
    ```bash
    export PM_API_TOKEN_SECRET="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    ```
    - Passe `main.tf` an:
      ```hcl
      pm_api_token_secret = var.pm_api_token_secret
      ```
    - Erstelle `variables.tf`:
      ```hcl
      variable "pm_api_token_secret" {
        type      = string
        sensitive = true
      }
      ```
  - Schränke Netzwerkzugriff via OPNsense ein:
    - Füge eine Firewall-Regel in OPNsense hinzu, um nur `192.168.30.0/24` den Zugriff auf `192.168.30.10:8006` zu erlauben.
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
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).
- **Modul-Organisation**:
  - Strukturiere Module klar (`main.tf`, `variables.tf`, `outputs.tf`).
  - Verwende Standardwerte für häufige Parameter (z. B. `cores`, `memory`).

**Quelle**: https://registry.terraform.io/providers/telmate/proxmox/latest/docs

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Proxmox-Provider, Ubuntu-VM, modularisierte Konfiguration.
  - **Workloads**: Bereitstellung einer VM mit SSH-Zugriff.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - Proxmox: Nutze lokale Ressourcen der HomeLab.
  - HomeLab: Sichere Konfigurationen auf TrueNAS.
- **Beispiel**:
  - VM-Bereitstellung mit modularisierter Konfiguration, erreichbar über SSH.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einzelnen VM und erweitere schrittweise.
- **Übung**: Experimentiere mit weiteren Proxmox-Ressourcen (z. B. LXC-Container).
- **Fehlerbehebung**: Nutze `terraform console` für Debugging:
  ```bash
  terraform console
  > module.ubuntu_vm.vm_id
  ```
- **Lernressourcen**: Nutze https://www.terraform.io/docs und https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Bereitstellung einer VM auf Proxmox mit modularer Konfiguration.
- **Einfachheit**: Lokale HomeLab-Umgebung ohne Cloud-Kosten.
- **Lernwert**: Verständnis von Proxmox-Provider, API-Authentifizierung und Modularisierung.

Es ist ideal für Schüler, die IaC in einer HomeLab-Umgebung lernen möchten, und verbindet Terraform-Konzepte mit Proxmox und HomeLab-Integration.

**Nächste Schritte**: Möchtest du eine Anleitung zu weiteren Proxmox-Ressourcen (z. B. LXC-Container), eine Integration mit Ansible für Softwarekonfiguration, oder Monitoring mit Check_MK/Prometheus?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Proxmox-Provider: https://registry.terraform.io/providers/telmate/proxmox/latest/docs
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,,,,,,,,,,
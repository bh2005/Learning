# Lernprojekt: Terraform und Ansible als Team (lokale HomeLab-Integration)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet, um Infrastruktur bereitzustellen. **Ansible** ist ein Open-Source-Tool für **Konfigurationsmanagement**, das Playbooks in YAML verwendet, um Software und Konfigurationen zu automatisieren. Dieses Lernprojekt kombiniert Terraform und Ansible in einer lokalen HomeLab-Umgebung, um eine virtuelle Maschine (VM) auf einem Proxmox VE-Server bereitzustellen und mit Ansible zu konfigurieren (z. B. Apache-Webserver-Installation). Es baut auf den vorherigen Modulen (`01_terraform_basics_module1.md`, `02_terraform_advanced_module2.md`, `03_terraform_advanced_module3.md`, `04_terraform_gcp_module4.md`, `05_terraform_proxmox_local_module.md`) auf und ist für Lernende mit Grundkenntnissen in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules) und Ansible (z. B. Playbooks, Inventories) geeignet. Das Projekt nutzt den Proxmox-Provider (`telmate/proxmox`) und integriert die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und Netzwerkmanagement. Es umfasst drei Übungen: die Bereitstellung einer VM mit Terraform, die Integration von Ansible zur Konfiguration und die Modularisierung des Workflows.

**Voraussetzungen**:
- Proxmox VE-Server (z. B. Version 8.x) in der HomeLab, erreichbar unter einer IP (z. B. `192.168.30.10`).
- Proxmox-Benutzer mit API-Zugriff (z. B. `terraform@pve`) und Token, wie in `05_terraform_proxmox_local_module.md`.
- Terraform installiert (Version 1.5.7):
  ```bash
  terraform version  # Erwartet: Terraform v1.5.7
  ```
- Ansible installiert (Version 2.10 oder höher):
  ```bash
  ansible --version  # Erwartet: ansible [core 2.10.x oder höher]
  ```
- Grundkenntnisse in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules) und Ansible (z. B. Playbooks, Inventories).
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- Ubuntu-ISO-Image auf Proxmox hochgeladen (z. B. `ubuntu-22.04.5-server-amd64.iso` in Storage `local`).
- Lokale Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) mit SSH-Zugang.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub` und `~/.ssh/id_rsa`).

**Ziele**:
- Bereitstellen einer Ubuntu-VM auf Proxmox mit Terraform.
- Konfigurieren der VM mit Ansible (z. B. Apache-Installation).
- Modularisieren des Terraform-Ansible-Workflows für Wiederverwendbarkeit.

**Hinweis**: Das Projekt ist kostenlos, da es lokal in der HomeLab ausgeführt wird und keine Cloud-Ressourcen benötigt.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Proxmox-Provider: https://registry.terraform.io/providers/telmate/proxmox/latest/docs
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,,,,,,,,,,

## Lernprojekt: Terraform und Ansible als Team

### Vorbereitung: Projekt einrichten
1. **Terraform installieren** (falls nicht vorhanden, siehe Modul 1):
   ```bash
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version  # Erwartet: Terraform v1.5.7
   ```
2. **Ansible installieren**:
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ansible --version  # Erwartet: ansible [core 2.10.x oder höher]
   ```
3. **Proxmox-API-Zugriff prüfen** (siehe `05_terraform_proxmox_local_module.md`):
   - Benutzer: `terraform@pve`, Token-ID: `terraform-token`, Token-Secret: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`.
   - Berechtigungen: `PVEAdmin` auf `/`.
4. **ISO-Image prüfen**:
   - Stelle sicher, dass `ubuntu-22.04.5-server-amd64.iso` in `local:iso` auf Proxmox verfügbar ist:
     ```bash
     ssh root@192.168.30.10 ls /var/lib/vz/template/iso/
     ```
     - Falls nicht vorhanden:
       ```bash
       wget https://releases.ubuntu.com/22.04.5/ubuntu-22.04.5-live-server-amd64.iso -P /tmp
       scp /tmp/ubuntu-22.04.5-live-server-amd64.iso root@192.168.30.10:/var/lib/vz/template/iso/
       ```
5. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-ansible
   cd ~/terraform-ansible
   mkdir ansible
   ```

**Tipp**: Arbeite auf einer lokalen Maschine (z. B. Proxmox-VM oder PC) mit Zugriff auf den Proxmox-Server.

### Übung 1: VM-Bereitstellung mit Terraform

**Ziel**: Eine Ubuntu-VM auf Proxmox mit Terraform bereitstellen.

**Aufgabe**: Schreibe eine Terraform-Konfiguration, die eine Ubuntu-VM erstellt, und stelle die IP-Adresse für Ansible bereit.

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
       pm_tls_insecure     = true
     }

     resource "proxmox_vm_qemu" "ubuntu_vm" {
       name        = "ansible-vm"
       target_node = "pve"
       vmid        = 101

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
     - `proxmox_vm_qemu`: Erstellt eine VM mit Ubuntu 22.04.5, 2 Kernen, 2 GB RAM, 10 GB Festplatte.
     - `network`: Verbindet die VM mit `vmbr0` (via OPNsense für DHCP).
     - `ciuser`, `cipassword`, `sshkeys`: Cloud-Init für SSH-Zugriff.

2. **Terraform ausführen**:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
   - Erwartete Ausgabe:
     ```
     Outputs:
     vm_id = 101
     ```

3. **VM-IP ermitteln**:
   - Öffne die Proxmox-Weboberfläche (`https://192.168.30.10:8006`).
   - Gehe zu `pve > ansible-vm > Summary > Network`.
   - Notiere die IP-Adresse (z. B. `192.168.30.101`, zugeteilt via DHCP durch OPNsense).
   - Teste SSH-Zugriff:
     ```bash
     ssh ubuntu@192.168.30.101
     ```

**Erkenntnis**: Terraform erstellt die Infrastruktur (VM) deklarativ. Die VM-IP wird manuell aus Proxmox ermittelt, da der Proxmox-Provider keine direkte IP-Ausgabe unterstützt.

**Quelle**: https://registry.terraform.io/providers/telmate/proxmox/latest/docs/resources/vm_qemu

### Übung 2: Ansible-Integration für VM-Konfiguration

**Ziel**: Konfiguriere die VM mit Ansible (Apache-Webserver-Installation).

**Aufgabe**: Schreibe ein Ansible-Playbook, das Apache auf der VM installiert, und integriere es mit Terraform.

1. **Ansible-Inventory erstellen**:
   ```bash
   nano ansible/inventory.yml
   ```
   - Inhalt:
     ```yaml
     all:
       hosts:
         ansible-vm:
           ansible_host: 192.168.30.101
           ansible_user: ubuntu
           ansible_ssh_private_key_file: ~/.ssh/id_rsa
     ```
   - **Erklärung**: Definiert die VM als Ziel, nutzt die IP aus Übung 1.

2. **Ansible-Playbook erstellen**:
   ```bash
   nano ansible/install_apache.yml
   ```
   - Inhalt:
     ```yaml
     ---
     - name: Install and configure Apache
       hosts: ansible-vm
       become: yes
       tasks:
         - name: Update package cache
           apt:
             update_cache: yes
         - name: Install Apache2
           apt:
             name: apache2
             state: present
         - name: Start Apache2 service
           service:
             name: apache2
             state: started
             enabled: yes
         - name: Create test HTML page
           copy:
             content: "<h1>Willkommen bei Terraform und Ansible!</h1>"
             dest: /var/www/html/index.html
             mode: '0644'
     ```
   - **Erklärung**:
     - Installiert Apache2, startet den Dienst und erstellt eine Test-HTML-Seite.

3. **Ansible mit Terraform verbinden**:
   - Erweitere `main.tf` um einen `null_resource` mit `local-exec`-Provisioner:
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
           null = {
             source  = "hashicorp/null"
             version = "~> 3.2"
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
         name        = "ansible-vm"
         target_node = "pve"
         vmid        = 101

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

         ciuser     = "ubuntu"
         cipassword = "securepassword123"
         sshkeys    = file("~/.ssh/id_rsa.pub")
       }

       resource "null_resource" "ansible_provision" {
         provisioner "local-exec" {
           command = "ansible-playbook -i ansible/inventory.yml ansible/install_apache.yml"
           environment = {
             ANSIBLE_HOST_KEY_CHECKING = "False"
           }
         }
         depends_on = [proxmox_vm_qemu.ubuntu_vm]
       }

       output "vm_id" {
         value       = proxmox_vm_qemu.ubuntu_vm.vmid
         description = "ID der erstellten VM"
       }
       ```
   - **Erklärung**:
     - `null_resource.ansible_provision`: Führt das Ansible-Playbook nach der VM-Erstellung aus.
     - `depends_on`: Stellt sicher, dass die VM erstellt ist.
     - `environment`: Deaktiviert SSH-Host-Key-Prüfung für die erste Verbindung.

4. **Terraform und Ansible ausführen**:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
   - Erwartete Ausgabe: VM wird erstellt, Ansible installiert Apache2.
   - Prüfe die Webseite:
     ```bash
     curl http://192.168.30.101
     ```
     - Erwartete Ausgabe:
       ```
       <h1>Willkommen bei Terraform und Ansible!</h1>
       ```

5. **VM in der Proxmox-Weboberfläche prüfen**:
   - Öffne `https://192.168.30.10:8006`.
   - Gehe zu `pve > ansible-vm`.
   - Erwartete Ausgabe: VM `ansible-vm` (ID 101) mit Status `Running`.

**Erkenntnis**: Terraform erstellt die Infrastruktur, während Ansible die Softwarekonfiguration übernimmt. Der `local-exec`-Provisioner verbindet beide Tools, ist aber auf eine manuelle IP-Zuweisung angewiesen.

**Quelle**: https://docs.ansible.com/ansible/latest/user_guide/playbooks.html

### Übung 3: Modularisierung des Terraform-Ansible-Workflows

**Ziel**: Modularisiere den Terraform-Ansible-Workflow für Wiederverwendbarkeit.

**Aufgabe**: Erstelle ein Terraform-Modul für die VM-Bereitstellung und integriere Ansible für die Konfiguration.

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

       resource "null_resource" "ansible_provision" {
         provisioner "local-exec" {
           command = "ansible-playbook -i ${var.ansible_inventory_path} ${var.ansible_playbook_path}"
           environment = {
             ANSIBLE_HOST_KEY_CHECKING = "False"
           }
         }
         depends_on = [proxmox_vm_qemu.vm]
       }

       output "vm_id" {
         value       = proxmox_vm_qemu.vm.vmid
         description = "ID der erstellten VM"
       }

       output "vm_name" {
         value       = proxmox_vm_qemu.vm.name
         description = "Name der erstellten VM"
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

       variable "ansible_inventory_path" {
         type        = string
         description = "Pfad zur Ansible-Inventory-Datei"
       }

       variable "ansible_playbook_path" {
         type        = string
         description = "Pfad zur Ansible-Playbook-Datei"
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
         null = {
           source  = "hashicorp/null"
           version = "~> 3.2"
         }
       }
     }

     provider "proxmox" {
       pm_api_url          = "https://192.168.30.10:8006/api2/json"
       pm_api_token_id     = "terraform@pve!terraform-token"
       pm_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
       pm_tls_insecure     = true
     }

     module "ansible_vm" {
       source                 = "./modules/proxmox-vm"
       vm_name                = "ansible-vm"
       vmid                   = 101
       iso                    = "local:iso/ubuntu-22.04.5-live-server-amd64.iso"
       cipassword             = "securepassword123"
       ssh_key_path           = "~/.ssh/id_rsa.pub"
       ansible_inventory_path = "${path.module}/ansible/inventory.yml"
       ansible_playbook_path  = "${path.module}/ansible/install_apache.yml"
     }

     output "vm_id" {
       value       = module.ansible_vm.vm_id
       description = "ID der erstellten VM"
     }

     output "vm_name" {
       value       = module.ansible_vm.vm_name
       description = "Name der erstellten VM"
     }
     ```

4. **Terraform und Ansible ausführen**:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
   - Erwartete Ausgabe:
     ```
     Outputs:
     vm_id = 101
     vm_name = "ansible-vm"
     ```
   - Prüfe die Webseite:
     ```bash
     curl http://192.168.30.101
     ```
     - Erwartete Ausgabe:
       ```
       <h1>Willkommen bei Terraform und Ansible!</h1>
       ```

**Erkenntnis**: Die Modularisierung kombiniert Terraform und Ansible in einem wiederverwendbaren Modul. Terraform erstellt die Infrastruktur, und Ansible übernimmt die Konfiguration, was einen klaren, skalierbaren Workflow ermöglicht.

**Quelle**: https://www.terraform.io/docs/language/modules/develop/index.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-ansible-backup-$(date +%F).tar.gz ~/terraform-ansible
     rsync -av ~/terraform-ansible-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-ansible-backup-$DATE.tar.gz ~/terraform-ansible
       rsync -av /home/ubuntu/terraform-ansible-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-ansible-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-ansible-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-ansible
     terraform init
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Dynamisches Inventory für Ansible**:
   - Erstelle ein dynamisches Inventory-Skript, um die VM-IP automatisch zu ermitteln (benötigt Proxmox-API-Abfrage, z. B. via `curl` oder ein Skript).
   - Beispiel (`ansible/dynamic_inventory.sh`):
     ```bash
     #!/bin/bash
     VM_ID=101
     IP=$(curl -s -k -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" https://192.168.30.10:8006/api2/json/nodes/pve/qemu/$VM_ID/status/current | jq -r '.data.ip')
     cat <<EOF > ansible/inventory.yml
     all:
       hosts:
         ansible-vm:
           ansible_host: $IP
           ansible_user: ubuntu
           ansible_ssh_private_key_file: ~/.ssh/id_rsa
     EOF
     ```
   - Ausführbar machen:
     ```bash
     chmod +x ansible/dynamic_inventory.sh
     ```
   - Passe `main.tf` an:
     ```hcl
     resource "null_resource" "ansible_provision" {
       provisioner "local-exec" {
         command = "./ansible/dynamic_inventory.sh && ansible-playbook -i ansible/inventory.yml ansible/install_apache.yml"
         environment = {
           ANSIBLE_HOST_KEY_CHECKING = "False"
         }
       }
       depends_on = [proxmox_vm_qemu.vm]
     }
     ```
2. **Erweitertes Playbook**:
   - Erweitere `install_apache.yml` um weitere Konfigurationen (z. B. PHP):
     ```yaml
     - name: Install PHP
       apt:
         name: php
         state: present
     ```

## Best Practices für Schüler

- **Sicherheit**:
  - Sichere den Proxmox-API-Token:
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
    - Füge eine Firewall-Regel in OPNsense hinzu, um nur `192.168.30.0/24` den Zugriff auf `192.168.30.10:8006` und `192.168.30.101:80` zu erlauben.
- **Fehlerbehebung**:
  - Validiere Terraform-Konfigurationen:
    ```bash
    terraform validate
    terraform fmt
    ```
  - Teste Ansible-Playbooks:
    ```bash
    ansible-playbook -i ansible/inventory.yml ansible/install_apache.yml --check
    ```
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).
- **Modul-Organisation**:
  - Strukturiere Terraform-Module (`main.tf`, `variables.tf`, `outputs.tf`) und Ansible-Dateien (`inventory.yml`, `install_apache.yml`).

**Quelle**: https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Proxmox-Provider, Ubuntu-VM, Ansible-Integration.
  - **Ansible**: Apache-Installation auf der VM.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - Proxmox: VM-Bereitstellung.
  - Ansible: Softwarekonfiguration.
  - HomeLab: Sichere Konfigurationen auf TrueNAS.
- **Beispiel**:
  - VM mit Apache-Webserver, erreichbar über HTTP.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einer einfachen VM und einem Basis-Playbook.
- **Übung**: Experimentiere mit weiteren Ansible-Modulen (z. B. `docker`, `mysql`).
- **Fehlerbehebung**: Nutze `terraform console` und Ansible-Debugging:
  ```bash
  terraform console
  > module.ansible_vm.vm_id
  ansible-playbook -i ansible/inventory.yml ansible/install_apache.yml -v
  ```
- **Lernressourcen**: Nutze https://learn.hashicorp.com/terraform, https://docs.ansible.com, und https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Kombination von Terraform (Infrastruktur) und Ansible (Konfiguration) in einer HomeLab.
- **Einfachheit**: Lokale Umgebung ohne Cloud-Kosten.
- **Lernwert**: Verständnis von Terraform-Ansible-Integration und Modularisierung.

Es ist ideal für Schüler, die IaC und Konfigurationsmanagement in einer HomeLab lernen möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring mit Check_MK/Prometheus, weitere Proxmox-Ressourcen (z. B. LXC-Container), oder eine Integration mit GCP?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Proxmox-Provider: https://registry.terraform.io/providers/telmate/proxmox/latest/docs
- Ansible-Dokumentation: https://docs.ansible.com/ansible/latest/
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,,,,,,,,,,
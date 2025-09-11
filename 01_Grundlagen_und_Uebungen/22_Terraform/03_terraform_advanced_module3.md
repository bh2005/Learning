# Lernprojekt: Fortgeschrittene Terraform-Konzepte (Modul 3: Remote State, Provisioners)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet. Dieses Lernprojekt (Modul 3) baut auf Modul 1 (`01_terraform_basics_module1.md`) und Modul 2 (`02_terraform_advanced_module2.md`) auf und führt fortgeschrittene Konzepte wie **Remote State** und **Provisioners** ein. Remote State ermöglicht die zentrale Speicherung des Terraform-States, während Provisioners zusätzliche Aktionen (z. B. Skriptausführung) nach Ressourcenerstellung erlauben. Das Projekt nutzt die Provider `local` und `null`, um Dateien zu erstellen und Skripte auszuführen, und simuliert ein Remote State Backend lokal. Es ist für Lernende mit Grundkenntnissen in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces) geeignet und kann lokal auf einer Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) ausgeführt werden. Die Übungen integrieren die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups und sind schülerfreundlich.

**Voraussetzungen**:
- Lokale Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) mit Ubuntu 22.04 LTS oder kompatiblem Linux.
- Terraform installiert (Version 1.5.7, wie in Modul 1):
  ```bash
  terraform version  # Erwartet: Terraform v1.5.7
  ```
- Grundkenntnisse in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`, Modules, Workspaces aus Modul 1 und 2) und Linux (z. B. `bash`, `nano`).
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Projektverzeichnis aus Modul 2 (`~/terraform-advanced`) oder ein neues Verzeichnis.
- Kein Cloud-Zugriff erforderlich (lokaler Provider).

**Ziele**:
- Verstehen von Remote State für zentrale State-Verwaltung.
- Nutzen von Provisioners zur Ausführung von Skripten.
- Kombinieren von Remote State, Provisioners, Modulen und Workspaces für komplexe Konfigurationen.

**Hinweis**: Dieses Projekt ist kostenlos, da es lokal ausgeführt wird und keine Cloud-Ressourcen benötigt.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Null Provider: https://registry.terraform.io/providers/hashicorp/null/latest/docs
- Remote State: https://www.terraform.io/docs/language/state/remote.html
- Provisioners: https://www.terraform.io/docs/language/resources/provisioners/syntax.html
- Webquellen:,,,,,,,,,,,,,,

## Modul 3: Fortgeschrittene Terraform-Konzepte

### Vorbereitung: Projekt einrichten
1. **Neues Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-module3
   cd ~/terraform-module3
   ```
2. **Terraform prüfen**:
   ```bash
   terraform version  # Erwartet: Terraform v1.5.7
   ```
   - Falls nicht installiert, siehe Modul 1 (`01_terraform_basics_module1.md`) für Installationsanweisungen.

**Tipp**: Arbeite in einem neuen Verzeichnis, um Konflikte mit Modul 1 und 2 zu vermeiden.

### Übung 1: Remote State mit lokalem Backend

**Ziel**: Verstehen, wie Remote State den Terraform-State zentral speichert und verwaltet.

**Aufgabe**: Konfiguriere ein lokales Remote State Backend, um den State außerhalb des Projektverzeichnisses zu speichern, und erstelle eine Datei mit dem `local`-Provider.

1. **Projektstruktur erstellen**:
   ```bash
   mkdir -p state-backup
   ```
2. **Terraform-Konfiguration erstellen**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         local = {
           source  = "hashicorp/local"
           version = "~> 2.4"
         }
       }
       backend "local" {
         path = "../state-backup/terraform.tfstate"
       }
     }

     resource "local_file" "hello" {
       filename = "${path.module}/output/hello.txt"
       content  = "Hallo, dies ist eine Datei mit Remote State!"
     }

     output "file_path" {
       value       = local_file.hello.filename
       description = "Pfad der erstellten Datei"
     }
     ```
   - **Erklärung**:
     - `backend "local"`: Spezifiziert, dass der State in `../state-backup/terraform.tfstate` gespeichert wird.
     - `local_file.hello`: Erstellt eine Datei `output/hello.txt`.

3. **Terraform ausführen**:
   ```bash
   terraform init -reconfigure
   terraform plan
   terraform apply -auto-approve
   ```
   - Prüfe die Datei:
     ```bash
     cat output/hello.txt
     ```
     - Erwartete Ausgabe: `Hallo, dies ist eine Datei mit Remote State!`
   - Prüfe den State:
     ```bash
     cat ../state-backup/terraform.tfstate
     ```
     - Erwartete Ausgabe: JSON mit Metadaten zu `local_file.hello`.

4. **State-Backup prüfen**:
   ```bash
   ls ../state-backup/
   ```
   - Erwartete Ausgabe: `terraform.tfstate`

5. **State manipulieren**:
   - Lösche die Datei manuell:
     ```bash
     rm output/hello.txt
     ```
   - Führe erneut aus:
     ```bash
     terraform apply -auto-approve
     ```
     - Erwartete Ausgabe: `hello.txt` wird wiederhergestellt, basierend auf dem State in `../state-backup/terraform.tfstate`.

**Erkenntnis**: Remote State speichert den Terraform-State zentral (hier simuliert durch ein lokales Backend), was Teamarbeit und State-Sicherheit erleichtert. Der State bleibt unabhängig vom Projektverzeichnis persistent.

**Quelle**: https://www.terraform.io/docs/language/state/remote.html

### Übung 2: Provisioners für Skriptausführung

**Ziel**: Verstehen, wie Provisioners zusätzliche Aktionen nach Ressourcenerstellung ausführen.

**Aufgabe**: Nutze den `null`-Provider mit einem Provisioner, um ein Skript auszuführen, das eine Zusammenfassungsdatei erstellt.

1. **Skript für Provisioner erstellen**:
   ```bash
   nano summarize.sh
   ```
   - Inhalt:
     ```bash
     #!/bin/bash
     OUTPUT_DIR=$1
     echo "Zusammenfassung der Dateien in $OUTPUT_DIR:" > $OUTPUT_DIR/summary.txt
     ls -l $OUTPUT_DIR >> $OUTPUT_DIR/summary.txt
     ```
   - Ausführbar machen:
     ```bash
     chmod +x summarize.sh
     ```

2. **Terraform-Konfiguration anpassen**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         local = {
           source  = "hashicorp/local"
           version = "~> 2.4"
         }
         null = {
           source  = "hashicorp/null"
           version = "~> 3.2"
         }
       }
       backend "local" {
         path = "../state-backup/terraform.tfstate"
       }
     }

     resource "local_file" "hello" {
       filename = "${path.module}/output/hello.txt"
       content  = "Hallo, dies ist eine Datei mit Remote State!"
     }

     resource "null_resource" "summarize" {
       provisioner "local-exec" {
         command = "./summarize.sh ${path.module}/output"
       }
       depends_on = [local_file.hello]
     }

     output "file_path" {
       value       = local_file.hello.filename
       description = "Pfad der erstellten Datei"
     }
     ```
   - **Erklärung**:
     - `null_resource.summarize`: Führt ein Skript (`summarize.sh`) mit dem `local-exec`-Provisioner aus.
     - `depends_on`: Stellt sicher, dass `hello.txt` zuerst erstellt wird.
     - `command`: Führt das Skript mit dem Output-Verzeichnis als Parameter aus.

3. **Terraform ausführen**:
   ```bash
   terraform init -reconfigure
   terraform apply -auto-approve
   ```
   - Prüfe das Ergebnis:
     ```bash
     cat output/summary.txt
     ```
     - Erwartete Ausgabe:
       ```
       Zusammenfassung der Dateien in /home/ubuntu/terraform-module3/output:
       -rw-rw-r-- 1 ubuntu ubuntu 38 Sep  9 12:55 hello.txt
       ```

**Erkenntnis**: Provisioners (z. B. `local-exec`) ermöglichen die Ausführung von Skripten nach Ressourcenerstellung, sind aber für externe Aktionen gedacht und sollten sparsam genutzt werden, da sie die Deklarativität von Terraform einschränken.

**Quelle**: https://www.terraform.io/docs/language/resources/provisioners/local-exec.html

### Übung 3: Kombination von Remote State, Provisioners, Modulen und Workspaces

**Ziel**: Integriere Remote State, Provisioners, Module und Workspaces für eine komplexe Konfiguration.

**Aufgabe**: Erstelle ein Modul mit Provisioner, nutze Workspaces für Dev/Prod und speichere den State in einem Remote Backend.

1. **Modulstruktur erstellen**:
   ```bash
   mkdir -p modules/file-manager
   mkdir -p modules/file-manager/templates
   ```

2. **Modul-Konfiguration erstellen**:
   - Erstelle `modules/file-manager/main.tf`:
     ```bash
     nano modules/file-manager/main.tf
     ```
     - Inhalt:
       ```hcl
       resource "local_file" "files" {
         for_each = var.files
         filename = "${var.directory}/${each.key}"
         content  = each.value
       }

       resource "null_resource" "summarize" {
         provisioner "local-exec" {
           command = "${path.module}/summarize.sh ${var.directory}"
         }
         depends_on = [local_file.files]
       }
       ```
   - Erstelle `modules/file-manager/variables.tf`:
     ```bash
     nano modules/file-manager/variables.tf
     ```
     - Inhalt:
       ```hcl
       variable "directory" {
         type        = string
         description = "Verzeichnis für Dateien"
       }

       variable "files" {
         type        = map(string)
         description = "Map von Dateinamen und Inhalten"
       }
       ```
   - Kopiere `summarize.sh` ins Modul:
     ```bash
     cp summarize.sh modules/file-manager/
     ```

3. **Haupt-Konfiguration erstellen**:
   ```bash
   nano main.tf
   ```
   - Inhalt:
     ```hcl
     terraform {
       required_providers {
         local = {
           source  = "hashicorp/local"
           version = "~> 2.4"
         }
         null = {
           source  = "hashicorp/null"
           version = "~> 3.2"
         }
       }
       backend "local" {
         path = "../state-backup/terraform.tfstate"
       }
     }

     variable "files" {
       type        = map(string)
       description = "Map von Dateinamen und Inhalten"
     }

     locals {
       env = terraform.workspace
       directories = {
         "dev"  = "output-dev"
         "prod" = "output-prod"
       }
     }

     module "file_manager" {
       source    = "./modules/file-manager"
       directory = local.directories[local.env]
       files     = var.files
     }

     output "file_paths" {
       value       = { for k, v in module.file_manager.files : k => v.filename }
       description = "Pfade der erstellten Dateien"
     }
     ```

4. **Workspaces einrichten**:
   ```bash
   terraform workspace new dev
   terraform workspace new prod
   ```

5. **Variablen für Workspaces definieren**:
   - Für `dev`:
     ```bash
     terraform workspace select dev
     nano terraform.tfvars
     ```
     - Inhalt:
       ```hcl
       files = {
         "file1.txt" = "Entwicklung: Datei 1"
         "file2.txt" = "Entwicklung: Datei 2"
       }
       ```
   - Für `prod`:
     ```bash
     terraform workspace select prod
     nano terraform.tfvars
     ```
     - Inhalt:
       ```hcl
       files = {
         "file1.txt" = "Produktion: Datei 1"
         "file2.txt" = "Produktion: Datei 2"
       }
       ```

6. **Terraform ausführen**:
   - Für `dev`:
     ```bash
     terraform workspace select dev
     terraform apply -auto-approve
     ```
     - Prüfe:
       ```bash
       ls output-dev/
       cat output-dev/summary.txt
       ```
       - Erwartete Ausgabe:
         ```
         output-dev/file1.txt
         output-dev/file2.txt
         output-dev/summary.txt
         ```
         Inhalt von `summary.txt`:
         ```
         Zusammenfassung der Dateien in output-dev:
         -rw-rw-r-- 1 ubuntu ubuntu 20 Sep  9 12:55 file1.txt
         -rw-rw-r-- 1 ubuntu ubuntu 20 Sep  9 12:55 file2.txt
         ```
   - Für `prod`:
     ```bash
     terraform workspace select prod
     terraform apply -auto-approve
     ```
     - Prüfe:
       ```bash
       ls output-prod/
       cat output-prod/summary.txt
       ```
       - Erwartete Ausgabe:
         ```
         output-prod/file1.txt
         output-prod/file2.txt
         output-prod/summary.txt
         ```
         Inhalt von `summary.txt`:
         ```
         Zusammenfassung der Dateien in output-prod:
         -rw-rw-r-- 1 ubuntu ubuntu 21 Sep  9 12:55 file1.txt
         -rw-rw-r-- 1 ubuntu ubuntu 21 Sep  9 12:55 file2.txt
         ```

7. **State prüfen**:
   ```bash
   ls ../state-backup/terraform.tfstate.d/
   ```
   - Erwartete Ausgabe:
     ```
     dev
     prod
     ```
   - Prüfe den State für `dev`:
     ```bash
     cat ../state-backup/terraform.tfstate.d/dev/terraform.tfstate
     ```

**Erkenntnis**: Die Kombination von Remote State, Provisioners, Modulen und Workspaces ermöglicht komplexe, wiederverwendbare und umgebungsbasierte Konfigurationen. Remote State zentralisiert die State-Verwaltung, während Provisioners zusätzliche Flexibilität bieten.

**Quelle**: https://www.terraform.io/docs/language/modules/develop/index.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-module3-backup-$(date +%F).tar.gz ~/terraform-module3
     rsync -av ~/terraform-module3-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-module3-backup-$DATE.tar.gz ~/terraform-module3
       rsync -av /home/ubuntu/terraform-module3-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **State-Backup sichern**:
   ```bash
   tar -czf ~/state-backup-$(date +%F).tar.gz ~/state-backup
   rsync -av ~/state-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/state/
   ```
3. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-module3-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-module3-backup-2025-09-09.tar.gz -C ~/
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/state/state-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/state-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-module3
     terraform init -reconfigure
     terraform workspace select dev
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Remote Backend mit HTTP (optional)**:
   - Simuliere ein HTTP-Backend lokal mit einem einfachen Server:
     ```bash
     sudo apt install python3
     mkdir ~/state-server
     cd ~/state-server
     python3 -m http.server 8080
     ```
   - Passe `main.tf` an:
     ```hcl
     terraform {
       backend "http" {
         address = "http://localhost:8080/terraform.tfstate"
         lock_address = "http://localhost:8080/terraform.tfstate/lock"
         unlock_address = "http://localhost:8080/terraform.tfstate/unlock"
       }
     }
     ```
   - Initialisiere:
     ```bash
     terraform init -reconfigure
     ```
2. **Provisioner mit Fehlerbehandlung**:
   - Erweitere `summarize.sh` um Fehlerprüfung:
     ```bash
     nano modules/file-manager/summarize.sh
     ```
     - Inhalt:
       ```bash
       #!/bin/bash
       OUTPUT_DIR=$1
       if [ ! -d "$OUTPUT_DIR" ]; then
         echo "Fehler: Verzeichnis $OUTPUT_DIR existiert nicht!" >&2
         exit 1
       fi
       echo "Zusammenfassung der Dateien in $OUTPUT_DIR:" > $OUTPUT_DIR/summary.txt
       ls -l $OUTPUT_DIR >> $OUTPUT_DIR/summary.txt
       ```

## Best Practices für Schüler

- **State-Management**:
  - Verwende Remote State für zentrale Verwaltung, auch in lokalen Projekten.
  - Sichere `terraform.tfstate`:
    ```bash
    chmod -R 600 ../state-backup
    ```
- **Provisioner-Nutzung**:
  - Verwende Provisioners sparsam, da sie die Deklarativität einschränken.
  - Bevorzuge `depends_on` für Abhängigkeiten.
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
- **Sicherheit**:
  - Versioniere Konfigurationen in Git (optional für HomeLab):
    ```bash
    git init
    git add .
    git commit -m "Terraform Modul 3 Konfiguration"
    ```
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).

**Quelle**: https://www.terraform.io/docs/language/settings/backends/local.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Remote State mit lokalem Backend, Provisioners mit `null_resource`, Module und Workspaces.
  - **Workloads**: Erstellung von Dateien (`file1.txt`, `file2.txt`, `summary.txt`) in `output-dev` und `output-prod`.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - Lokal: Keine Cloud-Ressourcen erforderlich.
  - HomeLab: Sichere Konfigurationen und State auf TrueNAS.
- **Beispiel**:
  - Modul zur Erstellung von Dateien mit Provisioner, verwaltet in zwei Workspaces (`dev`, `prod`) mit Remote State.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit einem einfachen Remote State Backend und einem Provisioner.
- **Übung**: Experimentiere mit anderen Provisioners (z. B. `file` für Datei-Uploads).
- **Fehlerbehebung**: Nutze `terraform console` für Debugging:
  ```bash
  terraform console
  > module.file_manager.file_paths
  ```
- **Lernressourcen**: Nutze https://learn.hashicorp.com/terraform und https://www.terraform.io/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt (Modul 3: Remote State, Provisioners) bietet:
- **Praxisorientiert**: Remote State und Provisioners für komplexe Konfigurationen.
- **Einfachheit**: Lokaler Provider erfordert keine Cloud-Ressourcen.
- **Lernwert**: Verständnis von Remote State, Provisioners und deren Integration mit Modulen/Workspaces.

Es ist ideal für Schüler, die fortgeschrittene IaC-Konzepte lernen möchten, und bereitet sie auf Cloud-Projekte (z. B. `gcp_terraform_lamp_iac_project.md`) vor.

**Nächste Schritte**: Möchtest du ein Modul 4 mit weiteren Konzepten (z. B. Data Sources, Terraform Cloud), eine Anleitung zu Monitoring mit Check_MK/Prometheus, oder eine Integration mit GCP-Ressourcen?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Null Provider: https://registry.terraform.io/providers/hashicorp/null/latest/docs
- Remote State: https://www.terraform.io/docs/language/state/remote.html
- Provisioners: https://www.terraform.io/docs/language/resources/provisioners/syntax.html
- Webquellen:,,,,,,,,,,,,,,
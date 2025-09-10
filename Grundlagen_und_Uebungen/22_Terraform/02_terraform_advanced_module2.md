# Lernprojekt: Fortgeschrittene Terraform-Konzepte (Modul 2: Modules, Workspaces)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet. Dieses Lernprojekt (Modul 2) baut auf Modul 1 (`01_terraform_basics_module1.md`) auf und führt fortgeschrittene Konzepte wie **Modules** und **Workspaces** ein. Modules ermöglichen die Wiederverwendung von Konfigurationen, während Workspaces mehrere Umgebungen (z. B. Dev, Prod) mit einem State verwalten. Das Projekt nutzt den lokalen Provider (`local`), um Dateien und Verzeichnisse zu erstellen, und ist für Anfänger mit Grundkenntnissen in Terraform (z. B. `resource`, `variable`, `output`, `tfstate`) geeignet. Es kann lokal auf einer Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) ausgeführt werden und integriert optional die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups. Die Übungen demonstrieren die Strukturierung von Modulen, die Verwaltung mehrerer Umgebungen mit Workspaces und die Kombination mit Variablen/Outputs.

**Voraussetzungen**:
- Lokale Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) mit Ubuntu 22.04 LTS oder kompatiblem Linux.
- Terraform installiert (Version 1.5.7, wie in Modul 1):
  ```bash
  terraform version  # Erwartet: Terraform v1.5.7
  ```
- Grundkenntnisse in Terraform (z. B. `resource`, `variable`, `output`, `tfstate` aus Modul 1) und Linux (z. B. `bash`, `nano`).
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Projektverzeichnis aus Modul 1 (`~/terraform-basics`) oder ein neues Verzeichnis.
- Kein Cloud-Zugriff erforderlich (lokaler Provider).

**Ziele**:
- Verstehen von Terraform-Modulen für wiederverwendbare Konfigurationen.
- Nutzen von Workspaces zur Verwaltung mehrerer Umgebungen.
- Kombinieren von Modulen, Variablen und Outputs für komplexere Konfigurationen.

**Hinweis**: Dieses Projekt ist kostenlos, da es lokal ausgeführt wird und keine Cloud-Ressourcen benötigt.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Modules: https://www.terraform.io/docs/language/modules/index.html
- Workspaces: https://www.terraform.io/docs/language/state/workspaces.html
- Webquellen:,,,,,,,,,,,,,,

## Modul 2: Fortgeschrittene Terraform-Konzepte

### Vorbereitung: Projekt einrichten
1. **Neues Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-advanced
   cd ~/terraform-advanced
   ```
2. **Terraform prüfen**:
   ```bash
   terraform version  # Erwartet: Terraform v1.5.7
   ```
   - Falls nicht installiert, siehe Modul 1 (`01_terraform_basics_module1.md`) für Installationsanweisungen.

**Tipp**: Arbeite in einem neuen Verzeichnis, um Konflikte mit Modul 1 zu vermeiden.

### Übung 1: Erstellen eines Terraform-Moduls

**Ziel**: Verstehen, wie Modules Konfigurationen strukturieren und wiederverwendbar machen.

**Aufgabe**: Erstelle ein Terraform-Modul, das mehrere Dateien in einem Verzeichnis anlegt, und nutze es in `main.tf`.

1. **Modulstruktur erstellen**:
   ```bash
   mkdir -p modules/file-creator
   mkdir -p modules/file-creator/templates
   ```
2. **Modul-Konfiguration erstellen**:
   - Erstelle `modules/file-creator/main.tf`:
     ```bash
     nano modules/file-creator/main.tf
     ```
     - Inhalt:
       ```hcl
       resource "local_file" "file" {
         for_each = var.files
         filename = "${var.directory}/${each.key}"
         content  = each.value
       }

       resource "local_file" "config" {
         filename = "${var.directory}/config.txt"
         content  = templatefile("${path.module}/templates/config.tftpl", {
           files_created = var.files
         })
       }
       ```
   - Erstelle `modules/file-creator/variables.tf`:
     ```bash
     nano modules/file-creator/variables.tf
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
   - Erstelle `modules/file-creator/templates/config.tftpl`:
     ```bash
     nano modules/file-creator/templates/config.tftpl
     ```
     - Inhalt:
       ```text
       Konfigurationsdatei
       Erstellt von Terraform am <%= formatdate("YYYY-MM-DD", timestamp()) %>
       Dateien:
       <% for name, content in files_created -%>
       - <%= name %>: <%= content %>
       <% endfor -%>
       ```
   - **Erklärung**:
     - `local_file.file`: Erstellt mehrere Dateien mit `for_each` basierend auf einer Map-Variable (`files`).
     - `local_file.config`: Erstellt eine Konfigurationsdatei mit einer Template-Datei (`config.tftpl`), die die erstellten Dateien auflistet.
     - `variables.tf`: Definiert Eingabevariablen für das Modul (`directory`, `files`).
     - `templatefile`: Rendert eine Vorlage mit dynamischen Werten.

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
       }
     }

     module "file_creator" {
       source = "./modules/file-creator"
       directory = "${path.module}/output"
       files = {
         "file1.txt" = "Inhalt von Datei 1"
         "file2.txt" = "Inhalt von Datei 2"
       }
     }
     ```
   - **Erklärung**:
     - `module`: Ruft das Modul `file-creator` auf und übergibt Werte für `directory` und `files`.

4. **Terraform ausführen**:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
   - Prüfe das Ergebnis:
     ```bash
     ls output/
     cat output/config.txt
     ```
     - Erwartete Ausgabe:
       ```
       output/file1.txt
       output/file2.txt
       output/config.txt
       ```
       Inhalt von `config.txt`:
       ```
       Konfigurationsdatei
       Erstellt von Terraform am 2025-09-09
       Dateien:
       - file1.txt: Inhalt von Datei 1
       - file2.txt: Inhalt von Datei 2
       ```

**Erkenntnis**: Modules strukturieren Konfigurationen und machen sie wiederverwendbar. Sie kapseln Ressourcen und Variablen, ähnlich wie Funktionen in Programmiersprachen, und fördern modulare IaC-Designs.

**Quelle**: https://www.terraform.io/docs/language/modules/syntax.html

### Übung 2: Workspaces für mehrere Umgebungen

**Ziel**: Verstehen, wie Workspaces mehrere Umgebungen (z. B. Dev, Prod) mit getrennten States verwalten.

**Aufgabe**: Erstelle zwei Workspaces (`dev` und `prod`), die das Modul aus Übung 1 mit unterschiedlichen Dateiinhalten verwenden.

1. **Workspaces erstellen**:
   - Standard-Workspace (`default`):
     ```bash
     terraform workspace show  # Erwartet: default
     ```
   - Erstelle und wechsle zu `dev`:
     ```bash
     terraform workspace new dev
     ```
   - Erstelle `prod`:
     ```bash
     terraform workspace new prod
     ```
   - Liste Workspaces:
     ```bash
     terraform workspace list
     ```
     - Erwartete Ausgabe:
       ```
         default
       * dev
         prod
       ```

2. **Variablen für Workspaces definieren**:
   ```bash
   nano terraform.tfvars
   ```
   - Inhalt:
     ```hcl
     directory = "output-dev"
     files = {
       "file1.txt" = "Entwicklung: Datei 1"
       "file2.txt" = "Entwicklung: Datei 2"
     }
     ```
   - **Erklärung**: Definiert spezifische Werte für den `dev`-Workspace.

3. **Terraform im `dev`-Workspace ausführen**:
   ```bash
   terraform workspace select dev
   terraform apply -auto-approve
   ```
   - Prüfe:
     ```bash
     ls output-dev/
     cat output-dev/config.txt
     ```
     - Erwartete Ausgabe:
       ```
       output-dev/file1.txt
       output-dev/file2.txt
       output-dev/config.txt
       ```
       Inhalt von `config.txt`:
       ```
       Konfigurationsdatei
       Erstellt von Terraform am 2025-09-09
       Dateien:
       - file1.txt: Entwicklung: Datei 1
       - file2.txt: Entwicklung: Datei 2
       ```

4. **Wechsle zum `prod`-Workspace**:
   ```bash
   terraform workspace select prod
   nano terraform.tfvars
   ```
   - Inhalt:
     ```hcl
     directory = "output-prod"
     files = {
       "file1.txt" = "Produktion: Datei 1"
       "file2.txt" = "Produktion: Datei 2"
     }
     ```
   - Führe aus:
     ```bash
     terraform apply -auto-approve
     ```
   - Prüfe:
     ```bash
     ls output-prod/
     cat output-prod/config.txt
     ```
     - Erwartete Ausgabe:
       ```
       output-prod/file1.txt
       output-prod/file2.txt
       output-prod/config.txt
       ```
       Inhalt von `config.txt`:
       ```
       Konfigurationsdatei
       Erstellt von Terraform am 2025-09-09
       Dateien:
       - file1.txt: Produktion: Datei 1
       - file2.txt: Produktion: Datei 2
       ```

5. **State-Dateien prüfen**:
   ```bash
   ls terraform.tfstate.d/
   ```
   - Erwartete Ausgabe:
     ```
     dev
     prod
     ```
   - Jeder Workspace hat seinen eigenen State in `terraform.tfstate.d/<workspace>/terraform.tfstate`.

**Erkenntnis**: Workspaces ermöglichen die Verwaltung mehrerer Umgebungen mit einem Satz an Konfigurationen, wobei jeder Workspace einen separaten State (`terraform.tfstate`) hat. Dies ist nützlich für Dev/Prod-Szenarien.

**Quelle**: https://www.terraform.io/docs/language/state/workspaces.html

### Übung 3: Module mit Variablen und Outputs kombinieren

**Ziel**: Module mit dynamischen Variablen und Outputs erweitern, um komplexere Konfigurationen zu erstellen.

**Aufgabe**: Erweitere das Modul aus Übung 1 um Outputs und nutze es mit variablenbasierten Konfigurationen in mehreren Workspaces.

1. **Modul um Outputs erweitern**:
   ```bash
   nano modules/file-creator/outputs.tf
   ```
   - Inhalt:
     ```hcl
     output "file_paths" {
       value       = { for k, v in local_file.file : k => v.filename }
       description = "Pfade der erstellten Dateien"
     }

     output "config_path" {
       value       = local_file.config.filename
       description = "Pfad der Konfigurationsdatei"
     }
     ```
   - **Erklärung**: Gibt die Pfade der erstellten Dateien (`file_paths`) und der Konfigurationsdatei (`config_path`) aus.

2. **Haupt-Konfiguration anpassen**:
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
     }

     variable "directory" {
       type        = string
       description = "Verzeichnis für Dateien"
     }

     variable "files" {
       type        = map(string)
       description = "Map von Dateinamen und Inhalten"
     }

     module "file_creator" {
       source    = "./modules/file-creator"
       directory = var.directory
       files     = var.files
     }

     output "created_files" {
       value       = module.file_creator.file_paths
       description = "Pfade der erstellten Dateien"
     }

     output "config_file" {
       value       = module.file_creator.config_path
       description = "Pfad der Konfigurationsdatei"
     }
     ```
   - **Erklärung**: Übergibt Variablen an das Modul und gibt dessen Outputs weiter.

3. **Terraform im `dev`-Workspace ausführen**:
   ```bash
   terraform workspace select dev
   nano terraform.tfvars
   ```
   - Inhalt:
     ```hcl
     directory = "output-dev"
     files = {
       "file1.txt" = "Entwicklung: Datei 1"
       "file2.txt" = "Entwicklung: Datei 2"
     }
     ```
   - Führe aus:
     ```bash
     terraform apply -auto-approve
     ```
   - Erwartete Ausgabe:
     ```
     Outputs:
     config_file = "output-dev/config.txt"
     created_files = {
       "file1.txt" = "output-dev/file1.txt"
       "file2.txt" = "output-dev/file2.txt"
     }
     ```

4. **Terraform im `prod`-Workspace ausführen**:
   ```bash
   terraform workspace select prod
   nano terraform.tfvars
   ```
   - Inhalt:
     ```hcl
     directory = "output-prod"
     files = {
       "file1.txt" = "Produktion: Datei 1"
       "file2.txt" = "Produktion: Datei 2"
     }
     ```
   - Führe aus:
     ```bash
     terraform apply -auto-approve
     ```
   - Erwartete Ausgabe:
     ```
     Outputs:
     config_file = "output-prod/config.txt"
     created_files = {
       "file1.txt" = "output-prod/file1.txt"
       "file2.txt" = "output-prod/file2.txt"
     }
     ```

**Erkenntnis**: Die Kombination von Modulen, Variablen und Outputs ermöglicht komplexe, wiederverwendbare Konfigurationen. Outputs aus Modulen können in der Hauptkonfiguration verwendet werden, um Ergebnisse zugänglich zu machen.

**Quelle**: https://www.terraform.io/docs/language/values/outputs.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-advanced-backup-$(date +%F).tar.gz ~/terraform-advanced
     rsync -av ~/terraform-advanced-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-advanced-backup-$DATE.tar.gz ~/terraform-advanced
       rsync -av /home/ubuntu/terraform-advanced-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-advanced-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-advanced-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-advanced
     terraform init
     terraform workspace select dev
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Modul mit dynamischen Pfaden**:
   - Passe das Modul an, um Verzeichnisse dynamisch zu erstellen:
     ```bash
     nano modules/file-creator/main.tf
     ```
     - Füge hinzu:
       ```hcl
       resource "local_file" "directory" {
         filename = "${var.directory}/.keep"
         content  = ""
       }
       ```
   - **Erklärung**: Erstellt das Verzeichnis `directory` implizit durch eine `.keep`-Datei.
2. **Workspace-spezifische Variablen**:
   - Nutze `locals` für umgebungsspezifische Konfigurationen:
     ```bash
     nano main.tf
     ```
     - Füge hinzu:
       ```hcl
       locals {
         env = terraform.workspace
         directories = {
           "dev"  = "output-dev"
           "prod" = "output-prod"
         }
       }

       module "file_creator" {
         source    = "./modules/file-creator"
         directory = local.directories[local.env]
         files     = var.files
       }
       ```
   - **Erklärung**: Wählt das Verzeichnis basierend auf dem aktuellen Workspace.

## Best Practices für Schüler

- **Modul-Organisation**:
  - Strukturiere Module in `modules/<name>` mit `main.tf`, `variables.tf`, `outputs.tf`.
  - Verwende klare Variablen- und Output-Beschreibungen.
- **Workspace-Management**:
  - Benenne Workspaces klar (z. B. `dev`, `prod`).
  - Prüfe States pro Workspace:
    ```bash
    cat terraform.tfstate.d/dev/terraform.tfstate
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
- **Sicherheit**:
  - Sichere `terraform.tfstate.d`, da sie sensible Daten enthalten kann:
    ```bash
    chmod -R 600 terraform.tfstate.d
    ```
  - Versioniere Konfigurationen in Git (optional für HomeLab):
    ```bash
    git init
    git add .
    git commit -m "Fortgeschrittene Terraform-Konfiguration"
    ```
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).

**Quelle**: https://www.terraform.io/docs/language/modules/develop/index.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Module für Dateierstellung, Workspaces für Dev/Prod.
  - **Workloads**: Erstellung von Dateien in `output-dev` und `output-prod`.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - Lokal: Keine Cloud-Ressourcen erforderlich.
  - HomeLab: Sichere Konfigurationen auf TrueNAS.
- **Beispiel**:
  - Modul zur Erstellung von Dateien (`file1.txt`, `file2.txt`, `config.txt`) in zwei Workspaces (`dev`, `prod`).

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit kleinen Modulen und einem Workspace.
- **Übung**: Experimentiere mit komplexeren Modulen (z. B. mehrere Ressourcen).
- **Fehlerbehebung**: Nutze `terraform console` für Debugging:
  ```bash
  terraform console
  > module.file_creator.file_paths
  ```
- **Lernressourcen**: Nutze https://learn.hashicorp.com/terraform und https://www.terraform.io/docs.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt (Modul 2: Fortgeschrittene Terraform-Konzepte) bietet:
- **Praxisorientiert**: Module und Workspaces für wiederverwendbare und umgebungsbasierte Konfigurationen.
- **Einfachheit**: Lokaler Provider erfordert keine Cloud-Ressourcen.
- **Lernwert**: Verständnis von Modulen, Workspaces und deren Integration mit Variablen/Outputs.

Es ist ideal für Schüler, die fortgeschrittene IaC-Konzepte lernen möchten, und bereitet sie auf komplexe Cloud-Projekte (z. B. `gcp_terraform_lamp_iac_project.md`) vor.

**Nächste Schritte**: Möchtest du ein Modul 3 mit weiteren Konzepten (z. B. Remote State, Provisioners), eine Anleitung zu Monitoring mit Check_MK/Prometheus, oder eine Integration mit GCP-Ressourcen?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Modules: https://www.terraform.io/docs/language/modules/index.html
- Workspaces: https://www.terraform.io/docs/language/state/workspaces.html
- Webquellen:,,,,,,,,,,,,,,

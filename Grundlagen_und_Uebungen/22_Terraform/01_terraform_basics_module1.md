# Lernprojekt: Terraform-Grundlagen (Modul 1: Terraform-Kernkonzepte)

## Einführung

**Terraform** ist ein Open-Source-Tool für **Infrastructure as Code (IaC)**, das deklarative Konfigurationen in HashiCorp Configuration Language (HCL) verwendet, um Infrastruktur zu definieren und bereitzustellen. Dieses Lernprojekt führt Schüler in die Kernkonzepte von Terraform ein, ohne Verbindung zu einem Cloud-Anbieter, indem es den lokalen Provider (`local`) nutzt. Es umfasst drei Übungen, die grundlegende Terraform-Syntax (`resource`, `variable`, `output`), den Terraform-State (`tfstate`) und die Wiederherstellung des gewünschten Zustands demonstrieren. Das Projekt ist für Anfänger geeignet, die mit Linux und YAML vertraut sind (z. B. aus vorherigen Anleitungen wie `gcp_ansible_lamp_iac_project.md`), und kann lokal auf einem Rechner (z. B. Proxmox-VM, TrueNAS, oder PC) ausgeführt werden. Es integriert optional die HomeLab-Infrastruktur (Proxmox VE, TrueNAS, OPNsense) für Backups.

**Voraussetzungen**:
- Lokale Maschine (z. B. Proxmox-VM, TrueNAS-VM, oder PC) mit Ubuntu 22.04 LTS oder kompatiblem Linux.
- Grundkenntnisse in Linux (z. B. `bash`, Dateibearbeitung mit `nano`) und YAML/HCL.
- Optional: HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense für Netzwerkverständnis.
- Terraform installiert (siehe Schritt 1).
- Kein Cloud-Zugriff erforderlich (lokaler Provider).

**Ziele**:
- Verstehen von Terraform-Kernkonzepten: `resource`, `variable`, `output`, `tfstate`.
- Erstellen und Verwalten einer lokalen Datei mit Terraform.
- Erkunden des Terraform-State-Mechanismus und seiner Rolle bei der Zustandsverwaltung.
- Nutzen von Variablen und Outputs für parametrisierbare Konfigurationen.

**Hinweis**: Dieses Projekt ist kostenlos, da es lokal ausgeführt wird und keine Cloud-Ressourcen benötigt.

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Webquellen:,,,,,,,,,,,,,,

## Modul 1: Terraform-Kernkonzepte

### Vorbereitung: Terraform installieren
1. **Terraform auf der lokalen Maschine installieren**:
   ```bash
   wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
   unzip terraform_1.5.7_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   terraform version  # Erwartet: Terraform v1.5.7
   ```
2. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/terraform-basics
   cd ~/terraform-basics
   ```

**Tipp**: Dieses Projekt läuft lokal und benötigt keine GCP-Anmeldung oder Servicekonten.

**Quelle**: https://www.terraform.io/docs/cli/install/apt.html

### Übung 1: Das erste `main.tf`

**Ziel**: Die grundlegende Terraform-Syntax (`resource`, `provider`) kennenlernen und die Befehle `terraform init`, `plan`, und `apply` verstehen.

**Aufgabe**: Erstelle eine `main.tf`-Datei, die eine lokale Datei (`hello.txt`) mit festem Inhalt erstellt.

1. **Erstelle `main.tf`**:
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

     resource "local_file" "hello" {
       filename = "${path.module}/hello.txt"
       content  = "Hallo, dies ist eine von Terraform erstellte Datei!"
     }
     ```
   - **Erklärung**:
     - `terraform {}` definiert Provider-Anforderungen.
     - `local_file` ist eine Ressource des `local`-Providers, die eine Datei auf dem Dateisystem erstellt.
     - `filename`: Pfad zur Datei (`${path.module}` verweist auf das aktuelle Verzeichnis).
     - `content`: Inhalt der Datei.

2. **Terraform initialisieren**:
   ```bash
   terraform init
   ```
   - **Erklärung**: Initialisiert das Projekt, lädt den `local`-Provider herunter und erstellt das Verzeichnis `.terraform`.

3. **Plan prüfen**:
   ```bash
   terraform plan
   ```
   - **Erklärung**: Zeigt eine Vorschau der Änderungen (z. B. Erstellung von `hello.txt`).

4. **Infrastruktur anwenden**:
   ```bash
   terraform apply -auto-approve
   ```
   - **Erklärung**: Erstellt die Datei `hello.txt` im Verzeichnis `~/terraform-basics`.
   - Prüfe die Datei:
     ```bash
     cat hello.txt
     ```
     - Erwartete Ausgabe: `Hallo, dies ist eine von Terraform erstellte Datei!`

**Erkenntnis**: Terraform bildet den **gewünschten Zustand** (desired state) in `main.tf` ab und setzt ihn mit `apply` um. Die `local_file`-Ressource erstellt Dateien deklarativ, und die Befehle `init`, `plan`, und `apply` sind zentral für den Terraform-Workflow.

**Quelle**: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file

### Übung 2: Der Terraform-State

**Ziel**: Die Bedeutung der `.tfstate`-Datei verstehen und die Zustandswiederherstellung testen.

**Aufgabe**: Untersuche die `terraform.tfstate`-Datei und beobachte, wie Terraform den Zustand nach manuellem Löschen der Datei wiederherstellt.

1. **Terraform-State prüfen**:
   - Nach `terraform apply` wurde `terraform.tfstate` erstellt.
   - Öffne die Datei:
     ```bash
     cat terraform.tfstate
     ```
   - **Erklärung**: Die Datei enthält JSON-Daten mit Metadaten über die erstellte Ressource (`local_file.hello`), z. B. Dateiname und Inhalt.
   - Beispielauszug:
     ```json
     {
       "resources": [
         {
           "mode": "managed",
           "type": "local_file",
           "name": "hello",
           "instances": [
             {
               "attributes": {
                 "filename": "./hello.txt",
                 "content": "Hallo, dies ist eine von Terraform erstellte Datei!"
               }
             }
           ]
         }
       ]
     }
     ```

2. **Datei manuell löschen**:
   ```bash
   rm hello.txt
   ls  # Erwartet: hello.txt fehlt
   ```

3. **Terraform-State wiederherstellen**:
   ```bash
   terraform apply -auto-approve
   ```
   - **Erklärung**: Terraform vergleicht den aktuellen Zustand (keine `hello.txt`) mit dem gewünschten Zustand in `main.tf` und stellt `hello.txt` wieder her.
   - Prüfe:
     ```bash
     cat hello.txt
     ```
     - Erwartete Ausgabe: `Hallo, dies ist eine von Terraform erstellte Datei!`

4. **State-Backup prüfen**:
   - Nach `apply` wird auch `terraform.tfstate.backup` erstellt (Vorheriger Zustand).
   ```bash
   ls  # Erwartet: terraform.tfstate, terraform.tfstate.backup
   ```

**Erkenntnis**: Terraform ist **stateful**, nicht rein idempotent. Die `terraform.tfstate`-Datei speichert den aktuellen Zustand der Infrastruktur, und Terraform nutzt sie, um Änderungen zu erkennen und den gewünschten Zustand wiederherzustellen.

**Quelle**: https://www.terraform.io/docs/language/state/index.html

### Übung 3: Variablen und Outputs

**Ziel**: Konfigurationen parametrisierbar und wiederverwendbar machen mit Variablen und Outputs.

**Aufgabe**: Erstelle `variables.tf` und `outputs.tf`, um den Dateinamen aus Übung 1 parametrisierbar zu machen und den Dateipfad als Output auszugeben.

1. **Variablen definieren**:
   ```bash
   nano variables.tf
   ```
   - Inhalt:
     ```hcl
     variable "filename" {
       type        = string
       description = "Name der zu erstellenden Datei"
       default     = "hello.txt"
     }

     variable "content" {
       type        = string
       description = "Inhalt der Datei"
       default     = "Hallo, dies ist eine von Terraform erstellte Datei!"
     }
     ```
   - **Erklärung**:
     - `variable`: Definiert Eingabevariablen mit Typ, Beschreibung und Standardwert.
     - `filename` und `content` sind parametrisierbar.

2. **Main-Datei anpassen**:
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

     resource "local_file" "hello" {
       filename = var.filename
       content  = var.content
     }
     ```
   - **Erklärung**: Nutzt `var.filename` und `var.content` statt fest codierter Werte.

3. **Outputs definieren**:
   ```bash
   nano outputs.tf
   ```
   - Inhalt:
     ```hcl
     output "file_path" {
       value       = local_file.hello.filename
       description = "Pfad der erstellten Datei"
     }
     ```
   - **Erklärung**: `output` gibt den Dateipfad (`filename`) der Ressource `local_file.hello` aus.

4. **Terraform anwenden**:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
   - **Erklärung**: Erstellt `hello.txt` mit Standardwerten aus `variables.tf`.
   - Erwartete Ausgabe (Output):
     ```bash
     Outputs:
     file_path = "./hello.txt"
     ```

5. **Variablen überschreiben**:
   - Erstelle eine `terraform.tfvars`-Datei:
     ```bash
     nano terraform.tfvars
     ```
     - Inhalt:
       ```hcl
       filename = "greeting.txt"
       content  = "Willkommen bei Terraform!"
       ```
   - Führe erneut aus:
     ```bash
     terraform apply -auto-approve
     ```
   - Prüfe:
     ```bash
     cat greeting.txt
     ```
     - Erwartete Ausgabe: `Willkommen bei Terraform!`
   - Output:
     ```bash
     Outputs:
     file_path = "./greeting.txt"
     ```

**Erkenntnis**: Variablen (`variables.tf`, `terraform.tfvars`) machen Konfigurationen flexibel und wiederverwendbar. Outputs (`outputs.tf`) liefern Informationen über die erstellten Ressourcen und sind nützlich für Debugging oder Integration.

**Quelle**: https://www.terraform.io/docs/language/values/variables.html

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/terraform-basics-backup-$(date +%F).tar.gz ~/terraform-basics
     rsync -av ~/terraform-basics-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
     ```
   - Automatisiere (z. B. in einem Backup-Skript):
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/terraform-basics-backup-$DATE.tar.gz ~/terraform-basics
       rsync -av /home/ubuntu/terraform-basics-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/terraform/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/terraform/terraform-basics-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/terraform-basics-backup-2025-09-09.tar.gz -C ~/
     ```
   - Führe Terraform erneut aus:
     ```bash
     cd ~/terraform-basics
     terraform init
     terraform apply -auto-approve
     ```

### Schritt 5: Erweiterung der Übungen
1. **Mehrere Dateien erstellen**:
   - Passe `main.tf` an:
     ```hcl
     resource "local_file" "additional" {
       filename = "${var.filename}_backup"
       content  = var.content
     }
     ```
   - Führe `terraform apply` aus und prüfe die zusätzliche Datei.
2. **State-Backend konfigurieren**:
   - Erstelle `backend.tf` für einen lokalen State:
     ```hcl
     terraform {
       backend "local" {
         path = "terraform.tfstate"
       }
     }
     ```
   - Initialisiere:
     ```bash
     terraform init -reconfigure
     ```
   - **Erklärung**: Explizite Backend-Konfiguration verbessert die State-Verwaltung.

## Best Practices für Schüler

- **Konfigurationsmanagement**:
  - Organisiere Dateien: `main.tf` (Ressourcen), `variables.tf` (Variablen), `outputs.tf` (Outputs).
  - Verwende `terraform.tfvars` für benutzerdefinierte Werte.
- **Fehlerbehebung**:
  - Validiere Konfigurationen:
    ```bash
    terraform validate
    ```
  - Prüfe detaillierte Pläne:
    ```bash
    terraform plan -out=tfplan
    terraform show tfplan
    ```
- **Sicherheit**:
  - Sichere `terraform.tfstate`, da sie sensible Daten enthalten kann:
    ```bash
    chmod 600 terraform.tfstate
    ```
  - Versioniere Konfigurationen in Git (optional für HomeLab):
    ```bash
    git init
    git add .
    git commit -m "Initial Terraform-Konfiguration"
    ```
- **Lernziele**:
  - Verstehe den Terraform-Workflow: `init`, `plan`, `apply`.
  - Erkenne die Rolle von `tfstate` für Zustandsmanagement.
  - Nutze Variablen und Outputs für Flexibilität.
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).

**Quelle**: https://www.terraform.io/docs/language/settings/backends/local.html

## Empfehlungen für Schüler

- **Setup**:
  - **Terraform**: Lokale Konfigurationen mit `local_file`-Ressource.
  - **Workloads**: Erstellung und Verwaltung von Dateien (`hello.txt`, `greeting.txt`).
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/terraform`).
- **Integration**:
  - Lokal: Keine Cloud-Ressourcen erforderlich.
  - HomeLab: Sichere Konfigurationen auf TrueNAS.
- **Beispiel**:
  - Erstellung von `hello.txt` mit Terraform, State-Verwaltung, und parametrisierte Konfiguration mit Variablen/Outputs.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit kleinen Konfigurationen, wie einer einzelnen `local_file`.
- **Übung**: Experimentiere mit anderen lokalen Ressourcen (z. B. `local_file` für mehrere Dateien).
- **Fehlerbehebung**: Nutze `terraform validate` und `terraform fmt` für sauberen Code:
  ```bash
  terraform fmt
  ```
- **Lernressourcen**: Nutze https://www.terraform.io/docs und Learn Terraform (https://learn.hashicorp.com/terraform).
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt (Modul 1: Terraform-Kernkonzepte) bietet:
- **Praxisorientiert**: Einfache Übungen zur Erstellung lokaler Dateien mit Terraform.
- **Einfachheit**: Lokaler Provider erfordert keine Cloud-Ressourcen.
- **Lernwert**: Verständnis von `resource`, `tfstate`, `variable`, `output` und dem Terraform-Workflow.

Es ist ideal für Schüler, die IaC-Grundlagen lernen möchten, und bereitet sie auf komplexere Cloud-Projekte (z. B. `gcp_terraform_lamp_iac_project.md`) vor.

**Nächste Schritte**: Möchtest du ein Modul 2 mit fortgeschrittenen Terraform-Konzepten (z. B. Modules, Workspaces), eine Anleitung zu Monitoring mit Check_MK/Prometheus, oder eine Integration mit GCP-Ressourcen?

**Quellen**:
- Terraform-Dokumentation: https://www.terraform.io/docs
- Local Provider: https://registry.terraform.io/providers/hashicorp/local/latest/docs
- Webquellen:,,,,,,,,,,,,,,

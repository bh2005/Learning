# Praxisorientierte Anleitung: Multi-Cloud-Governance und hybride On-Prem-Audit-Workflows

## Einführung
Multi-Cloud-Governance und hybride On-Prem-Audit-Workflows sind entscheidend, um Sicherheit, Compliance und Konsistenz in Umgebungen mit GCP, AWS, Azure und On-Premises-Systemen (z. B. HomeLab mit Debian und LXC) zu gewährleisten. Diese Anleitung zeigt, wie man Governance-Richtlinien automatisiert und Audit-Workflows für IAM, Logging und Compliance implementiert. Ziel ist es, dir praktische Schritte für eine einheitliche Governance in Multi-Cloud- und hybriden Setups zu vermitteln.

Voraussetzungen:
- Zugang zu einem GCP-Projekt, AWS-Account, Azure-Abonnement und einem On-Prem-Debian-System (z. B. HomeLab mit LXC).
- Installierte Tools: `gcloud`, `aws`, `az`, `terraform` (für Cloud), `bash` und `rsyslog` (für On-Prem).
- Grundkenntnisse in Terraform (HCL), YAML (für CI/CD) und Linux-Logging.
- Ein GitHub-Repository für CI/CD-Pipelines (z. B. GitHub Actions).
- Testumgebung für sichere Tests (keine Produktionsumgebung).

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für Multi-Cloud- und hybride Governance:

1. **Multi-Cloud-Governance**:
   - Einheitliche IAM-Policies mit Least Privilege über GCP, AWS, Azure.
   - Automatisierte Richtlinien mit Terraform und CI/CD.
   - Zentralisierte Logging- und Monitoring-Tools (z. B. Stackdriver, CloudWatch, Azure Monitor).
2. **Hybride On-Prem-Integration**:
   - Synchronisation von On-Prem-Logs (z. B. via `rsyslog`) mit Cloud-Audit-Logs.
   - IAM für hybride Workloads (z. B. LXC-Container mit Cloud-Interaktion).
3. **Audit-Workflows**:
   - Regelmäßige Überprüfung von IAM-Rollen und Zugriffen.
   - Tools wie AWS Access Analyzer, GCP IAM Recommender, Azure PIM, `auditd` (On-Prem).

## Übungen zum Verinnerlichen

### Übung 1: Multi-Cloud-IAM mit Terraform
**Ziel**: Erstelle einheitliche IAM-Policies für GCP, AWS und Azure mit Terraform.

1. **Schritt 1**: Erstelle eine Terraform-Konfiguration (`multi_cloud_iam.tf`) in deinem GitHub-Repository:
   ```hcl
   # GCP Provider
   provider "google" {
     project = "your-project-id"
     credentials = file("gcp-sa-key.json")
   }

   resource "google_project_iam_custom_role" "minimal_viewer" {
     role_id     = "minimalViewer"
     title       = "Minimal Viewer"
     description = "Least privilege for viewing resources"
     permissions = ["storage.objects.get", "compute.instances.list"]
   }

   resource "google_project_iam_binding" "gcp_binding" {
     project = "your-project-id"
     role    = "projects/your-project-id/roles/minimalViewer"
     members = ["serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com"]
   }

   # AWS Provider
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_iam_policy" "minimal_read" {
     name        = "MinimalRead"
     description = "Least privilege for reading S3 and EC2"
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect   = "Allow"
         Action   = ["s3:GetObject", "ec2:DescribeInstances"]
         Resource = ["arn:aws:s3:::your-bucket/*", "*"]
         Condition = { Bool = { "aws:SecureTransport" = "true" } }
       }]
     })
   }

   resource "aws_iam_role" "aws_role" {
     name = "minimal-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
     })
   }

   resource "aws_iam_role_policy_attachment" "aws_attach" {
     role       = aws_iam_role.aws_role.name
     policy_arn = aws_iam_policy.minimal_read.arn
   }

   # Azure Provider
   provider "azurerm" {
     features {}
   }

   resource "azurerm_role_definition" "minimal_reader" {
     name        = "MinimalReader"
     scope       = "/subscriptions/your-sub-id"
     description = "Least privilege for reading storage and VMs"
     permissions {
       actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read", "Microsoft.Compute/virtualMachines/read"]
     }
     assignable_scopes = ["/subscriptions/your-sub-id"]
   }

   resource "azurerm_role_assignment" "azure_assignment" {
     scope              = "/subscriptions/your-sub-id/resourceGroups/your-rg"
     role_definition_id = azurerm_role_definition.minimal_reader.role_id
     principal_id       = "your-user-or-sp-id"
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/multi-cloud-iam.yml`):
   ```yaml
   name: Deploy Multi-Cloud IAM
   on:
     push:
       branches: [ main ]
   jobs:
     deploy-iam:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: hashicorp/setup-terraform@v3
         with:
           terraform_version: 1.9.0
       - uses: google-github-actions/auth@v2
         with:
           credentials_json: ${{ secrets.GCP_SA_KEY }}
       - uses: aws-actions/configure-aws-credentials@v4
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-east-1
       - uses: azure/login@v1
         with:
           creds: ${{ secrets.AZURE_CREDENTIALS }}
       - run: |
           terraform init
           terraform plan -out=tfplan
           terraform apply tfplan
         working-directory: .
   ```
3. **Schritt 3**: Füge Credentials als GitHub Secrets hinzu: `GCP_SA_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AZURE_CREDENTIALS`.
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   export GOOGLE_APPLICATION_CREDENTIALS=gcp-sa-key.json
   export AWS_ACCESS_KEY_ID=your-key
   export AWS_SECRET_ACCESS_KEY=your-secret
   az login --service-principal -u your-client-id -p your-client-secret --tenant your-tenant-id
   terraform init && terraform apply -auto-approve
   gsutil ls gs://your-bucket/
   aws s3 cp s3://your-bucket/file.txt .
   az storage blob list --account-name your-account
   ```

**Reflexion**: Wie vereinfacht Terraform die Multi-Cloud-Governance? Was sind die Herausforderungen bei der Verwaltung mehrerer Provider?

### Übung 2: Hybride On-Prem-Audit-Workflows
**Ziel**: Integriere On-Prem-Logs (z. B. LXC-Container) mit Cloud-Audit-Logs.

1. **Schritt 1**: Konfiguriere `rsyslog` auf deinem Debian-HomeLab für zentralisierte Logs:
   ```bash
   # Installiere rsyslog
   apt update && apt install -y rsyslog
   # Konfiguriere rsyslog für Cloud-Integration
   cat << 'EOF' >> /etc/rsyslog.conf
   *.* @your-log-server:514
   EOF
   systemctl restart rsyslog
   ```
2. **Schritt 2**: Sende LXC-Container-Logs (z. B. von `game-container`) an einen Cloud-Log-Dienst (z. B. GCP Logging):
   ```bash
   # Erstelle LXC-Container (falls nicht vorhanden)
   lxc-create -t download -n game-container -- -d debian -r bookworm -a amd64
   lxc-start -n game-container
   # Konfiguriere Container-Logs für rsyslog
   lxc-attach -n game-container -- bash -c "apt update && apt install -y rsyslog"
   lxc-attach -n game-container -- bash -c "echo '*.* @your-log-server:514' >> /etc/rsyslog.conf"
   lxc-attach -n game-container -- systemctl restart rsyslog
   ```
3. **Schritt 3**: Erstelle eine Terraform-Konfiguration für GCP Logging (`gcp_logging.tf`):
   ```hcl
   resource "google_logging_project_sink" "log_sink" {
     project = "your-project-id"
     name    = "on-prem-sink"
     destination = "pubsub.googleapis.com/projects/your-project-id/topics/on-prem-logs"
     filter  = "resource.type=global"
   }

   resource "google_pubsub_topic" "on_prem_logs" {
     project = "your-project-id"
     name    = "on-prem-logs"
   }
   ```
4. **Schritt 4**: Pushe die Terraform-Konfiguration in die Pipeline (siehe Übung 1) und teste:
   ```bash
   # Prüfe Logs in GCP
   gcloud logging read "resource.type=global" --project=your-project-id
   ```

**Reflexion**: Wie verbessert die Integration von On-Prem- und Cloud-Logs die Nachvollziehbarkeit? Welche Herausforderungen gibt es bei hybriden Audits?

### Übung 3: Automatisierte Audit-Workflows
**Ziel**: Implementiere einen Audit-Workflow für IAM und Logs in Multi-Cloud.

1. **Schritt 1**: Erstelle ein Skript für IAM-Audit (`audit_iam.sh`):
   ```bash
   #!/bin/bash
   echo "GCP IAM Audit"
   gcloud iam roles list --project=your-project-id
   echo "AWS IAM Audit"
   aws iam list-policies --query 'Policies[*].{Name:PolicyName,ARN:Arn}'
   echo "Azure IAM Audit"
   az role definition list --output table
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/audit.yml`):
   ```yaml
   name: Multi-Cloud IAM Audit
   on:
     schedule:
       - cron: '0 0 * * *' # Täglich um Mitternacht
   jobs:
     audit-iam:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: google-github-actions/auth@v2
         with:
           credentials_json: ${{ secrets.GCP_SA_KEY }}
       - uses: aws-actions/configure-aws-credentials@v4
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-east-1
       - uses: azure/login@v1
         with:
           creds: ${{ secrets.AZURE_CREDENTIALS }}
       - run: |
           chmod +x audit_iam.sh
           ./audit_iam.sh > audit_report.txt
           git add audit_report.txt
           git commit -m "Update IAM audit report"
           git push
   ```
3. **Schritt 3**: Füge Credentials als GitHub Secrets hinzu (siehe Übung 1).
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und prüfe `audit_report.txt` im Repository.

**Reflexion**: Wie hilft ein automatisierter Audit-Workflow bei der Compliance? Welche zusätzlichen Tools könnten die Analyse verbessern?

## Tipps für den Erfolg
- **Least Privilege**: Nutze Terraform für granulare IAM-Definitionen, valide mit Tools wie AWS Access Analyzer.
- **Sicherheit**: Speichere Credentials in GitHub Secrets, aktiviere MFA, teste in Sandboxes.
- **Fehlerbehebung**: Prüfe Terraform-Logs (`terraform plan`), Cloud-Logs und `rsyslog`-Logs (`/var/log/syslog`).
- **Best Practices**: Versioniere alle Konfigurationen in Git, modularisiere Terraform, automatisiere Audits mit Cron.
- **Erweiterungen**: Integriere `checkov` für Sicherheits-Checks:
  ```bash
  pip install checkov
  checkov -f multi_cloud_iam.tf
  ```

## Fazit
Du hast gelernt, Multi-Cloud-Governance und hybride On-Prem-Audit-Workflows mit Terraform und GitHub Actions für GCP, AWS, Azure und dein HomeLab zu implementieren. Diese Übungen fördern Konsistenz, Sicherheit und Compliance. Wiederhole sie in Testumgebungen, um die Automatisierung zu verinnerlichen.

**Nächste Schritte**:
- Erkunde fortgeschrittene Tools wie GCP IAM Recommender, Azure PIM oder `auditd`.
- Integriere weitere On-Prem-Tools (z. B. Ansible für LXC-Management).
- Vertiefe dich in Compliance-Standards (z. B. GDPR, SOC 2).

**Quellen**: Terraform Docs, AWS IAM Docs, Azure RBAC Docs, GCP IAM Docs, Rsyslog Docs.
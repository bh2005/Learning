# Praxisorientierte Anleitung: IAM in CI/CD-Pipelines mit Terraform

## Einführung
Die Integration von Identity and Access Management (IAM) in CI/CD-Pipelines mit Terraform ermöglicht die automatisierte Erstellung, Verwaltung und Validierung von sicheren Rollen und Richtlinien in GCP, AWS und Azure. Terraform definiert IAM als Code, was Konsistenz, Wiederholbarkeit und Least-Privilege-Governance fördert. Diese Anleitung zeigt, wie man Terraform mit GitHub Actions nutzt, um IAM-Ressourcen zu deployen und Governance zu gewährleisten. Ziel ist es, dir praktische Schritte für eine automatisierte, sichere IAM-Verwaltung zu vermitteln.

Voraussetzungen:
- Zugang zu einem GCP-Projekt, AWS-Account oder Azure-Abonnement mit IAM-Administrationsrechten.
- Ein GitHub-Repository für CI/CD-Pipelines.
- Installierte Tools: Terraform (`terraform`), CLI-Tools (`gcloud`, `aws`, `az`).
- Grundkenntnisse in Terraform (HCL), YAML (für GitHub Actions) und JSON (für Policies).
- Testumgebung für sichere Tests (keine Produktionsumgebung).

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für die IAM-Integration mit Terraform:

1. **IAM als Code**:
   - Terraform-Ressourcen (z. B. `aws_iam_policy`, `google_project_iam_custom_role`) definieren Rollen und Policies.
   - Least Privilege durch granulare Rechte in HCL.
2. **CI/CD-Integration**:
   - GitHub Actions für automatisches Planen und Anwenden von Terraform-Konfigurationen.
   - Validierung mit Tools wie AWS Access Analyzer oder GCP IAM Recommender.
3. **Governance und Compliance**:
   - Automatische Audits durch Terraform-Plan-Ausgaben.
   - Logging mit CloudTrail (AWS), Audit Logs (GCP), Activity Logs (Azure).

## Übungen zum Verinnerlichen

### Übung 1: IAM in GCP mit Terraform und GitHub Actions
**Ziel**: Automatisiere eine Custom Role in GCP mit Terraform.

1. **Schritt 1**: Erstelle eine Terraform-Konfiguration (`gcp_iam.tf`) in deinem GitHub-Repository:
   ```hcl
   provider "google" {
     project = "your-project-id"
     credentials = file("sa-key.json")
   }

   resource "google_project_iam_custom_role" "minimal_storage_viewer" {
     role_id     = "minimalStorageViewer"
     title       = "Minimal Storage Viewer"
     description = "Least privilege for viewing storage"
     permissions = ["storage.objects.get"]
   }

   resource "google_project_iam_binding" "binding" {
     project = "your-project-id"
     role    = "projects/your-project-id/roles/minimalStorageViewer"
     members = ["serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com"]
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/gcp-iam.yml`):
   ```yaml
   name: Deploy GCP IAM with Terraform
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
       - run: |
           terraform init
           terraform plan -out=tfplan
           terraform apply tfplan
         working-directory: .
   ```
3. **Schritt 3**: Füge den Service Account-Schlüssel als GitHub Secret (`GCP_SA_KEY`) hinzu (Repository Settings > Secrets and Variables > Actions).
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline in GitHub Actions und teste:
   ```bash
   # Lokal testen
   export GOOGLE_APPLICATION_CREDENTIALS=sa-key.json
   terraform init && terraform apply -auto-approve
   gsutil ls gs://your-bucket/
   ```

**Reflexion**: Wie reduziert Terraform die Komplexität von IAM-Management? Warum ist ein Plan-Schritt in CI/CD wichtig?

### Übung 2: IAM in AWS mit Terraform und GitHub Actions
**Ziel**: Automatisiere eine Least-Privilege-Policy in AWS.

1. **Schritt 1**: Erstelle eine Terraform-Konfiguration (`aws_iam.tf`):
   ```hcl
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_iam_policy" "minimal_s3_get" {
     name        = "MinimalS3Get"
     description = "Least privilege for S3 read"
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Effect   = "Allow"
         Action   = "s3:GetObject"
         Resource = "arn:aws:s3:::your-bucket/*"
         Condition = {
           Bool = { "aws:SecureTransport" = "true" }
         }
       }]
     })
   }

   resource "aws_iam_role" "example_role" {
     name = "example-role"
     assume_role_policy = jsonencode({
       Version = "2012-10-17"
       Statement = [{
         Action = "sts:AssumeRole"
         Effect = "Allow"
         Principal = { Service = "ec2.amazonaws.com" }
       }]
     })
   }

   resource "aws_iam_role_policy_attachment" "attach" {
     role       = aws_iam_role.example_role.name
     policy_arn = aws_iam_policy.minimal_s3_get.arn
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/aws-iam.yml`):
   ```yaml
   name: Deploy AWS IAM with Terraform
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
       - uses: aws-actions/configure-aws-credentials@v4
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-east-1
       - run: |
           terraform init
           terraform plan -out=tfplan
           terraform apply tfplan
         working-directory: .
   ```
3. **Schritt 3**: Füge AWS-Credentials als GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) hinzu.
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   export AWS_ACCESS_KEY_ID=your-key
   export AWS_SECRET_ACCESS_KEY=your-secret
   terraform init && terraform apply -auto-approve
   aws s3 cp s3://your-bucket/file.txt .
   ```

**Reflexion**: Wie verbessert Terraform die Nachvollziehbarkeit gegenüber CLI-Befehlen? Was passiert, wenn die Policy zu breit ist?

### Übung 3: IAM in Azure mit Terraform und GitHub Actions
**Ziel**: Automatisiere eine Custom Role in Azure RBAC.

1. **Schritt 1**: Erstelle eine Terraform-Konfiguration (`azure_iam.tf`):
   ```hcl
   provider "azurerm" {
     features {}
   }

   resource "azurerm_role_definition" "minimal_storage_reader" {
     name        = "MinimalStorageReader"
     scope       = "/subscriptions/your-sub-id"
     description = "Least privilege for reading storage"
     permissions {
       actions = ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
     }
     assignable_scopes = ["/subscriptions/your-sub-id"]
   }

   resource "azurerm_role_assignment" "assignment" {
     scope              = "/subscriptions/your-sub-id/resourceGroups/your-rg"
     role_definition_id = azurerm_role_definition.minimal_storage_reader.role_id
     principal_id       = "your-user-or-sp-id"
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/azure-iam.yml`):
   ```yaml
   name: Deploy Azure IAM with Terraform
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
       - uses: azure/login@v1
         with:
           creds: ${{ secrets.AZURE_CREDENTIALS }}
       - run: |
           terraform init
           terraform plan -out=tfplan
           terraform apply tfplan
         working-directory: .
   ```
3. **Schritt 3**: Füge Azure-Credentials als GitHub Secret (`AZURE_CREDENTIALS`) hinzu (Service Principal mit Client ID, Secret, Tenant ID).
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   az login --service-principal -u your-client-id -p your-client-secret --tenant your-tenant-id
   terraform init && terraform apply -auto-approve
   az storage blob list --account-name your-account
   ```

**Reflexion**: Wie unterstützt Terraform Multi-Cloud-Setups? Warum ist die Scope-Definition in Azure kritisch?

## Tipps für den Erfolg
- **Least Privilege**: Definiere granulare Rechte in Terraform, valide mit Analyzer-Tools.
- **Sicherheit**: Speichere Credentials in GitHub Secrets, aktiviere MFA, nutze Sandboxes.
- **Fehlerbehebung**: Prüfe Terraform-Logs (`terraform plan`) und Cloud-Logs (CloudTrail, Azure Activity Logs).
- **Best Practices**: Versioniere Terraform-Dateien in Git, modularisiere mit Modulen, teste lokal vor CI/CD.
- **Erweiterungen**: Integriere `tflint` oder `checkov` für Policy-Validierung:
  ```bash
  tflint --init
  tflint gcp_iam.tf
  ```

## Fazit
Du hast gelernt, IAM-Rollen und Policies in GCP, AWS und Azure mit Terraform in CI/CD-Pipelines zu automatisieren, um Governance und Least Privilege zu gewährleisten. Wiederhole die Übungen in Testumgebungen, um die Automatisierung zu verinnerlichen.

**Nächste Schritte**:
- Erkunde fortgeschrittene Terraform-Module für IAM.
- Integriere Tools wie `checkov` für Sicherheits-Checks.
- Vertiefe Multi-Cloud-Governance mit Terraform.

**Quellen**: Terraform Docs, AWS IAM Docs, Azure RBAC Docs, GCP IAM Docs, GitHub Actions Docs.
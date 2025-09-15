# Praxisorientierte Anleitung: IAM in CI/CD-Pipelines für automatisierte Governance

## Einführung
Die Integration von Identity and Access Management (IAM) in CI/CD-Pipelines automatisiert die Erstellung, Validierung und Überwachung von sicheren Rollen und Richtlinien, um das Least-Privilege-Prinzip durchzusetzen und Governance in Cloud-Umgebungen (GCP, AWS, Azure) zu stärken. Diese Anleitung zeigt, wie man IAM mit Tools wie GitHub Actions automatisiert, um Konsistenz, Sicherheit und Compliance zu gewährleisten. Ziel ist es, dir praktische Schritte für eine automatisierte Governance-Pipeline zu vermitteln.

Voraussetzungen:
- Zugang zu einem GCP-Projekt, AWS-Account oder Azure-Abonnement mit IAM-Administrationsrechten.
- Ein GitHub-Repository für CI/CD-Pipelines.
- Installierte CLI-Tools: `gcloud` (GCP), `aws` (AWS), `az` (Azure).
- Grundkenntnisse in YAML (für GitHub Actions) und JSON (für IAM-Policies).
- Testumgebung (keine Produktionsumgebung) für sichere Tests.

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für die IAM-Integration in CI/CD:

1. **Automatisierte IAM-Verwaltung**:
   - Definieren von Rollen/Policies als Code (z. B. JSON, Terraform).
   - Validierung mit Tools wie AWS Access Analyzer oder GCP IAM Recommender.
2. **CI/CD-Pipeline-Integration**:
   - **GitHub Actions**: Workflows für IAM-Deployment und -Validierung.
   - **Least Privilege**: Policies automatisch auf minimale Rechte prüfen.
3. **Governance und Compliance**:
   - Automatische Audits (z. B. Überprüfung ungenutzter Rollen).
   - Logging und Monitoring (z. B. CloudTrail, Azure Activity Logs).

## Übungen zum Verinnerlichen

### Übung 1: IAM in GCP mit GitHub Actions automatisieren
**Ziel**: Automatisiere die Erstellung einer Custom Role in GCP mit einer CI/CD-Pipeline.

1. **Schritt 1**: Erstelle eine IAM-Role-Definition in deinem GitHub-Repository (`iam/custom-role.yaml`):
   ```yaml
   # custom-role.yaml
   title: MinimalStorageViewer
   description: Least privilege for viewing storage
   includedPermissions:
     - storage.objects.get
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/gcp-iam.yml`):
   ```yaml
   name: Deploy GCP IAM Role
   on:
     push:
       branches: [ main ]
   jobs:
     deploy-iam:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: google-github-actions/auth@v2
         with:
           credentials_json: ${{ secrets.GCP_SA_KEY }}
       - uses: google-github-actions/setup-gcloud@v2
       - run: |
           gcloud iam roles create minimalStorageViewer --project=your-project-id \
             --file=iam/custom-role.yaml
           gcloud projects add-iam-policy-binding your-project-id \
             --member=serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com \
             --role=projects/your-project-id/roles/minimalStorageViewer
   ```
3. **Schritt 3**: Füge den Service Account-Schlüssel als GitHub Secret (`GCP_SA_KEY`) hinzu (Repository Settings > Secrets and Variables > Actions).
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline in GitHub Actions und teste den Zugriff:
   ```bash
   # Lokal testen
   gcloud auth activate-service-account --key-file=sa-key.json
   gsutil ls gs://your-bucket/
   ```

**Reflexion**: Wie reduziert die Automatisierung von IAM in CI/CD manuelle Fehler? Warum ist ein Service Account-Schlüssel sicherer als Benutzer-Credentials?

### Übung 2: IAM in AWS mit GitHub Actions automatisieren
**Ziel**: Automatisiere die Erstellung einer Least-Privilege-Policy in AWS.

1. **Schritt 1**: Erstelle eine IAM-Policy-Definition (`iam/minimal-s3-policy.json`):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::your-bucket/*",
         "Condition": {"Bool": {"aws:SecureTransport": "true"}}
       }
     ]
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/aws-iam.yml`):
   ```yaml
   name: Deploy AWS IAM Policy
   on:
     push:
       branches: [ main ]
   jobs:
     deploy-iam:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: aws-actions/configure-aws-credentials@v4
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-east-1
       - run: |
           aws iam create-policy --policy-name MinimalS3Get \
             --policy-document file://iam/minimal-s3-policy.json
           aws iam attach-role-policy --role-name your-role \
             --policy-arn arn:aws:iam::your-account:policy/MinimalS3Get
   ```
3. **Schritt 3**: Füge AWS-Credentials als GitHub Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) hinzu.
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   aws s3 cp s3://your-bucket/file.txt .
   ```

**Reflexion**: Wie hilft AWS Access Analyzer bei der Validierung? Was passiert, wenn die Policy zu breit definiert ist?

### Übung 3: IAM in Azure mit GitHub Actions automatisieren
**Ziel**: Automatisiere die Erstellung einer Custom Role in Azure RBAC.

1. **Schritt 1**: Erstelle eine Role-Definition (`iam/minimal-storage-role.json`):
   ```json
   {
     "Name": "MinimalStorageReader",
     "Description": "Least privilege for reading storage",
     "AssignableScopes": ["/subscriptions/your-sub-id"],
     "Actions": ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/azure-iam.yml`):
   ```yaml
   name: Deploy Azure IAM Role
   on:
     push:
       branches: [ main ]
   jobs:
     deploy-iam:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: azure/login@v1
         with:
           creds: ${{ secrets.AZURE_CREDENTIALS }}
       - run: |
           az role definition create --role-definition iam/minimal-storage-role.json
           az role assignment create --assignee your-user@domain.com \
             --role MinimalStorageReader \
             --scope /subscriptions/your-sub-id/resourceGroups/your-rg
   ```
3. **Schritt 3**: Füge Azure-Credentials als GitHub Secret (`AZURE_CREDENTIALS`) hinzu (siehe Azure AD Service Principal).
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   az storage blob list --account-name your-account
   ```

**Reflexion**: Wie verbessert Azure PIM die Governance? Warum ist ein Service Principal sicherer als Benutzerkonten?

## Tipps für den Erfolg
- **Least Privilege**: Definiere Policies mit minimalen Rechten und validiere mit Analyzer-Tools.
- **Sicherheit**: Speichere Credentials nur in GitHub Secrets, aktiviere MFA.
- **Fehlerbehebung**: Überprüfe Pipeline-Logs (GitHub Actions) und Cloud-Logs (CloudTrail, Azure Activity Logs).
- **Automatisierung**: Nutze Terraform für komplexe IAM-Setups:
  ```hcl
  # Beispiel für AWS
  resource "aws_iam_policy" "minimal_s3" {
    name = "MinimalS3Get"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = "arn:aws:s3:::your-bucket/*"
      }]
    })
  }
  ```
- **Best Practices**: Versioniere IAM-Definitionen in Git, teste in Sandboxes, überwache regelmäßig.

## Fazit
Du hast gelernt, IAM in CI/CD-Pipelines mit GitHub Actions für GCP, AWS und Azure zu integrieren, um automatisierte Governance mit Least Privilege zu gewährleisten. Wiederhole die Übungen in Testumgebungen, um die Automatisierung zu verinnerlichen.

**Nächste Schritte**:
- Erkunde fortgeschrittene Tools wie GCP IAM Recommender oder Azure PIM.
- Integriere Terraform für Multi-Cloud-IAM.
- Vertiefe dich in Audit- und Compliance-Workflows.

**Quellen**: AWS IAM Docs, Azure RBAC Docs, GCP IAM Docs, GitHub Actions Docs.
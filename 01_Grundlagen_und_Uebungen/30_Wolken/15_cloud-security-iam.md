# Praxisorientierte Anleitung: Cloud-Sicherheit und Governance - IAM

## Einführung
Cloud-Sicherheit und Governance sind entscheidend, um Risiken in verteilten Umgebungen zu minimieren. Diese Anleitung konzentriert sich auf Identity and Access Management (IAM), mit einem detaillierten Fokus auf die Erstellung sicherer Rollen und Richtlinien basierend auf dem Least-Privilege-Prinzip (Zugriff nur auf das Notwendigste). Wir behandeln GCP, AWS und Azure. Ziel ist es, dir praktische Schritte zu vermitteln, um IAM effektiv umzusetzen, Risiken zu reduzieren und Compliance zu gewährleisten.

Voraussetzungen:
- Zugang zu einem GCP-Projekt, AWS-Account oder Azure-Abonnement (mit IAM-Administrationsrechten).
- Grundkenntnisse in Cloud-Konzepten wie Ressourcen, Rollen und Policies.
- Tools: Cloud-Konsole (GCP Console, AWS Management Console, Azure Portal) oder CLI-Tools (`gcloud`, `aws`, `az`).
- Test-Account oder -Projekt für sichere Tests (keine Produktionsumgebung).

## Grundlegende Konzepte
Hier sind die wichtigsten IAM-Konzepte für GCP, AWS und Azure:

1. **Least-Privilege-Prinzip**:
   - Gewähre nur die minimalen Rechte, die für eine Aufgabe benötigt werden.
   - Vermeide breite Rollen; nutze granulare Policies und Bedingungen.
2. **Rollen und Policies**:
   - **GCP**: Predefined Roles, Custom Roles; Policies binden Rollen an Principals.
   - **AWS**: Managed Policies, Inline Policies; Rollen für EC2, Lambda usw.
   - **Azure**: Built-in Roles, Custom Roles; RBAC mit Scopes (Management Group, Subscription, Resource Group).
3. **Monitoring und Governance**:
   - Tools wie GCP IAM Recommender, AWS Access Analyzer, Azure PIM.
   - Bedingte Zugriffe und zeitbeschränkte Rechte.

## Übungen zum Verinnerlichen

### Übung 1: Sichere Rollen in GCP erstellen
**Ziel**: Erstelle eine Custom Role mit Least Privilege für einen Service Account in GCP.

1. **Schritt 1**: Logge dich in die GCP Console ein und navigiere zu IAM & Admin > Roles.
2. **Schritt 2**: Erstelle eine Custom Role (z. B. "MinimalStorageViewer") mit nur notwendigen Permissions (z. B. `storage.objects.get`).
   ```bash
   # Erstelle Role mit gcloud
   gcloud iam roles create minimalStorageViewer --project=your-project-id --title="Minimal Storage Viewer" --description="Least privilege for viewing storage" --permissions=storage.objects.get
   ```
3. **Schritt 3**: Binde die Role an einen Service Account.
   ```bash
   # Binde Role
   gcloud projects add-iam-policy-binding your-project-id --member=serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com --role=projects/your-project-id/roles/minimalStorageViewer
   ```
4. **Schritt 4**: Teste den Zugriff (z. B. `gsutil ls gs://your-bucket/`) und prüfe, ob unnötige Aktionen blockiert werden.

**Reflexion**: Warum ist eine Custom Role besser als eine Predefined Role? Wie wird Least Privilege angewendet?

### Übung 2: Sichere Rollen in AWS erstellen
**Ziel**: Erstelle eine IAM Role mit Least-Privilege-Policy in AWS.

1. **Schritt 1**: Logge dich in die AWS Console ein und navigiere zu IAM > Roles.
2. **Schritt 2**: Erstelle eine Role für EC2 mit einer Customer-Managed Policy (z. B. nur `s3:GetObject`).
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
   ```bash
   # Erstelle Policy
   aws iam create-policy --policy-name MinimalS3Get --policy-document file://policy.json
   ```
3. **Schritt 3**: Weise die Policy der Role zu und valide mit IAM Access Analyzer.
   ```bash
   # Attache Policy
   aws iam attach-role-policy --role-name your-role --policy-arn arn:aws:iam::your-account:policy/MinimalS3Get
   ```
4. **Schritt 4**: Teste den Zugriff (z. B. `aws s3 cp s3://your-bucket/file.txt .`) und überprüfe CloudTrail-Logs.

**Reflexion**: Wie hilft der Condition-Schlüssel bei Least Privilege? Vergleiche mit breiten Managed Policies.

### Übung 3: Sichere Rollen in Azure erstellen
**Ziel**: Erstelle eine Custom Role mit Least Privilege in Azure RBAC.

1. **Schritt 1**: Logge dich in den Azure Portal ein und navigiere zu Azure AD > Roles and Administrators.
2. **Schritt 2**: Erstelle eine Custom Role (z. B. "MinimalStorageReader") mit nur `Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read`.
   ```bash
   # Erstelle Custom Role
   az role definition create --role-definition '{
     "Name": "MinimalStorageReader",
     "Description": "Least privilege for reading storage",
     "AssignableScopes": ["/subscriptions/your-sub-id"],
     "Actions": ["Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"]
   }'
   ```
3. **Schritt 3**: Weise die Role zu (z. B. an einen User in einer Resource Group).
   ```bash
   # Weise Role zu
   az role assignment create --assignee your-user@domain.com --role "MinimalStorageReader" --scope /subscriptions/your-sub-id/resourceGroups/your-rg
   ```
4. **Schritt 4**: Teste den Zugriff (z. B. `az storage blob list --account-name your-account`) und prüfe mit Microsoft Defender for Cloud.

**Reflexion**: Warum ist die Zuweisung zu Groups besser als zu Users? Wie unterstützt PIM Least Privilege?

## Tipps für den Erfolg
- **Start klein**: Beginne mit minimalen Rechten und erweitere bei Bedarf.
- **Regelmäßige Reviews**: Überwache Zugriffe mit CloudTrail (AWS), Audit Logs (GCP), Activity Logs (Azure).
- **Automatisiere**: Nutze Terraform oder CLI-Skripte für IAM-Konfigurationen.
- **Sicherheit zuerst**: Aktiviere MFA, nutze Bedingungen (z. B. IP-Restriktionen), teste in Sandboxes.
- **Updates prüfen**: Beachte neue Features (z. B. IAM-Analyzer in 2025).

## Fazit
Du hast gelernt, sichere IAM-Rollen und Policies in GCP, AWS und Azure mit Least Privilege zu erstellen. Diese Übungen stärken Cloud-Sicherheit und Governance. Wiederhole sie in Testumgebungen, um die Konzepte zu verinnerlichen.

**Nächste Schritte**:
- Erkunde GCP IAM Recommender, AWS Access Analyzer oder Azure PIM.
- Integriere IAM in CI/CD-Pipelines für automatisierte Governance.
- Vertiefe Multi-Cloud-Strategien für hybride Umgebungen.

**Quellen**: AWS IAM Docs, Azure RBAC Docs, GCP IAM Docs.
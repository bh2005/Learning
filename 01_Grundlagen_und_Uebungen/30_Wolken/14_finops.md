# Cloud Cost Management (FinOps)

## Überblick
FinOps optimiert Cloud-Kosten durch Transparenz, Optimierung und Verantwortung. Ziel: Kosten kontrollieren, ROI maximieren. Unternehmen sparen bis zu 21 Mrd. USD.

### Kernprinzipien
- **Visibility**: Kosten mit AWS Cost Explorer/GCP Billing überwachen.
- **Optimization**: Ressourcen rightsizen, Discounts nutzen.
- **Accountability**: Budgets/Alerts einrichten.
- **Best Practices 2025**: Metriken tracken, Kultur fördern, automatisieren.

### Vorteile
- Kosteneinsparungen
- Präzise Forecasts
- Skalierbarkeit

## Quick Start
1. **Vorbereitung**:
   - AWS/GCP-Konto einrichten, IAM sichern.
   - CLI-Tools: `aws cli`, `gcloud`.
   - Test-Ressourcen starten (EC2, GCP VM).

2. **AWS Cost Explorer**:
   - Zugriff: Billing > Cost Explorer
   - Reports: Filter Services/Tags, CSV-Export
   - Budgets/Alerts: AWS Budgets einrichten
   - Tipp: RI-Recommendations prüfen

3. **GCP Billing**:
   - Zugriff: Billing > Reports
   - BigQuery-Export für Dashboards
   - Budgets/Alerts: Schwellenwerte definieren
   - Tipp: Committed Use Discounts nutzen

4. **FinOps Best Practices**:
   - Tracke Metriken (Cost per User)
   - Anomalien korrigieren (>10% Spikes)
   - Automatisiere: `aws ce get-cost-and-usage`

## Tipps
- **Sicherheit**: MFA für Billing, Tags konsistent
- **Fehlerbehebung**: Datenverzögerung (24h) prüfen
- **Erweiterungen**: Splunk, Terraform nutzen 
- **Praxis**: Wöchentliche Checks, monatliche Optimierung 

## Nächste Schritte
- Azure Cost Management erkunden
- HomeLab-Integration (Hybrid-Cloud)
- Auto-Scaling für Optimierung

**Quellen**: AWS Docs, GCP Billing Docs, FinOps 2025 Trends
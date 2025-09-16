# Praxisorientierte Anleitung: Erkundung von Cloud-DR-Lösungen (Azure Site Recovery, AWS Elastic Disaster Recovery)

## Einführung
Cloud-basierte Disaster Recovery (DR)-Lösungen wie **Azure Site Recovery** und **AWS Elastic Disaster Recovery** ermöglichen die Replikation und schnelle Wiederherstellung von Anwendungen und Daten in der Cloud, um Ausfälle durch Hardwaredefekte, Cyberangriffe oder Naturkatastrophen zu minimieren. Diese Dienste bieten automatisierte Failover, Point-in-Time-Recovery und Integration mit Cloud-Infrastruktur, um RTO (Recovery Time Objective) und RPO (Recovery Point Objective) zu optimieren. Diese Anleitung erkundet die Grundlagen, Features und Implementierung dieser Lösungen auf Basis aktueller Informationen (Stand September 2025). Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, Cloud-DR für hybride Umgebungen zu planen und umzusetzen. Diese Anleitung ist ideal für Administratoren und Entwickler, die resiliente Systeme aufbauen möchten.

**Voraussetzungen:**
- Ein Azure- oder AWS-Konto mit Admin-Rechten
- Grundlegende Kenntnisse der Cloud-Konsole (Azure Portal, AWS Management Console)
- Ein Test-VM oder On-Premises-System zum Replizieren
- Externe Speichermedien oder Cloud-Storage für Backups
- Netzwerkverbindung für Replikation

## Grundlegende Cloud-DR-Konzepte
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **DR-Komponenten**:
   - **Replikation**: Kontinuierliche Synchronisation von Daten zu einem sekundären Standort (z. B. Cloud-Region).
   - **Failover**: Automatisierter Wechsel zum sekundären System bei Ausfall.
   - **Failback**: Rückkehr zum primären System nach Behebung.
   - **Testing**: Nicht-disruptive DR-Tests ohne Auswirkungen auf die Produktion.
2. **Vorteile von Cloud-DR**:
   - Kosteneffizienz: Pay-as-you-go, keine dedizierten DR-Sites.
   - Skalierbarkeit: Globale Replikation über Regionen.
   - Compliance: Integrierte Sicherheitsfeatures wie Verschlüsselung.
3. **Wichtige Metriken**:
   - **RTO**: Zeit bis zur Wiederherstellung (z. B. Minuten).
   - **RPO**: Akzeptabler Datenverlust (z. B. Sekunden).

## Übungen zum Verinnerlichen

### Übung 1: Azure Site Recovery einrichten und testen
**Ziel**: Lernen, wie man Azure Site Recovery für VM-Replikation und Failover konfiguriert.

1. **Schritt 1**: Erstelle einen Recovery Services Vault.
   - Öffne das Azure Portal (`portal.azure.com`).
   - Suche nach **Recovery Services vaults** > **Create**.
   - Wähle Subscription, Resource Group, Vault-Name (z. B. `dr-vault`), Region (z. B. West Europe).
   - Klicke **Review + create** > **Create**.
2. **Schritt 2**: Konfiguriere Replikation für eine VM.
   - Im Vault: **Site Recovery** > **Replicated Items** > **Source** > **On-premises** oder **Azure VMs**.
   - Für Azure-VMs: **Enable replication** > Wähle VM > Target Region (z. B. North Europe).
   - Konfiguriere Policy: RPO < 15 Minuten, RTO < 60 Minuten.
   - Starte Replikation; der Status wechselt zu "Protected".
3. **Schritt 3**: Teste Failover und Failback.
   - Im Vault: **Replicated Items** > Wähle VM > **Test failover**.
   - Wähle Recovery Point (z. B. Latest) und Target Resource Group.
   - Nach Test: **Cleanup test failover**.
   - Für Failover: **Planned failover** oder **Unplanned failover** (Simulation).
   - Failback: **Disable replication** > Re-enable in ursprünglicher Region.
4. **Schritt 4**: Überprüfe Metriken.
   - Im Vault: **Overview** > **Metrics** > Überwache RPO/RTO.

**Reflexion**: Warum ist Azure Site Recovery kosteneffizient, und wie unterstützt es hybride Umgebungen? [Ref: Azure Site Recovery-Dokumentation](https://learn.microsoft.com/en-us/azure/site-recovery/)

### Übung 2: AWS Elastic Disaster Recovery einrichten und testen
**Ziel**: Verstehen, wie man AWS Elastic Disaster Recovery für Server-Replikation und Recovery konfiguriert.

1. **Schritt 1**: Erstelle ein AWS DRS-Konto und Staging-Umgebung.
   - Öffne die AWS Management Console (`console.aws.amazon.com`).
   - Suche nach **Elastic Disaster Recovery** > **Get started**.
   - Wähle Source Servers > **Add source server** (On-Premises oder EC2).
   - Für EC2: Wähle Instanz > **Replicate**.
   - Staging Subnet: Wähle VPC, Subnet (z. B. us-east-1a).
2. **Schritt 2**: Konfiguriere Replikation.
   - Installiere AWS Replication Agent auf Source-Server (Download-Link in Console).
   - Starte Replikation: **Actions** > **Start replication**.
   - Überwache: **Source servers** > Status: "Replicating".
3. **Schritt 3**: Teste Recovery und Failback.
   - **Actions** > **Launch recovery instance** > Target AZ (z. B. us-east-1b).
   - Wähle Point-in-Time (z. B. Latest) > Launch.
   - Teste Instanz: SSH/RDP-Zugriff.
   - Cleanup: **Terminate instance**.
   - Für Failback: **Convert to EC2** > **Replicate back** nach Original-Region.
4. **Schritt 4**: Überprüfe Metriken.
   - In DRS-Console: **Metrics** > RPO (sub-sekunden), RTO (Minuten).

**Reflexion**: Wie minimiert AWS DRS Downtime, und welche Vorteile bietet die Staging-Umgebung? [Ref: AWS Elastic Disaster Recovery-Dokumentation](https://docs.aws.amazon.com/drs/)

### Übung 3: Vergleich und Hybrid-Setup
**Ziel**: Lernen, wie man Azure und AWS vergleicht und ein Hybrid-DR-Setup plant.

1. **Schritt 1**: Vergleiche Features in einer Tabelle.

| Feature                  | Azure Site Recovery                          | AWS Elastic Disaster Recovery                |
|--------------------------|----------------------------------------------|---------------------------------------------|
| **Replikation**          | Kontinuierlich, RPO < 5 Min                  | Block-level, RPO sub-sekunden               |
| **Failover**             | Automatisiert, Orchestrierung                | Launch in Minuten, Post-Launch Actions      |
| **Kosten**               | Pay-as-you-go, keine DR-Site-Kosten [Ref](https://learn.microsoft.com/en-us/azure/site-recovery/) | Staging mit minimalem Compute, Pay-per-Use [Ref](https://docs.aws.amazon.com/drs/) |
| **Testing**              | Nicht-disruptiv, Recovery Plans              | Drill-Modus, PIT Snapshots                  |
| **Integration**          | Azure VMs, On-Prem, VMware                    | On-Prem, EC2, Multi-Cloud                   |

2. **Schritt 2**: Plane ein Hybrid-Setup.
   - Primär: Azure Site Recovery für Azure-Workloads.
   - Sekundär: AWS DRS für On-Prem-Replikation.
   - Konfiguriere Cross-Cloud-Sync: Verwende Tools wie AWS DataSync oder Azure Data Box.
3. **Schritt 3**: Teste Hybrid-Failover.
   - Simuliere Ausfall: Failover Azure-VM zu AWS EC2.
   - Überwache RTO/RPO mit Azure Monitor oder AWS CloudWatch.

**Reflexion**: Wie ergänzen Azure und AWS einander in einem Hybrid-DR, und welche Herausforderungen ergeben sich bei Cross-Cloud-Replikation?

## Tipps für den Erfolg
- Definieren Sie RTO/RPO basierend auf Geschäftsanforderungen (z. B. RTO < 1 Stunde für kritische Apps).
- Testen Sie DR-Pläne vierteljährlich, inkl. Failover und Failback.
- Nutzen Sie Automatisierung (z. B. Azure Logic Apps oder AWS Step Functions) für Orchestrierung.
- Berücksichtigen Sie Compliance (z. B. GDPR) bei Cross-Region-Replikation.

## Fazit
In dieser Anleitung haben Sie Cloud-DR-Lösungen wie Azure Site Recovery und AWS Elastic Disaster Recovery erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Replikation, Failover und Vergleichen gesammelt. Diese Fähigkeiten sind essenziell für resiliente Cloud-Umgebungen. Üben Sie weiter, um Multi-Cloud-DR oder Automatisierung zu implementieren!

**Nächste Schritte**:
- Erkunden Sie AWS Backup oder Azure Backup für ergänzende Services.
- Integrieren Sie DR in CI/CD-Pipelines.
- Testen Sie Multi-Region-Setups für globale Resilienz.

**Quellen**:
- Azure Site Recovery-Dokumentation: https://learn.microsoft.com/en-us/azure/site-recovery/
- AWS Elastic Disaster Recovery-Dokumentation: https://docs.aws.amazon.com/drs/
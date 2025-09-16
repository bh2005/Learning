# Praxisorientierte Anleitung: Disaster Recovery für DNS- und LDAP-Systeme auf Debian

## Einführung
Disaster Recovery (DR) für **DNS** (Domain Name System) und **LDAP** (Lightweight Directory Access Protocol) auf Debian-Systemen ist entscheidend, um die Verfügbarkeit von Netzwerkdiensten und Verzeichnisdiensten nach Ausfällen (z. B. Hardwarefehler, Cyberangriffe) sicherzustellen. DNS löst Domainnamen in IP-Adressen auf, während LDAP Benutzer- und Gruppeninformationen für Authentifizierung und Autorisierung verwaltet. Diese Anleitung konzentriert sich auf DR-Strategien für DNS (mit BIND9) und LDAP (mit OpenLDAP) auf Debian, einschließlich Backup, Restore und Replikation. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive DR-Pläne für diese Dienste zu erstellen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die kritische Netzwerkdienste schützen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Installierte BIND9- und OpenLDAP-Server
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Externer Speicher (z. B. NAS, Cloud) für Backups
- Grundlegende Kenntnisse der Linux-Kommandozeile, DNS und LDAP
- Netzwerkverbindung für Replikation und Offsite-Backups

## Grundlegende Disaster Recovery-Konzepte für DNS und LDAP
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **DNS- und LDAP-Konzepte**:
   - **DNS (BIND9)**: Verwaltet Zonendateien und Resolver-Konfigurationen.
   - **LDAP (OpenLDAP)**: Speichert Verzeichnisdaten in einer DIT (Directory Information Tree).
   - **Replikation**: Sekundäre DNS-Server oder LDAP-Replicas für Redundanz.
2. **DR-Komponenten**:
   - **Backup**: Sicherung von Zonendateien (DNS) und LDIF-Dateien (LDAP).
   - **Restore**: Wiederherstellung von Konfigurationen und Datenbanken.
   - **Failover**: Umschaltung auf sekundäre Server bei Ausfall.
   - **RTO/RPO**: Recovery Time Objective (Zeit bis Wiederherstellung), Recovery Point Objective (Datenverlust).
3. **Best Practices**:
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.
   - Regelmäßige Tests von Restore-Prozessen und Replikation.

## Übungen zum Verinnerlichen

### Übung 1: Backup und Restore für DNS (BIND9)
**Ziel**: Lernen, wie man einen BIND9-DNS-Server sichert und nach einem Ausfall wiederherstellt.

1. **Schritt 1**: Richte einen BIND9-Server ein (falls nicht vorhanden).
   - Installiere BIND9:
     ```bash
     sudo apt update
     sudo apt install -y bind9 bind9utils
     ```
   - Konfiguriere eine Zone (z. B. `example.com`):
     ```bash
     sudo nano /etc/bind/named.conf.local
     ```
     Inhalt:
     ```
     zone "example.com" {
         type master;
         file "/etc/bind/db.example.com";
     };
     ```
   - Erstelle Zonendatei:
     ```bash
     sudo nano /etc/bind/db.example.com
     ```
     Inhalt:
     ```
     $TTL 86400
     @ IN SOA ns1.example.com. admin.example.com. (
         2025091601 ; Serial
         3600       ; Refresh
         1800       ; Retry
         604800     ; Expire
         86400 )    ; Minimum TTL
     @ IN NS ns1.example.com.
     ns1 IN A 192.168.1.10
     www IN A 192.168.1.100
     ```
   - Starte BIND9:
     ```bash
     sudo systemctl restart bind9
     ```
2. **Schritt 2**: Sichere DNS-Konfigurationen und Zonendateien.
   - Erstelle ein Backup:
     ```bash
     BACKUP_DIR="/media/backup/dns-$(date +%Y%m%d)"
     sudo mkdir -p $BACKUP_DIR
     sudo rsync -av /etc/bind/ $BACKUP_DIR/
     ```
3. **Schritt 3**: Teste einen Restore.
   - Simuliere Ausfall: Lösche Zonendatei:
     ```bash
     sudo rm /etc/bind/db.example.com
     ```
   - Stelle aus Backup wieder her:
     ```bash
     sudo rsync -av /media/backup/dns-20250916/ /etc/bind/
     sudo systemctl restart bind9
     ```
   - Überprüfe:
     ```bash
     nslookup www.example.com 192.168.1.10
     ```
     Ausgabe sollte `192.168.1.100` sein.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich rsync auf NAS
     - RPO: 24 Stunden, RTO: 30 Minuten
     - Restore: rsync für Konfigurationen, bind9 restart
     ```

**Reflexion**: Warum ist die Sicherung von Zonendateien entscheidend, und wie unterstützt ein sekundärer DNS-Server die Resilienz?

### Übung 2: Backup und Restore für LDAP (OpenLDAP)
**Ziel**: Verstehen, wie man einen OpenLDAP-Server sichert und nach einem Ausfall wiederherstellt.

1. **Schritt 1**: Richte einen OpenLDAP-Server ein (falls nicht vorhanden).
   - Installiere OpenLDAP:
     ```bash
     sudo apt update
     sudo apt install -y slapd ldap-utils
     ```
   - Konfiguriere während der Installation (z. B. Admin-Passwort: `admin`).
   - Füge eine Test-DN hinzu:
     ```bash
     sudo nano test.ldif
     ```
     Inhalt:
     ```
     dn: cn=Test User,dc=example,dc=com
     objectClass: inetOrgPerson
     cn: Test User
     sn: User
     uid: testuser
     userPassword: testpass
     ```
     Importiere:
     ```bash
     ldapadd -x -D "cn=admin,dc=example,dc=com" -W -f test.ldif
     ```
2. **Schritt 2**: Sichere LDAP-Datenbank und Konfiguration.
   - Exportiere LDIF-Backup:
     ```bash
     sudo slapcat -l /media/backup/ldap-$(date +%Y%m%d).ldif
     ```
   - Sichere Konfiguration:
     ```bash
     sudo rsync -av /etc/ldap/ /media/backup/ldap_config-$(date +%Y%m%d)/
     ```
3. **Schritt 3**: Teste einen Restore.
   - Simuliere Ausfall: Lösche LDAP-Datenbank:
     ```bash
     sudo systemctl stop slapd
     sudo rm -rf /var/lib/ldap/*
     ```
   - Stelle LDIF-Backup wieder her:
     ```bash
     sudo systemctl stop slapd
     sudo slapadd -l /media/backup/ldap-20250916.ldif
     sudo chown openldap:openldap /var/lib/ldap/*
     sudo systemctl start slapd
     ```
   - Überprüfe:
     ```bash
     ldapsearch -x -b "dc=example,dc=com" -H ldap://localhost
     ```
     Ausgabe sollte `cn=Test User` enthalten.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich slapcat und rsync auf NAS
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Restore: slapadd für LDIF, rsync für Konfigurationen
     ```

**Reflexion**: Warum ist ein LDIF-Export für LDAP-Restore effizient, und wie unterstützt Replikation die Verfügbarkeit?

### Übung 3: Automatisierte Backups und Offsite-Replikation
**Ziel**: Lernen, wie man automatisierte Backups und Offsite-Replikation für DNS und LDAP einrichtet.

1. **Schritt 1**: Erstelle ein Backup-Skript.
   ```bash
   sudo nano /root/dns_ldap_backup.sh
   ```
   Inhalt:
   ```bash
   #!/bin/bash
   # Backup-Skript für DNS und LDAP
   BACKUP_DIR="/media/backup"
   DATE=$(date +%Y%m%d)

   # DNS Backup
   sudo rsync -av /etc/bind/ $BACKUP_DIR/dns-$DATE/

   # LDAP Backup
   sudo slapcat -l $BACKUP_DIR/ldap-$DATE.ldif
   sudo rsync -av /etc/ldap/ $BACKUP_DIR/ldap_config-$DATE/

   # Offsite-Replikation zu AWS S3
   aws s3 sync $BACKUP_DIR/ s3://dns-ldap-backups/ --delete

   echo "Backup abgeschlossen: $(date)" >> /var/log/dns_ldap_backup.log
   ```
   Mach es ausführbar:
   ```bash
   chmod +x /root/dns_ldap_backup.sh
   ```
2. **Schritt 2**: Konfiguriere AWS S3 für Offsite-Backup.
   - Installiere AWS CLI:
     ```bash
     sudo apt install -y awscli
     aws configure
     ```
     Gib AWS Access Key, Secret Key und Region ein (z. B. `eu-central-1`).
   - Erstelle einen S3-Bucket:
     ```bash
     aws s3 mb s3://dns-ldap-backups
     ```
3. **Schritt 3**: Plane das Backup mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (täglich um 02:00):
   ```
   0 2 * * * /root/dns_ldap_backup.sh >> /var/log/dns_ldap_backup.log 2>&1
   ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich rsync (DNS), slapcat (LDAP), S3-Sync
     - Offsite: S3 (eu-central-1)
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Test: Monatlich simulierter Ausfall
     ```

**Reflexion**: Wie verbessert Offsite-Replikation die Resilienz, und warum ist die Automatisierung von Backups für DNS/LDAP kritisch?

## Tipps für den Erfolg
- Überwachen Sie Dienste: `systemctl status bind9 slapd` oder `nslookup`/`ldapsearch`.
- Testen Sie Restores monatlich, um die Integrität zu gewährleisten.
- Verwenden Sie die 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite (z. B. S3).
- Konfigurieren Sie sekundäre DNS-Server und LDAP-Replicas für Failover.

## Fazit
In dieser Anleitung haben Sie die Grundlagen des Disaster Recovery für DNS (BIND9) und LDAP (OpenLDAP) auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Backups, Restores, Automatisierung und Offsite-Replikation gesammelt. Diese Fähigkeiten sind essenziell für die Sicherung kritischer Netzwerkdienste. Üben Sie weiter, um Multi-Master-Replikation oder Cloud-DR-Lösungen zu integrieren!

**Nächste Schritte**:
- Integrieren Sie Monitoring-Tools wie Check_MK für DNS/LDAP-Überwachung.
- Erkunden Sie Multi-Master-LDAP-Replikation oder sekundäre DNS-Server.
- Implementieren Sie Cloud-DR mit Azure Site Recovery oder AWS Elastic Disaster Recovery.

**Quellen**:
- BIND9-Dokumentation: https://www.isc.org/bind/documentation/
- OpenLDAP-Dokumentation: https://www.openldap.org/doc/
- Debian Wiki (Backup): https://wiki.debian.org/BackupAndRecovery
- AWS S3 Guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html
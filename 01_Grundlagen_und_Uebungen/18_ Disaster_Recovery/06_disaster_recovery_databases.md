# Praxisorientierte Anleitung: Disaster Recovery für Datenbanken auf Debian

## Einführung
Disaster Recovery (DR) für Datenbanken ist entscheidend, um Datenverluste und Ausfallzeiten bei Hardwaredefekten, Softwarefehlern oder Cyberangriffen zu minimieren. Diese Anleitung konzentriert sich auf DR-Strategien für gängige Datenbanksysteme auf Debian: **MySQL/MariaDB** und **PostgreSQL**. Sie deckt Backup, Restore, Replikation und Automatisierung ab, um die Verfügbarkeit und Integrität kritischer Daten zu gewährleisten. Ziel ist es, Ihnen die Fähigkeiten zu vermitteln, effektive DR-Pläne für Datenbanken zu erstellen und umzusetzen. Diese Anleitung ist ideal für Administratoren, die Datenbankdienste schützen möchten.

**Voraussetzungen:**
- Ein Debian-System (z. B. Debian 11 oder 12) mit Root- oder Sudo-Zugriff
- Installierte MySQL/MariaDB- oder PostgreSQL-Server
- Mindestens 4 GB RAM und ausreichend Festplattenspeicher (mindestens 10 GB frei)
- Externer Speicher (z. B. NAS, Cloud) für Backups
- Grundlegende Kenntnisse der Linux-Kommandozeile und Datenbankverwaltung
- Netzwerkverbindung für Replikation und Offsite-Backups

## Grundlegende Disaster Recovery-Konzepte für Datenbanken
Hier sind die wichtigsten Konzepte, die wir behandeln:

1. **Datenbank-DR-Konzepte**:
   - **Backup-Typen**: Logical (SQL-Dumps), Physical (Binärdateien), Incremental (z. B. Binary Logs).
   - **Replikation**: Master-Slave oder Master-Master für Redundanz.
   - **Point-in-Time Recovery (PITR)**: Wiederherstellung zu einem bestimmten Zeitpunkt.
2. **DR-Komponenten**:
   - **RTO (Recovery Time Objective)**: Zeit bis zur Wiederherstellung.
   - **RPO (Recovery Point Objective)**: Maximal akzeptabler Datenverlust.
   - **Failover**: Umschaltung auf einen sekundären Server.
3. **Best Practices**:
   - 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite.
   - Regelmäßige Tests von Restore-Prozessen und Dokumentation.

## Übungen zum Verinnerlichen

### Übung 1: Backup und Restore für MySQL/MariaDB
**Ziel**: Lernen, wie man MySQL/MariaDB-Datenbanken sichert und wiederherstellt.

1. **Schritt 1**: Richte einen MySQL/MariaDB-Server ein (falls nicht vorhanden).
   - Installiere MariaDB:
     ```bash
     sudo apt update
     sudo apt install -y mariadb-server
     sudo systemctl enable --now mariadb
     ```
   - Erstelle eine Test-Datenbank:
     ```bash
     mysql -u root -p
     ```
     Im MySQL-Prompt:
     ```sql
     CREATE DATABASE testdb;
     USE testdb;
     CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100));
     INSERT INTO users (name) VALUES ('Alice'), ('Bob');
     ```
2. **Schritt 2**: Sichere die Datenbank.
   - Erstelle ein Logical Backup (SQL-Dump):
     ```bash
     mysqldump -u root -p testdb > /media/backup/testdb-$(date +%Y%m%d).sql
     ```
   - Sichere Binary Logs für PITR:
     ```bash
     sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
     ```
     Füge hinzu:
     ```
     [mysqld]
     log_bin = /var/log/mysql/mysql-bin.log
     ```
     Starte neu:
     ```bash
     sudo systemctl restart mariadb
     mysqladmin -u root -p flush-logs
     sudo cp /var/log/mysql/mysql-bin.* /media/backup/
     ```
3. **Schritt 3**: Teste einen Restore.
   - Simuliere Ausfall: Lösche die Datenbank:
     ```bash
     mysql -u root -p -e "DROP DATABASE testdb;"
     ```
   - Stelle SQL-Dump wieder her:
     ```bash
     mysql -u root -p -e "CREATE DATABASE testdb;"
     mysql -u root -p testdb < /media/backup/testdb-20250916.sql
     ```
   - Überprüfe:
     ```bash
     mysql -u root -p -e "SELECT * FROM testdb.users;"
     ```
     Ausgabe sollte `Alice` und `Bob` enthalten.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich mysqldump, wöchentlich Binary Logs auf NAS
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Restore: mysqldump für Daten, mysqlbinlog für PITR
     ```

**Reflexion**: Warum sind Binary Logs für PITR wichtig, und wie unterscheidet sich ein Logical Backup von einem Physical Backup?

### Übung 2: Backup und Restore für PostgreSQL
**Ziel**: Verstehen, wie man PostgreSQL-Datenbanken sichert und wiederherstellt.

1. **Schritt 1**: Richte einen PostgreSQL-Server ein (falls nicht vorhanden).
   - Installiere PostgreSQL:
     ```bash
     sudo apt update
     sudo apt install -y postgresql
     sudo systemctl enable --now postgresql
     ```
   - Erstelle eine Test-Datenbank:
     ```bash
     sudo -u postgres psql
     ```
     Im psql-Prompt:
     ```sql
     CREATE DATABASE testdb;
     \c testdb
     CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100));
     INSERT INTO users (name) VALUES ('Alice'), ('Bob');
     ```
2. **Schritt 2**: Sichere die Datenbank.
   - Erstelle ein Logical Backup (SQL-Dump):
     ```bash
     pg_dump -U postgres testdb > /media/backup/testdb-$(date +%Y%m%d).sql
     ```
   - Sichere für PITR (WAL-Logs):
     ```bash
     sudo nano /etc/postgresql/*/main/postgresql.conf
     ```
     Füge hinzu:
     ```
     wal_level = replica
     archive_mode = on
     archive_command = 'cp %p /media/backup/wal/%f'
     ```
     Starte neu:
     ```bash
     sudo systemctl restart postgresql
     ```
3. **Schritt 3**: Teste einen Restore.
   - Simuliere Ausfall: Lösche die Datenbank:
     ```bash
     sudo -u postgres psql -c "DROP DATABASE testdb;"
     ```
   - Stelle SQL-Dump wieder her:
     ```bash
     sudo -u postgres psql -c "CREATE DATABASE testdb;"
     psql -U postgres testdb < /media/backup/testdb-20250916.sql
     ```
   - Überprüfe:
     ```bash
     psql -U postgres testdb -c "SELECT * FROM users;"
     ```
     Ausgabe sollte `Alice` und `Bob` enthalten.
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich pg_dump, wöchentlich WAL-Logs auf NAS
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Restore: pg_dump für Daten, WAL-Logs für PITR
     ```

**Reflexion**: Wie erleichtert PostgreSQL PITR durch WAL-Logs, und warum sind SQL-Dumps für plattformübergreifende Restores nützlich?

### Übung 3: Automatisierte Backups und Offsite-Replikation
**Ziel**: Lernen, wie man automatisierte Backups und Offsite-Replikation für Datenbanken einrichtet.

1. **Schritt 1**: Erstelle ein Backup-Skript.
   ```bash
   sudo nano /root/db_backup.sh
   ```
   Inhalt:
   ```bash
   #!/bin/bash
   # Backup-Skript für MySQL und PostgreSQL
   BACKUP_DIR="/media/backup"
   DATE=$(date +%Y%m%d)

   # MySQL/MariaDB Backup
   mysqldump -u root -p<root_password> --all-databases > $BACKUP_DIR/mysql-$DATE.sql
   sudo cp /var/log/mysql/mysql-bin.* $BACKUP_DIR/mysql-bin-$DATE/

   # PostgreSQL Backup
   pg_dumpall -U postgres > $BACKUP_DIR/postgres-$DATE.sql
   sudo cp -r /media/backup/wal/ $BACKUP_DIR/postgres-wal-$DATE/

   # Offsite-Replikation zu AWS S3
   aws s3 sync $BACKUP_DIR/ s3://db-backups/ --delete

   echo "Backup abgeschlossen: $(date)" >> /var/log/db_backup.log
   ```
   Mach es ausführbar:
   ```bash
   chmod +x /root/db_backup.sh
   ```
   **Hinweis**: Ersetze `<root_password>` durch das tatsächliche MySQL-Root-Passwort oder verwende `.my.cnf` für sichere Zugangsdaten.
2. **Schritt 2**: Konfiguriere AWS S3 für Offsite-Backup.
   - Installiere AWS CLI:
     ```bash
     sudo apt install -y awscli
     aws configure
     ```
     Gib AWS Access Key, Secret Key und Region ein (z. B. `eu-central-1`).
   - Erstelle einen S3-Bucket:
     ```bash
     aws s3 mb s3://db-backups
     ```
3. **Schritt 3**: Plane das Backup mit Cron.
   ```bash
   crontab -e
   ```
   Füge hinzu (täglich um 02:00):
   ```
   0 2 * * * /root/db_backup.sh >> /var/log/db_backup.log 2>&1
   ```
4. **Schritt 4**: Dokumentiere den DR-Plan.
   - Beispiel:
     ```
     - Backup: Täglich mysqldump/pg_dump, wöchentlich Binary/WAL-Logs, S3-Sync
     - Offsite: S3 (eu-central-1)
     - RPO: 24 Stunden, RTO: 1 Stunde
     - Test: Monatlich simulierter Datenbankverlust
     ```

**Reflexion**: Warum ist die Automatisierung von Backups für Datenbanken kritisch, und wie verbessert Offsite-Replikation die Resilienz?

## Tipps für den Erfolg
- Überwachen Sie Datenbankdienste: `systemctl status mariadb postgresql`.
- Testen Sie Restores monatlich, um die Integrität zu gewährleisten.
- Verwenden Sie die 3-2-1-Regel: 3 Kopien, 2 Medien, 1 offsite (z. B. S3).
- Konfigurieren Sie Replikation (z. B. MySQL Master-Slave, PostgreSQL Streaming Replication) für Failover.

## Fazit
In dieser Anleitung haben Sie die Grundlagen des Disaster Recovery für MySQL/MariaDB und PostgreSQL auf Debian erkundet. Durch die Übungen haben Sie praktische Erfahrung mit Backups, Restores, Automatisierung und Offsite-Replikation gesammelt. Diese Fähigkeiten sind essenziell für die Sicherung kritischer Datenbankdienste. Üben Sie weiter, um Replikation oder Cloud-DR-Lösungen zu integrieren!

**Nächste Schritte**:
- Integrieren Sie Monitoring-Tools wie Check_MK oder Prometheus für Datenbank-Überwachung.
- Erkunden Sie Replikationsstrategien wie MySQL Master-Master oder PostgreSQL Hot Standby.
- Implementieren Sie Cloud-DR mit Azure Database Services oder AWS RDS.

**Quellen**:
- MySQL/MariaDB-Dokumentation: https://mariadb.org/documentation/
- PostgreSQL-Dokumentation: https://www.postgresql.org/docs/
- Debian Backup-Wiki: https://wiki.debian.org/BackupAndRecovery
- AWS S3 Guide: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3.html
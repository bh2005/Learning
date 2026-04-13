# Lernprojekt: RSyslog-Server warten und im Betrieb überwachen

## Einführung

Ein zentraler Log-Server, der unbeaufsichtigt läuft, ist nur halb so nützlich. Ohne Log-Rotation füllt sich die Festplatte, ohne Monitoring bemerkt man Ausfälle erst dann, wenn man Logs braucht – und sie fehlen. In dieser Anleitung lernst du, den RSyslog-Server mit `logrotate` zu pflegen, seinen Betrieb mit Checkmk zu überwachen und Logs langfristig zu archivieren.

Du richtest außerdem strukturierte Alarmierung ein: Wenn ein Client keine Logs mehr sendet oder die Festplatte des Log-Servers voll zu laufen droht, soll das auffallen – bevor es ein Problem wird.

**Voraussetzungen:**
- RSyslog-Server läuft unter `192.168.30.120`, Anleitung 01 und 02 abgeschlossen
- Clients senden bereits Logs an den Server
- Checkmk-Instanz vorhanden (optional, für Monitoring-Teil)
- Ansible-Umgebung auf `192.168.30.101`

---

## Grundlegende Konzepte

1. **Log-Rotation mit logrotate**:
   - `rotate N`: Anzahl der aufzuhebenden alten Log-Dateien
   - `daily` / `weekly` / `monthly`: Rotationsintervall
   - `compress` / `delaycompress`: Ältere Dateien mit gzip komprimieren
   - `postrotate`: Skript, das nach der Rotation ausgeführt wird (z. B. RSyslog neu laden)
   - `missingok`: Fehler ignorieren, wenn die Log-Datei nicht existiert
2. **Disk-Management**:
   - `du -sh /var/log/remote/`: Gesamtgröße des Log-Verzeichnisses
   - `find … -mtime +N -delete`: Alte Dateien nach N Tagen löschen
   - `df -h`: Festplattenauslastung überwachen
3. **RSyslog-Monitoring**:
   - `systemctl status rsyslog`: Dienststatus
   - `journalctl -u rsyslog --since "1 hour ago"`: RSyslog-eigene Fehlermeldungen
   - RSyslog Impstats-Modul: interne Statistiken über verarbeitete Nachrichten

---

## Vorbereitung: Aktuellen Zustand prüfen

1. **Log-Verzeichnis analysieren**:
   ```bash
   # Auf 192.168.30.120
   du -sh /var/log/remote/
   du -sh /var/log/remote/*/
   find /var/log/remote/ -name "*.log" | wc -l
   ```
2. **Älteste und neueste Log-Dateien finden**:
   ```bash
   find /var/log/remote/ -name "*.log" -printf "%T@ %p\n" | sort -n | head -5
   find /var/log/remote/ -name "*.log" -printf "%T@ %p\n" | sort -n | tail -5
   ```
3. **RSyslog-Status prüfen**:
   ```bash
   systemctl status rsyslog
   journalctl -u rsyslog --since "24 hours ago" --no-pager | grep -E "error|warning|failed" -i
   ```
4. **Ansible-Projektverzeichnis vorbereiten**:
   ```bash
   # Auf 192.168.30.101
   cd ~/rsyslog-setup
   mkdir -p files
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

---

## Übung 1: Log-Rotation mit logrotate einrichten

**Ziel**: Konfiguriere `logrotate` so, dass Logs im Verzeichnis `/var/log/remote/` täglich rotiert, 30 Tage aufbewahrt und danach komprimiert gelöscht werden.

**Aufgabe**: Lege eine logrotate-Konfiguration an, teste sie manuell und prüfe das Ergebnis.

1. **logrotate-Konfiguration anlegen**:
   ```bash
   # Auf 192.168.30.120
   nano /etc/logrotate.d/rsyslog-remote
   ```
   Inhalt:
   ```
   /var/log/remote/*/*/*/*.log {
       daily
       rotate 30
       compress
       delaycompress
       missingok
       notifempty
       sharedscripts
       create 0640 syslog adm
       postrotate
           /usr/lib/rsyslog/rsyslog-rotate
       endscript
   }
   ```

2. **Rotation manuell testen** (ohne tatsächlich zu rotieren):
   ```bash
   logrotate --debug /etc/logrotate.d/rsyslog-remote
   # Die Ausgabe zeigt, was rotiert werden würde – keine Dateien werden verändert
   ```

3. **Rotation erzwingen** (zum Testen):
   ```bash
   logrotate --force /etc/logrotate.d/rsyslog-remote
   ls -lh /var/log/remote/<hostname>/$(date +%Y-%m-%d)/
   # Komprimierte .gz-Dateien sollten erscheinen
   ```

4. **Automatische Ausführung prüfen**:
   ```bash
   # logrotate wird täglich durch cron/systemd ausgeführt
   cat /etc/cron.daily/logrotate
   # oder
   systemctl status logrotate.timer
   ```

5. **Veraltete Logs älter als 90 Tage sofort löschen** (einmaliger Bereinigungslauf):
   ```bash
   find /var/log/remote/ -name "*.log.gz" -mtime +90 -delete
   find /var/log/remote/ -name "*.log" -mtime +90 -delete
   # Leere Verzeichnisse aufräumen
   find /var/log/remote/ -type d -empty -delete
   ```

**Reflexion**: Warum ist `delaycompress` sinnvoll – welche Konsequenz hätte es, wenn die aktuell rotierende Datei sofort komprimiert würde?

---

## Übung 2: RSyslog-Statistiken aktivieren und auswerten

**Ziel**: Aktiviere das RSyslog-Impstats-Modul, um interne Verarbeitungsstatistiken zu erfassen, und schreibe sie in eine eigene Log-Datei.

**Aufgabe**: Konfiguriere das Statistikmodul, lies die Ausgabe und lerne, Engpässe zu erkennen.

1. **Statistik-Konfiguration anlegen**:
   ```bash
   nano /etc/rsyslog.d/20-stats.conf
   ```
   Inhalt:
   ```
   # Interne RSyslog-Statistiken alle 60 Sekunden ausgeben
   module(load="impstats"
          interval="60"
          severity="7"
          log.syslog="off"
          log.file="/var/log/rsyslog-stats.log")
   ```

2. **RSyslog neu starten**:
   ```bash
   systemctl restart rsyslog
   ```

3. **Statistiken nach ~60 Sekunden lesen**:
   ```bash
   cat /var/log/rsyslog-stats.log
   ```
   Wichtige Felder in der Ausgabe:
   - `submitted`: Anzahl eingereichter Nachrichten
   - `enqueued`: In die Queue eingereihte Nachrichten
   - `discarded.full` / `discarded.nf`: Verworfene Nachrichten (sollten 0 sein!)
   - `called.recvmmsg`: Empfangene UDP-Pakete

4. **Statistiken dauerhaft überwachen**:
   ```bash
   tail -f /var/log/rsyslog-stats.log | grep -E "discarded|enqueued"
   ```

5. **logrotate für Stats-Log ergänzen**:
   ```bash
   nano /etc/logrotate.d/rsyslog-stats
   ```
   Inhalt:
   ```
   /var/log/rsyslog-stats.log {
       weekly
       rotate 4
       compress
       missingok
       notifempty
       postrotate
           /usr/lib/rsyslog/rsyslog-rotate
       endscript
   }
   ```

**Reflexion**: Was bedeutet es, wenn `discarded.full` kontinuierlich steigt – und welche Maßnahmen würdest du ergreifen?

---

## Übung 3: Ansible-Playbook für Wartungsaufgaben

**Ziel**: Automatisiere die Wartungsroutine (logrotate-Konfiguration, Statistikmodul, Disk-Check) mit einem Ansible-Playbook, das bei Bedarf auf dem Server ausgeführt werden kann.

**Aufgabe**: Erstelle ein Wartungs-Playbook und eine Cron-basierte Disk-Warnung.

1. **logrotate-Template für Ansible vorbereiten**:
   ```bash
   # Auf 192.168.30.101
   cd ~/rsyslog-setup
   nano templates/rsyslog-remote.logrotate.j2
   ```
   Inhalt:
   ```
   # Managed by Ansible
   /var/log/remote/*/*/*/*.log {
       {{ rsyslog_logrotate_interval | default('daily') }}
       rotate {{ rsyslog_logrotate_keep | default(30) }}
       compress
       delaycompress
       missingok
       notifempty
       sharedscripts
       create 0640 syslog adm
       postrotate
           /usr/lib/rsyslog/rsyslog-rotate
       endscript
   }
   ```

2. **Disk-Warn-Skript vorbereiten**:
   ```bash
   nano files/check_log_disk.sh
   ```
   Inhalt:
   ```bash
   #!/usr/bin/env bash
   # Warnung per logger, wenn /var/log/remote mehr als 80 % der Partition belegt
   THRESHOLD=80
   USAGE=$(df /var/log/remote --output=pcent | tail -1 | tr -d ' %')
   if [ "$USAGE" -ge "$THRESHOLD" ]; then
       logger -p local0.warning "WARNUNG: /var/log/remote Festplattenbelegung bei ${USAGE}% (Schwellwert: ${THRESHOLD}%)"
   fi
   ```

3. **Wartungs-Playbook schreiben**:
   ```bash
   nano maintenance_rsyslog_server.yml
   ```
   Inhalt:
   ```yaml
   ---
   - name: RSyslog-Server Wartung
     hosts: syslog_server
     vars:
       rsyslog_logrotate_interval: daily
       rsyslog_logrotate_keep: 30
       rsyslog_log_dir: /var/log/remote

     tasks:
       - name: logrotate-Konfiguration deployen
         template:
           src: templates/rsyslog-remote.logrotate.j2
           dest: /etc/logrotate.d/rsyslog-remote
           owner: root
           group: root
           mode: '0644'

       - name: Statistikmodul-Konfiguration deployen
         copy:
           dest: /etc/rsyslog.d/20-stats.conf
           owner: root
           group: root
           mode: '0644'
           content: |
             module(load="impstats"
                    interval="60"
                    severity="7"
                    log.syslog="off"
                    log.file="/var/log/rsyslog-stats.log")
         notify: RSyslog neu starten

       - name: Disk-Check-Skript deployen
         copy:
           src: files/check_log_disk.sh
           dest: /usr/local/bin/check_log_disk.sh
           owner: root
           group: root
           mode: '0755'

       - name: Cron-Job für Disk-Check einrichten (stündlich)
         cron:
           name: "RSyslog Log-Disk-Check"
           minute: "0"
           hour: "*"
           job: "/usr/local/bin/check_log_disk.sh"
           user: root

       - name: Alte komprimierte Logs (>90 Tage) entfernen
         find:
           paths: "{{ rsyslog_log_dir }}"
           patterns: "*.log.gz"
           age: "90d"
           recurse: yes
         register: old_logs

       - name: Anzahl zu löschender Logs ausgeben
         debug:
           msg: "{{ old_logs.files | length }} alte Log-Dateien gefunden (>90 Tage)"

       - name: Alte Logs löschen
         file:
           path: "{{ item.path }}"
           state: absent
         loop: "{{ old_logs.files }}"
         when: old_logs.files | length > 0

       - name: RSyslog-Dienststatus prüfen
         systemd:
           name: rsyslog
         register: rsyslog_status

       - name: RSyslog-Status ausgeben
         debug:
           msg: "RSyslog ist {{ rsyslog_status.status.ActiveState }}"

     handlers:
       - name: RSyslog neu starten
         systemd:
           name: rsyslog
           state: restarted
   ```

4. **Playbook ausführen**:
   ```bash
   ansible-playbook -i inventory.yml maintenance_rsyslog_server.yml
   ```

5. **Ergebnis auf dem Server prüfen**:
   ```bash
   # Auf 192.168.30.120
   crontab -l -u root
   ls -lh /usr/local/bin/check_log_disk.sh
   cat /etc/logrotate.d/rsyslog-remote
   ```

**Reflexion**: Welche weiteren Wartungsaufgaben würdest du in ein solches Playbook aufnehmen – z. B. in Bezug auf Sicherheit oder Archivierung?

---

## Tipps für den Erfolg

- Teste `logrotate` immer zuerst mit `--debug` bevor du `--force` nutzt – so siehst du ohne Risiko, was passiert.
- Der Befehl `rsyslogd -N1 /etc/rsyslog.conf` prüft die gesamte Konfiguration auf Syntaxfehler, ohne den Dienst neu zu starten.
- Richte einen separaten Mount-Punkt für `/var/log/remote/` ein (z. B. dedizierte LVM-Partition), damit ein volles Log-Verzeichnis nicht das Root-Filesystem blockiert.
- Überwache den RSyslog-Prozess in Checkmk mit dem Service-Check `Process: rsyslogd` – so siehst du sofort, wenn der Dienst gestoppt ist.
- Für langfristige Archivierung bietet sich ein NFS-Mount zu TrueNAS (`192.168.30.100`) an: ältere Log-Jahrgänge dorthin verschieben und lokal löschen.

---

## Fazit

Du hast den RSyslog-Server für den laufenden Betrieb fit gemacht: Log-Rotation verhindert volle Festplatten, das Statistikmodul macht Engpässe sichtbar und das Ansible-Wartungs-Playbook sorgt dafür, dass diese Aufgaben reproduzierbar und automatisierbar bleiben.

**Nächste Schritte**:
- [01 – Server einrichten](01_rsyslog_server_einrichtung.md): Grundkonfiguration des Servers
- [02 – Clients konfigurieren](02_rsyslog_clients_konfiguration.md): Hosts zur Weiterleitung einrichten
- **Weiterführende Themen**:
  - RSyslog + Elasticsearch/Graylog: Logs durchsuchbar machen
  - TLS-verschlüsselte Log-Weiterleitung mit `omfwd` und `gtls`-Treiber
  - Checkmk-Integration: Log-Inhalte auf Patterns überwachen (MK Logwatch)

**Quellen**:
- logrotate-Manpage: `man logrotate`
- RSyslog Impstats: https://www.rsyslog.com/doc/v8-stable/configuration/modules/impstats.html
- RSyslog TLS-Konfiguration: https://www.rsyslog.com/doc/v8-stable/tutorials/tls.html
- Checkmk Logwatch-Plugin: https://docs.checkmk.com/latest/de/mk_logwatch.html

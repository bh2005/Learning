# Lernprojekt: RSyslog-Clients konfigurieren – Logs zentral weiterleiten

## Einführung

Nachdem der zentrale RSyslog-Server läuft, müssen die Debian-Hosts im Netzwerk so konfiguriert werden, dass sie ihre Logs an ihn weiterleiten. Jeder Debian-Host hat bereits RSyslog als lokalen Syslog-Daemon vorinstalliert – er muss lediglich um eine Weiterleitungsregel ergänzt werden.

In dieser Anleitung konfigurierst du mehrere Debian-Clients mit Ansible, richtest die Weiterleitung per TCP ein und verifizierst, dass die Logs korrekt auf dem zentralen Server ankommen. Außerdem lernst du, wie du bestimmte Facilities oder Schweregrade gefiltert weiterleiten kannst.

**Voraussetzungen:**
- RSyslog-Server läuft unter `192.168.30.120` (syslog.homelab.local), Anleitung 01 abgeschlossen
- Mindestens ein Debian-Client im Netzwerk (z. B. `192.168.30.101`, `192.168.30.110`)
- Ansible-Umgebung auf `192.168.30.101`
- SSH-Zugriff auf alle Clients

---

## Grundlegende Konzepte

1. **Weiterleitungsregeln**:
   - `*.* @server:514` – alle Logs per **UDP** weiterleiten (kein Verbindungsaufbau, kein Verlust-Tracking)
   - `*.* @@server:514` – alle Logs per **TCP** weiterleiten (zuverlässiger, Reihenfolge garantiert)
   - `auth,authpriv.* @@server:514` – nur auth-Logs weiterleiten
2. **Action-Queue (Pufferspeicher)**:
   - RSyslog kann Nachrichten zwischenspeichern, wenn der Server nicht erreichbar ist
   - `queue.type="LinkedList"`, `queue.fileName`, `queue.saveOnShutdown` – Konfigurationsparameter
   - Verhindert Log-Verlust bei kurzen Netzwerkunterbrechungen
3. **Filterlogik**:
   - `Facility.Severity` – klassische Filter-Syntax (z. B. `kern.crit`, `*.warning`)
   - RainerScript `if/then`: komplexere Filterlogik möglich
   - `stop` – stoppt die weitere Verarbeitung einer Nachricht nach einer Regel

---

## Vorbereitung: Client-Umgebung prüfen

1. **SSH-Zugriff auf Clients prüfen**:
   ```bash
   # Von 192.168.30.101
   ssh root@192.168.30.110
   exit
   ```
2. **RSyslog auf dem Client prüfen**:
   ```bash
   ssh root@192.168.30.110 "rsyslogd -v && systemctl is-active rsyslog"
   ```
3. **Netzwerkverbindung zum Server testen**:
   ```bash
   ssh root@192.168.30.110 "nc -zv 192.168.30.120 514"
   # Erwartete Ausgabe: Connection to 192.168.30.120 514 port [tcp/*] succeeded!
   ```
4. **Projektverzeichnis erweitern**:
   ```bash
   cd ~/rsyslog-setup
   mkdir -p templates group_vars
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf Proxmox (`192.168.30.2`), OPNsense (`192.168.30.1`) und TrueNAS (`192.168.30.100`).

---

## Übung 1: Einfache Log-Weiterleitung manuell einrichten

**Ziel**: Konfiguriere einen einzelnen Debian-Client manuell, um alle Logs per TCP an den zentralen Server zu senden, und verifiziere die Übertragung.

**Aufgabe**: Lege eine Weiterleitungsregel an, starte RSyslog neu und prüfe auf dem Server, ob Logs ankommen.

1. **Auf dem Client einloggen**:
   ```bash
   ssh root@192.168.30.110
   ```

2. **Weiterleitungskonfiguration anlegen**:
   ```bash
   nano /etc/rsyslog.d/50-forward.conf
   ```
   Inhalt:
   ```
   # Alle Logs per TCP an zentralen RSyslog-Server weiterleiten
   *.* action(type="omfwd"
               target="192.168.30.120"
               port="514"
               protocol="tcp"
               action.resumeRetryCount="-1"
               queue.type="LinkedList"
               queue.size="10000"
               queue.saveOnShutdown="on"
               queue.fileName="fwd-main")
   ```

3. **RSyslog neu starten**:
   ```bash
   systemctl restart rsyslog
   systemctl status rsyslog
   ```

4. **Test-Nachricht senden**:
   ```bash
   logger -p local0.info "RSyslog Weiterleitungstest von $(hostname)"
   ```

5. **Auf dem Server prüfen, ob die Nachricht angekommen ist**:
   ```bash
   # Auf 192.168.30.120
   ls /var/log/remote/
   # Hier sollte ein Verzeichnis mit dem Hostnamen des Clients erscheinen
   tail -f /var/log/remote/<hostname>/$(date +%Y-%m-%d)/local0.log
   ```

6. **Echtzeit-Überwachung aller eingehenden Logs**:
   ```bash
   # Auf 192.168.30.120
   tail -f /var/log/remote/*/*/$(date +%Y-%m-%d)/*.log
   ```

**Reflexion**: Warum ist `action.resumeRetryCount="-1"` sinnvoll – und in welchem Szenario könnte es problematisch werden?

---

## Übung 2: Gefilterte Weiterleitung – nur kritische Logs

**Ziel**: Konfiguriere einen Client so, dass er nur Logs ab Schweregrad `warning` und alle `auth`-Logs weiterleitet, um das Volumen auf dem Server zu reduzieren.

**Aufgabe**: Erstelle eine gefilterte Weiterleitungsregel und teste sie mit verschiedenen Log-Schweregraden.

1. **Neue Konfiguration anlegen** (ersetzt die aus Übung 1):
   ```bash
   nano /etc/rsyslog.d/50-forward.conf
   ```
   Inhalt:
   ```
   # Template für Weiterleitung (wird weiter unten referenziert)
   template(name="fwd_template" type="string" string="%msg%\n")

   # Nur auth/authpriv immer weiterleiten (Sicherheitslogs)
   if $syslogfacility-text == 'auth' or $syslogfacility-text == 'authpriv' then {
     action(type="omfwd"
            target="192.168.30.120"
            port="514"
            protocol="tcp"
            queue.type="LinkedList"
            queue.fileName="fwd-auth")
   }

   # Alle anderen Logs ab Schweregrad "warning" weiterleiten
   if $syslogseverity <= 4 and
      $syslogfacility-text != 'auth' and
      $syslogfacility-text != 'authpriv' then {
     action(type="omfwd"
            target="192.168.30.120"
            port="514"
            protocol="tcp"
            queue.type="LinkedList"
            queue.fileName="fwd-warn")
   }
   ```
   > Schweregrade als Zahl: 0=emerg, 1=alert, 2=crit, 3=err, 4=warning, 5=notice, 6=info, 7=debug

2. **RSyslog neu starten**:
   ```bash
   systemctl restart rsyslog
   ```

3. **Verschiedene Schweregrade testen**:
   ```bash
   # Diese sollte ankommen (warning):
   logger -p daemon.warning "TEST warning – sollte auf Server erscheinen"

   # Diese sollte NICHT ankommen (info):
   logger -p daemon.info "TEST info – sollte nicht weitergeleitet werden"

   # Auth-Logs immer weiterleiten:
   logger -p auth.info "TEST auth info – sollte immer weitergeleitet werden"
   ```

4. **Auf dem Server überprüfen**:
   ```bash
   # Auf 192.168.30.120
   grep "TEST" /var/log/remote/<hostname>/$(date +%Y-%m-%d)/*.log
   ```

**Reflexion**: Welche Facilities und Schweregrade würdest du für einen Produktionsserver zwingend immer weiterleiten – und welche könntest du weglassen?

---

## Übung 3: Ansible-Playbook für alle Clients

**Ziel**: Automatisiere die Client-Konfiguration mit Ansible, sodass alle Debian-Hosts im Inventar automatisch korrekt konfiguriert werden.

**Aufgabe**: Erweitere das Inventar aus Anleitung 01, erstelle ein Client-Template und führe das Playbook aus.

1. **Inventar erweitern**:
   ```bash
   cd ~/rsyslog-setup
   nano inventory.yml
   ```
   Inhalt:
   ```yaml
   all:
     children:
       syslog_server:
         hosts:
           syslog:
             ansible_host: 192.168.30.120
             ansible_user: root
             ansible_python_interpreter: /usr/bin/python3

       syslog_clients:
         hosts:
           ubuntu-vm:
             ansible_host: 192.168.30.101
             ansible_user: ubuntu
             ansible_python_interpreter: /usr/bin/python3
           debian-client1:
             ansible_host: 192.168.30.110
             ansible_user: root
             ansible_python_interpreter: /usr/bin/python3
   ```

2. **Gruppen-Variablen für Clients anlegen**:
   ```bash
   nano group_vars/syslog_clients.yml
   ```
   Inhalt:
   ```yaml
   rsyslog_server_ip: "192.168.30.120"
   rsyslog_server_port: 514
   rsyslog_forward_all: false        # nur warning+ und auth weiterleiten
   ```

3. **Client-Konfigurationstemplate erstellen**:
   ```bash
   nano templates/50-forward.conf.j2
   ```
   Inhalt:
   ```
   # Managed by Ansible – nicht manuell bearbeiten

   {% if rsyslog_forward_all %}
   # Alle Logs weiterleiten
   *.* action(type="omfwd"
              target="{{ rsyslog_server_ip }}"
              port="{{ rsyslog_server_port }}"
              protocol="tcp"
              action.resumeRetryCount="-1"
              queue.type="LinkedList"
              queue.size="10000"
              queue.saveOnShutdown="on"
              queue.fileName="fwd-all")
   {% else %}
   # Auth/Authpriv immer weiterleiten
   if $syslogfacility-text == 'auth' or $syslogfacility-text == 'authpriv' then {
     action(type="omfwd"
            target="{{ rsyslog_server_ip }}"
            port="{{ rsyslog_server_port }}"
            protocol="tcp"
            queue.type="LinkedList"
            queue.fileName="fwd-auth")
   }

   # Alle anderen ab "warning" weiterleiten
   if $syslogseverity <= 4 and
      $syslogfacility-text != 'auth' and
      $syslogfacility-text != 'authpriv' then {
     action(type="omfwd"
            target="{{ rsyslog_server_ip }}"
            port="{{ rsyslog_server_port }}"
            protocol="tcp"
            queue.type="LinkedList"
            queue.fileName="fwd-warn")
   }
   {% endif %}
   ```

4. **Client-Playbook schreiben**:
   ```bash
   nano setup_rsyslog_clients.yml
   ```
   Inhalt:
   ```yaml
   ---
   - name: RSyslog-Clients konfigurieren
     hosts: syslog_clients
     become: yes

     tasks:
       - name: RSyslog installieren (falls nicht vorhanden)
         apt:
           name: rsyslog
           state: present
           update_cache: yes

       - name: Weiterleitungskonfiguration deployen
         template:
           src: templates/50-forward.conf.j2
           dest: /etc/rsyslog.d/50-forward.conf
           owner: root
           group: root
           mode: '0644'
         notify: RSyslog neu starten

       - name: RSyslog aktivieren und starten
         systemd:
           name: rsyslog
           enabled: yes
           state: started

       - name: Verbindung zum RSyslog-Server testen
         shell: "nc -zv {{ rsyslog_server_ip }} {{ rsyslog_server_port }}"
         register: nc_result
         ignore_errors: yes

       - name: Verbindungsstatus ausgeben
         debug:
           msg: "Verbindung zu {{ rsyslog_server_ip }}:{{ rsyslog_server_port }} – {{ 'OK' if nc_result.rc == 0 else 'FEHLGESCHLAGEN' }}"

     handlers:
       - name: RSyslog neu starten
         systemd:
           name: rsyslog
           state: restarted
   ```

5. **Playbook ausführen**:
   ```bash
   ansible-playbook -i inventory.yml setup_rsyslog_clients.yml
   ```

6. **Auf dem Server alle eingehenden Hosts prüfen**:
   ```bash
   # Auf 192.168.30.120
   ls /var/log/remote/
   # Erwartete Ausgabe: je ein Verzeichnis pro Client-Hostname
   ```

**Reflexion**: Wie würdest du das Playbook erweitern, um unterschiedliche Clients unterschiedlich zu konfigurieren – z. B. Datenbankserver mit `rsyslog_forward_all: true`?

---

## Tipps für den Erfolg

- Verwende immer TCP statt UDP für die Weiterleitung in Produktionsumgebungen – UDP-Pakete können bei hoher Last still und leise verloren gehen.
- Die `queue.saveOnShutdown`-Option speichert ungesendete Nachrichten auf Disk – so gehen Logs bei einem Neustart des Clients nicht verloren.
- Teste nach jeder Konfigurationsänderung mit `rsyslogd -N1 /etc/rsyslog.conf` auf Syntaxfehler, bevor du neu startest.
- Bei großen Umgebungen: Vergib sprechende Hostnamen (`apt-get install -y hostname` und `/etc/hostname` anpassen) – sonst sind die Log-Verzeichnisse auf dem Server schwer zuzuordnen.
- `nc -zv <server> 514` vor der Konfiguration testen – wenn Port 514 vom Client aus nicht erreichbar ist, nutzt die beste Konfiguration nichts.

---

## Fazit

Du hast Debian-Clients so konfiguriert, dass sie ihre Logs zuverlässig per TCP an den zentralen RSyslog-Server weiterleiten. Du kennst den Unterschied zwischen vollständiger und gefilterter Weiterleitung und hast die Konfiguration mit Ansible automatisiert.

**Nächste Schritte**:
- [01 – Server einrichten](01_rsyslog_server_einrichtung.md): Nachlesen, falls der Server noch nicht steht
- [03 – Wartung und Betrieb](03_rsyslog_wartung_und_betrieb.md): Log-Rotation, Monitoring und Archivierung für den laufenden Betrieb

**Quellen**:
- RSyslog omfwd-Dokumentation: https://www.rsyslog.com/doc/v8-stable/configuration/modules/omfwd.html
- RSyslog Queue-Konzept: https://www.rsyslog.com/doc/v8-stable/concepts/queues.html
- Debian Syslog-Howto: https://wiki.debian.org/Logging

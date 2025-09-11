# Praxisorientierte Anleitung: Integration von tmux in die Shell-Konfiguration mit .bashrc

## Einführung zu tmux
`tmux` ist ein Terminal-Multiplexer, der es ermöglicht, mehrere Terminal-Sitzungen in einem einzigen Fenster zu verwalten. Zu den Hauptfunktionen gehören:
- **Sitzungen**: Speichere und stelle Terminal-Sitzungen wieder her, auch nach Verbindungsabbruch.
- **Fenster und Panels**: Teile das Terminal in mehrere Fenster (tabs) oder Panels (Splits) auf.
- **Automatisierung**: Starte vordefinierte Layouts mit Skripten oder `.bashrc`-Integration.
- **Tastenkombinationen**: Standardmäßig mit `Ctrl+b` (Präfix) gesteuert (z. B. `Ctrl+b c` für neues Fenster).

Diese Anleitung zeigt, wie du `tmux` installierst, konfigurierst und mit der `.bashrc` kombinierst, um Workflows in deiner HomeLab-Umgebung (z. B. Papermerge-Dienste) zu optimieren.

## Grundlegende tmux-Befehle
- `tmux`: Startet eine neue tmux-Sitzung.
- `tmux new -s <name>`: Startet eine benannte Sitzung (z. B. `tmux new -s mysession`).
- `tmux attach -t <name>`: Verbindet sich mit einer bestehenden Sitzung.
- `tmux ls`: Listet alle laufenden Sitzungen.
- **Wichtige Tastenkombinationen** (Präfix `Ctrl+b`):
  - `Ctrl+b c`: Erstellt ein neues Fenster.
  - `Ctrl+b %`: Teilt das Fenster vertikal.
  - `Ctrl+b "`: Teilt das Fenster horizontal.
  - `Ctrl+b d`: Detacht (verlässt) die Sitzung ohne Beenden.
  - `Ctrl+b n` / `Ctrl+b p`: Wechselt zum nächsten/vorherigen Fenster.
  - `Ctrl+b ,`: Benennt das aktuelle Fenster um.

## Vorbereitung: Umgebung prüfen
1. **Verbinde dich mit dem Debian-Container**:
   ```bash
   ssh root@192.168.30.120
   ```
2. **Prüfe die Shell-Konfiguration**:
   ```bash
   env
   alias
   ```
   - Überprüfe `PATH`, `HOME`, `USER` und bestehende Aliases.
3. **Sichere die .bashrc**:
   ```bash
   cp ~/.bashrc ~/.bashrc.bak
   ```

**Tipp**: Arbeite auf dem Debian-Container (`192.168.30.120`) und nutze TrueNAS (`192.168.30.100`) für Backups.

## Übung 1: Installation und Grundkonfiguration von tmux
**Ziel**: Installiere `tmux`, erstelle eine Basis-Konfigurationsdatei (`~/.tmux.conf`) und teste grundlegende Funktionen.

1. **Installiere tmux**:
   ```bash
   apt update
   apt install -y tmux
   ```
   Überprüfe:
   ```bash
   tmux -V
   ```
   - Erwartete Ausgabe: `tmux <version>` (z. B. `tmux 3.3a`).

2. **Erstelle eine tmux-Konfigurationsdatei**:
   ```bash
   nano ~/.tmux.conf
   ```
   Füge hinzu:
   ```bash
   # Setze Präfix auf Ctrl+a (statt Ctrl+b)
   set -g prefix C-a
   unbind C-b
   bind C-a send-prefix

   # Mausunterstützung aktivieren
   set -g mouse on

   # Statusleiste anpassen
   set -g status-style bg=blue,fg=white
   set -g status-left "[#S] "
   set -g status-right "%Y-%m-%d %H:%M"

   # Fenster-Nummerierung bei 1 beginnen
   set -g base-index 1
   setw -g pane-base-index 1

   # Schnellere Reaktion auf Tasten
   set -s escape-time 0
   ```
   Speichere und schließe.

3. **Teste tmux**:
   ```bash
   tmux
   ```
   - Erstelle ein neues Fenster: `Ctrl+a c`.
   - Teile das Fenster vertikal: `Ctrl+a %`.
   - Teile das Fenster horizontal: `Ctrl+a "`.
   - Wechsle zwischen Panels: `Ctrl+a Pfeiltasten`.
   - Detache die Sitzung: `Ctrl+a d`.
   - Liste Sitzungen: `tmux ls`.
   - Verbinde dich wieder: `tmux attach`.
   - Erwartete Ausgabe: Funktionierende Sitzung mit angepasster Statusleiste.

4. **Sichere die Konfiguration auf TrueNAS**:
   ```bash
   scp ~/.tmux.conf root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
   ```

**Reflexion**: Wie verbessert `tmux` die Verwaltung mehrerer Aufgaben? Überlege, wie Mausunterstützung die Bedienung erleichtert.

## Übung 2: Integration von tmux in die .bashrc
**Ziel**: Erstelle Aliases, Funktionen und Umgebungsvariablen in der `.bashrc`, um `tmux`-Workflows zu automatisieren.

1. **Erstelle Aliases für tmux**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   alias tnew='tmux new -s'
   alias tattach='tmux attach -t'
   alias tls='tmux ls'
   alias tkill='tmux kill-session -t'
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   tnew mysession
   # In tmux: Ctrl+a d
   tls
   tattach mysession
   tkill mysession
   ```
   - Erwartete Ausgabe: Sitzung wird erstellt, gelistet, verbunden und gelöscht.

2. **Erstelle eine tmux-Funktion für Papermerge-Überwachung**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function tmux_papermerge() {
       SESSION_NAME="papermerge"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           echo "Sitzung $SESSION_NAME existiert bereits. Verbinde..."
           tattach "$SESSION_NAME"
           return
       fi
       tnew "$SESSION_NAME"
       tmux rename-window -t "$SESSION_NAME":1 "Services"
       tmux split-window -h
       tmux send-keys -t "$SESSION_NAME":1.0 'systemctl status nginx' C-m
       tmux send-keys -t "$SESSION_NAME":1.1 'systemctl status gunicorn' C-m
       tmux split-window -v -t "$SESSION_NAME":1.0
       tmux send-keys -t "$SESSION_NAME":1.2 'systemctl status postgresql' C-m
       tmux select-pane -t "$SESSION_NAME":1.0
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   tmux_papermerge
   ```
   - Erwartete Ausgabe: Eine tmux-Sitzung mit drei Panels, die den Status von Nginx, Gunicorn und PostgreSQL anzeigen.

3. **Umgebungsvariablen für tmux**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   export TMUX_DEFAULT_SESSION="homelab"
   if [ -z "$TMUX" ]; then
       if tmux has-session -t "$TMUX_DEFAULT_SESSION" 2>/dev/null; then
           tattach "$TMUX_DEFAULT_SESSION"
       else
           tnew "$TMUX_DEFAULT_SESSION"
       fi
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   exit  # Verlasse das Terminal
   ssh root@192.168.30.120
   ```
   - Erwartete Ausgabe: Das Terminal startet automatisch in einer tmux-Sitzung namens `homelab`.

4. **Konditionale tmux-Konfiguration**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   if command -v tmux >/dev/null 2>&1; then
       alias t='tmux'
       export TMUX_CONF="$HOME/.tmux.conf"
       echo "tmux ist installiert, Konfiguration: $TMUX_CONF"
   else
       echo "tmux ist nicht installiert. Bitte mit 'apt install tmux' installieren."
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   t
   ```
   - Erwartete Ausgabe: Startet `tmux`, wenn installiert, sonst Fehlermeldung.

**Reflexion**: Wie verbessern Aliases und Funktionen die tmux-Nutzung? Überlege, wie du `tmux_papermerge` für andere Dienste anpassen kannst.

## Übung 3: Erweiterte tmux-Workflows mit .bashrc
**Ziel**: Erstelle komplexe tmux-Workflows, integriere sie mit `.bashrc` und sichere die Konfiguration.

1. **Erstelle eine tmux-Sitzung für HomeLab-Monitoring**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function tmux_homelab() {
       SESSION_NAME="homelab_monitor"
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tattach "$SESSION_NAME"
           return
       fi
       tnew "$SESSION_NAME"
       tmux rename-window -t "$SESSION_NAME":1 "Monitoring"
       tmux split-window -h
       tmux split-window -v -t "$SESSION_NAME":1.0
       tmux send-keys -t "$SESSION_NAME":1.0 'watch -n 2 df -h /var/lib/papermerge' C-m
       tmux send-keys -t "$SESSION_NAME":1.1 'htop' C-m
       tmux send-keys -t "$SESSION_NAME":1.2 'tail -f /var/log/nginx/access.log' C-m
       tmux new-window -t "$SESSION_NAME" -n "Logs"
       tmux send-keys -t "$SESSION_NAME":2 'tail -f /var/log/postgresql/postgresql-15-main.log' C-m
       tmux select-window -t "$SESSION_NAME":1
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   tmux_homelab
   ```
   - Erwartete Ausgabe: Eine tmux-Sitzung mit zwei Fenstern: "Monitoring" (drei Panels mit Festplattennutzung, htop, Nginx-Logs) und "Logs" (PostgreSQL-Logs).

2. **Sichere tmux- und Bash-Konfiguration auf TrueNAS**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function backup_configs() {
       trap 'echo "Backup unterbrochen"; exit 1' INT TERM
       tar -czf /tmp/config-backup-$(date +%Y-%m-%d).tar.gz ~/.bashrc ~/.tmux.conf
       scp /tmp/config-backup-$(date +%Y-%m-%d).tar.gz root@192.168.30.100:/mnt/tank/backups/debian-upgrade/
       echo "Konfigurationen gesichert auf TrueNAS"
       trap - INT TERM
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   backup_configs
   ```
   - Erwartete Ausgabe: `.bashrc` und `.tmux.conf` werden auf TrueNAS gesichert.

3. **Erstelle eine tmux-Funktion mit Parametern**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function tmux_project() {
       if [ $# -eq 0 ]; then
           echo "Usage: tmux_project <session_name> <directory>"
           return 1
       fi
       SESSION_NAME="$1"
       PROJECT_DIR="$2"
       if [ ! -d "$PROJECT_DIR" ]; then
           echo "Fehler: Verzeichnis $PROJECT_DIR existiert nicht"
           return 1
       fi
       if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
           tattach "$SESSION_NAME"
           return
       fi
       tnew "$SESSION_NAME"
       tmux send-keys -t "$SESSION_NAME":1 "cd $PROJECT_DIR" C-m
       tmux split-window -h
       tmux send-keys -t "$SESSION_NAME":1.1 "cd $PROJECT_DIR && git status" C-m
   }
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste:
   ```bash
   mkdir ~/projects/testproject
   cd ~/projects/testproject
   git init
   tmux_project "testproject" "~/projects/testproject"
   ```
   - Erwartete Ausgabe: tmux-Sitzung mit zwei Panels, eines im Projektverzeichnis, eines mit `git status`.

4. **Git-Status im Prompt mit tmux**:
   ```bash
   nano ~/.bashrc
   ```
   Füge hinzu:
   ```bash
   function git_branch() {
       git branch 2>/dev/null | grep -E "\*" | sed -E "s/^\* (.+)$/\1/"
   }
   if [ -n "$TMUX" ]; then
       export PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[33m\]($(git_branch))\[\e[0m\]\$ '
   else
       export PS1='\[\e[32m\]\u@\h:\[\e[34m\]\w\[\e[0m\]\$ '
   fi
   ```
   Speichere, schließe und lade:
   ```bash
   source ~/.bashrc
   ```
   Teste in einer tmux-Sitzung:
   ```bash
   tmux
   cd ~/projects/testproject
   ```
   - Erwartete Ausgabe: Prompt zeigt Git-Branch in tmux-Sitzungen (z. B. `(main)`).

**Reflexion**: Wie kann `tmux` mit `.bashrc` Workflows wie Server-Monitoring automatisieren? Probiere `tmux new -s test -n editor 'vim'`, um Editoren direkt zu starten.

## Tipps für den Erfolg
- **Modularität**: Lagere tmux-spezifische Aliases in `~/.bash_aliases` und source sie in `.bashrc`:
  ```bash
  if [ -f ~/.bash_aliases ]; then
      source ~/.bash_aliases
  fi
  ```
- **tmux.conf erweitern**: Füge Tastenkombinationen hinzu, z. B.:
  ```bash
  bind r source-file ~/.tmux.conf \; display "tmux.conf reloaded!"
  ```
- **Fehlerbehandlung**: Nutze `trap` in Funktionen für saubere Abbrüche:
  ```bash
  trap 'tmux kill-session -t "$SESSION_NAME" 2>/dev/null; echo "Sitzung beendet"' INT
  ```
- **Performance**: Vermeide schwere Befehle in `.bashrc` (z. B. `git status` in großen Repos); teste mit `time source ~/.bashrc`.
- **Sicherheit**: Sichere sensible Konfigurationen:
  ```bash
  chmod 600 ~/.tmux.conf ~/.bashrc
  ```
- **Backup**: Automatisiere Backups mit einem Cronjob:
  ```bash
  crontab -e
  ```
  Füge hinzu:
  ```bash
  0 3 * * * /bin/bash -c "source ~/.bashrc && backup_configs" >> /var/log/config-backup.log 2>&1
  ```

## Fazit
Durch diese Übungen hast du gelernt, `tmux` zu installieren, mit `.bashrc` zu integrieren und komplexe Workflows für die HomeLab-Umgebung zu erstellen. Du hast Aliases, Funktionen mit Parametern, Umgebungsvariablen und Git-Integration kombiniert, um die Produktivität zu steigern. Wiederhole die Übungen, um `tmux` für andere Aufgaben (z. B. Entwicklung, Monitoring) anzupassen.

**Nächste Schritte**: Möchtest du eine Anleitung zu `tmux` mit `oh-my-zsh`, erweiterten tmux-Skripten oder Integration mit anderen HomeLab-Tools (z. B. Checkmk)?

**Quellen**:
- Tmux-Dokumentation: `man tmux`, https://github.com/tmux/tmux/wiki
- Bash-Dokumentation: `man bash`, https://www.gnu.org/software/bash/manual/
- Webquellen: https://tmuxcheatsheet.com/, https://www.man7.org/linux/man-pages/man1/tmux.1.html
```
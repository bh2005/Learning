# Praxisorientierte Anleitung: PowerShell-Befehle für Windows zur Netzwerkverwaltung, Firewall-Konfiguration und sichere Remote-Verbindungen

## Einführung
Die PowerShell bietet leistungsstarke Werkzeuge zur Verwaltung von Netzwerkschnittstellen, Firewall-Regeln und sicheren Verbindungen unter Windows. Diese Anleitung orientiert sich an den angegebenen Linux-Befehlen und zeigt deren Äquivalente in PowerShell. Die Schwerpunkte sind **Netzwerkverwaltung**, **Firewall-Konfiguration** sowie **SSH und sichere Dateiübertragung**. Durch praktische Übungen lernst du, PowerShell-Cmdlets anzuwenden, um Netzwerkeinstellungen zu konfigurieren, Verbindungen zu testen und sichere Remote-Zugriffe einzurichten.

Voraussetzungen:
- Ein Windows-System (z. B. Windows 10 oder 11).
- PowerShell (vorinstalliert, starte mit `powershell` oder `pwsh` für PowerShell Core).
- Administratorrechte für einige Befehle (z. B. Netzwerk- und Firewall-Konfiguration).
- Grundlegendes Verständnis von Netzwerkkonzepten (z. B. IP-Adressen, DNS, Ports).
- Internetzugang für Tests und Installationen (z. B. OpenSSH).
- Sichere Testumgebung (z. B. VM), um Konfigurationen risikofrei auszuprobieren.
- Optional: OpenSSH für Windows für SSH/SCP-Funktionen.

## Grundlegende Befehle
Hier sind die wichtigsten PowerShell-Befehle, die den Linux-Pendants entsprechen, aufgeteilt nach den Schwerpunkten:

1. **Netzwerkverwaltung**:
   - `Get-NetAdapter` (ähnlich `ip link`): Zeigt Netzwerkschnittstellen an.
   - `Get-NetIPAddress` (ähnlich `ip addr`): Zeigt IP-Adressen und Konfigurationen.
   - `Test-Connection` (ähnlich `ping`): Testet die Erreichbarkeit eines Hosts.
   - `Get-NetTCPConnection` (ähnlich `ss`): Zeigt Netzwerkverbindungen und Sockets.
   - `Invoke-WebRequest` (ähnlich `curl`): Sendet HTTP-Anfragen und zeigt Antworten.
   - `Invoke-WebRequest` oder `Start-BitsTransfer` (ähnlich `wget`): Lädt Dateien aus dem Internet.
   - `Resolve-DnsName` (ähnlich `nslookup`): Fragt DNS-Server nach Hostinformationen.
   - Kein direkter `links2`-Ersatz, aber `Invoke-WebRequest` für textbasiertes Abrufen von Webseiten.
2. **Firewall**:
   - `Get-NetFirewallRule`/`New-NetFirewallRule` (ähnlich `ufw`/`iptables`): Verwaltet Windows-Firewall-Regeln.
   - `Set-NetFirewallProfile` (ähnlich `iptables`): Konfiguriert Firewall-Profile.
3. **SSH & SCP**:
   - `ssh` (ähnlich `ssh`, benötigt OpenSSH): Stellt eine sichere Remote-Verbindung her.
   - `scp` (ähnlich `scp`, benötigt OpenSSH): Kopiert Dateien sicher zwischen Hosts.
   - `New-SSHKey` oder `ssh-keygen` (ähnlich `ssh-keygen`, benötigt OpenSSH): Generiert SSH-Schlüsselpaare.
4. **Sonstige nützliche Befehle**:
   - `Get-Help` (ähnlich `man`): Zeigt die Hilfeseite eines Befehls an.
   - `Start-Process -Verb RunAs` (ähnlich `sudo`): Führt Befehle mit Administratorrechten aus.

## Übungen zum Verinnerlichen der Befehle

### Übung 1: Netzwerkverwaltung
**Ziel**: Lerne, wie du Netzwerkschnittstellen konfigurierst und Netzwerkverbindungen testest.

1. **Schritt 1**: Zeige alle Netzwerkschnittstellen und deren Status:
   ```powershell
   Get-NetAdapter
   ```
   Notiere den Namen deiner primären Schnittstelle (z. B. `Ethernet` oder `Wi-Fi`).
2. **Schritt 2**: Zeige die IP-Adressen der Schnittstellen:
   ```powershell
   Get-NetIPAddress | Select-Object InterfaceAlias, IPAddress
   ```
   Überprüfe deine IPv4-Adresse (z. B. `192.168.1.100`).
3. **Schritt 3**: Teste die Erreichbarkeit eines Hosts (z. B. google.com):
   ```powershell
   Test-Connection google.com
   ```
   Nutze den Alias `ping`:
   ```powershell
   ping google.com
   ```
4. **Schritt 4**: Zeige aktive TCP-Verbindungen:
   ```powershell
   Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State
   ```
5. **Schritt 5**: Sende eine HTTP-Anfrage und lade eine Datei:
   ```powershell
   Invoke-WebRequest -Uri "https://example.com" | Select-Object Content
   Start-BitsTransfer -Source "https://example.com/example.txt" -Destination "$HOME\example.txt"
   Get-Content $HOME\example.txt -ErrorAction SilentlyContinue
   ```
6. **Schritt 6**: Führe eine DNS-Abfrage durch:
   ```powershell
   Resolve-DnsName google.com
   ```

**Reflexion**: Wie unterscheidet sich `Get-NetTCPConnection` von `ss`? Schaue in `Get-Help Get-NetTCPConnection` und überlege, wie du Netzwerkprobleme diagnostizieren könntest.

### Übung 2: Firewall-Konfiguration
**Ziel**: Lerne, wie du Windows-Firewall-Regeln konfigurierst.

1. **Schritt 1**: Zeige alle aktiven Firewall-Regeln:
   ```powershell
   Get-NetFirewallRule | Where-Object { $_.Enabled -eq $true } | Select-Object Name, DisplayName, Action
   ```
2. **Schritt 2**: Erstelle eine neue Regel, um eingehenden HTTP-Verkehr (Port 80) zuzulassen:
   ```powershell
   New-NetFirewallRule -Name "AllowHTTP" -DisplayName "Allow HTTP" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 80
   ```
   Überprüfe:
   ```powershell
   Get-NetFirewallRule -Name "AllowHTTP"
   ```
3. **Schritt 3**: Deaktiviere die Regel:
   ```powershell
   Disable-NetFirewallRule -Name "AllowHTTP"
   Get-NetFirewallRule -Name "AllowHTTP" | Select-Object Enabled
   ```
4. **Schritt 4**: Ändere das Firewall-Profil (z. B. öffentliches Profil):
   ```powershell
   Set-NetFirewallProfile -Profile Public -Enabled True
   Get-NetFirewallProfile -Profile Public
   ```
5. **Schritt 5**: Entferne die erstellte Regel:
   ```powershell
   Remove-NetFirewallRule -Name "AllowHTTP"
   Get-Net秩序

System: NetFirewallRule -Name "AllowHTTP" -ErrorAction SilentlyContinue
   ```

**Reflexion**: Wie unterscheiden sich Windows-Firewall-Regeln von `iptables`? Schaue in `Get-Help New-NetFirewallRule` und überlege, wie du komplexere Regeln (z. B. für bestimmte IPs) erstellen könntest.

### Übung 3: SSH und sichere Dateiübertragung
**Ziel**: Lerne, wie du SSH-Verbindungen und sichere Dateiübertragungen einrichtest und automatisierst.

1. **Schritt 1**: Installiere OpenSSH für Windows (falls nicht vorhanden):
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
   ssh -V
   ```
2. **Schritt 2**: Generiere ein SSH-Schlüsselpaar:
   ```powershell
   ssh-keygen -t ed25519 -C "test@example.com"
   Get-Content $HOME\.ssh\id_ed25519.pub
   ```
   Hinweis: Kopiere den öffentlichen Schlüssel für die spätere Verwendung (z. B. auf einem Remote-Server).
3. **Schritt 3**: Teste eine SSH-Verbindung zu einem Remote-Server (ersetze `<user>` und `<host>`):
   ```powershell
   ssh <user>@<host>
   ```
   Hinweis: Du benötigst einen laufenden SSH-Server für Tests (z. B. auf einer Linux-VM).
4. **Schritt 4**: Kopiere eine Datei per SCP zu einem Remote-Server:
   ```powershell
   New-Item -ItemType File -Name test.txt
   "Testdaten" | Out-File test.txt
   scp test.txt <user>@<host>:/home/<user>/test.txt
   ```
5. **Schritt 5**: Erstelle ein Skript zur automatischen Übertragung von Dateien:
   ```powershell
   New-Item -ItemType File -Name auto_scp.ps1
   @"
   \$source = "\$HOME\test.txt"
   \$destination = "<user>@<host>:/home/<user>/test.txt"
   \$logFile = "\$HOME\scp_log.txt"
   scp \$source \$destination
   "Datei übertragen: \$(Get-Date)" | Out-File -FilePath \$logFile -Append
   "@ | Out-File auto_scp.ps1
   ```
   Führe es aus (setze `<user>` und `<host>` ein):
   ```powershell
   .\auto_scp.ps1
   Get-Content $HOME\scp_log.txt
   ```
6. **Schritt 6**: Plane das Skript mit dem Task Scheduler (stündlich):
   ```powershell
   $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File $HOME\auto_scp.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At "12:00 AM" -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 1)
   Register-ScheduledTask -TaskName "AutoSCP" -Action $action -Trigger $trigger -Description "Automatische Dateiübertragung"
   ```

**Reflexion**: Warum ist OpenSSH für Windows nützlich? Schaue in `Get-Help ssh` und überlege, wie du SSH-Schlüssel sicher verwaltest.

## Tipps für den Erfolg
- **Übe regelmäßig**: Wiederhole die Übungen, um die Cmdlets zu verinnerlichen.
- **Experimentiere sicher**: Nutze Testumgebungen für Netzwerk- und Firewall-Änderungen.
- **Fehler sind normal**: Lies Fehlermeldungen und nutze `Get-Help` oder Online-Ressourcen.
- **Vorsicht bei Admin-Befehlen**: Firewall- und Netzwerkänderungen können die Konnektivität beeinflussen.
- **Logs überprüfen**: Nutze Skript-Logs (z. B. `scp_log.txt`) oder `Get-WinEvent` zur Fehlersuche.
- **Skripte modular gestalten**: Verwende Variablen und Bedingungen für flexible Automatisierung.

## Fazit
Durch diese Übungen hast du PowerShell-Befehle für Netzwerkverwaltung, Firewall-Konfiguration und sichere Remote-Verbindungen angewendet. Wiederhole die Übungen und experimentiere mit erweiterten Cmdlets (z. B. `Test-NetConnection` für erweiterte Diagnosen oder `Set-NetIPInterface` für fortgeschrittene Netzwerkkonfigurationen), um deine Fähigkeiten zu vertiefen.
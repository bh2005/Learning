# Praxisorientierte Anleitung: Zero Trust für Netzwerksicherheit im On-Premises-HomeLab

## Einführung
Zero Trust ist ein Sicherheitsmodell, das davon ausgeht, dass kein Akteur – weder innerhalb noch außerhalb des Netzwerks – automatisch vertrauenswürdig ist. Es erfordert kontinuierliche Verifizierung von Identitäten, Geräten und Zugriffen sowie die Beschränkung auf minimale Berechtigungen (Least Privilege). Diese Anleitung zeigt, wie man Zero Trust in einem Debian-basierten HomeLab (z. B. mit LXC-Containern) implementiert, mit Fokus auf Netzwerksicherheit durch `iptables`, `nftables` und hybride Cloud-Verbindungen (z. B. zu AWS, GCP, Azure). Ziel ist es, dir praktische Schritte zur Absicherung deines HomeLabs zu vermitteln, um Angriffsflächen zu minimieren.

Voraussetzungen:
- Ein Debian-basiertes HomeLab mit LXC-Containern (z. B. `game-container`).
- Installierte Tools: `iptables`, `nftables`, `ansible`, `rsyslog`, `auditd`.
- Optional: Zugang zu einem Cloud-Anbieter (AWS, GCP, Azure) für hybride Tests.
- Ein GitHub-Repository für CI/CD (z. B. GitHub Actions).
- Grundkenntnisse in Netzwerkkonzepten (z. B. Ports, IP-Bereiche) und Ansible.
- Testumgebung ohne Produktionsdaten.

## Grundlegende Konzepte
Hier sind die wichtigsten Prinzipien von Zero Trust mit Fokus auf On-Prem:

1. **Zero Trust Prinzipien**:
   - **Verifiziere immer**: Jede Verbindung benötigt Identitäts- und Geräteprüfung (z. B. via SSH-Keys oder Zertifikate).
   - **Least Privilege**: Gewähre nur minimal benötigte Zugriffe (z. B. spezifische Ports/IPs).
   - **Kontinuierliche Überwachung**: Protokolliere und analysiere alle Zugriffe mit `auditd` und `rsyslog`.
2. **On-Prem Netzwerksicherheit**:
   - **iptables/nftables**: Stateful/stateless Firewall-Regeln für LXC-Container.
   - **Netzwerksegmentierung**: Isoliere Container mit VLANs oder Bridge-Netzwerken.
3. **Hybride Integration**:
   - Verbinde HomeLab mit Cloud via VPN (z. B. AWS VPN, WireGuard).
   - Nutze Cloud-Logs für zentralisierte Überwachung.

## Übungen zum Verinnerlichen

### Übung 1: Netzwerksegmentierung mit iptables im HomeLab
**Ziel**: Konfiguriere `iptables` für Zero Trust in einem LXC-Container.

1. **Schritt 1**: Erstelle ein Ansible-Playbook für `iptables` (`zero_trust_iptables.yml`):
   ```yaml
   - name: Zero Trust iptables für LXC
     hosts: lxc_hosts
     tasks:
       - name: Installiere iptables
         ansible.builtin.apt:
           name: iptables
           state: present
           update_cache: yes
       - name: Setze SSH-Regel (nur vertrautes Netzwerk)
         ansible.builtin.iptables:
           chain: INPUT
           protocol: tcp
           destination_port: 22
           source: "192.168.1.0/24"
           jump: ACCEPT
       - name: Setze HTTP-Regel (spezifische IP)
         ansible.builtin.iptables:
           chain: INPUT
           protocol: tcp
           destination_port: 80
           source: "your-ip/32"
           jump: ACCEPT
       - name: Droppe anderen eingehenden Traffic
         ansible.builtin.iptables:
           chain: INPUT
           jump: DROP
       - name: Speichere iptables-Regeln
         ansible.builtin.command: iptables-save > /etc/iptables/rules.v4
   ```
2. **Schritt 2**: Erstelle ein Inventory für LXC (`inventory.yml`):
   ```yaml
   lxc_hosts:
     hosts:
       game-container:
         ansible_host: 192.168.1.100
         ansible_user: root
   ```
3. **Schritt 3**: Führe das Playbook aus und teste:
   ```bash
   ansible-playbook -i inventory.yml zero_trust_iptables.yml
   # Teste Zugriff
   ssh root@192.168.1.100  # Sollte von 192.168.1.0/24 aus funktionieren
   curl http://192.168.1.100  # Sollte nur von your-ip funktionieren
   ```
4. **Schritt 4**: Überprüfe Logs mit `auditd`:
   ```bash
   apt install auditd
   echo "-w /var/log/lxc -p wa -k lxc-access" >> /etc/audit/audit.rules
   systemctl restart auditd
   ausearch -k lxc-access
   ```

**Reflexion**: Wie unterstützt `iptables` das Zero-Trust-Prinzip „Verifiziere immer“? Warum ist Netzwerksegmentierung wichtig?

### Übung 2: Kontinuierliche Überwachung mit rsyslog und Cloud-Integration
**Ziel**: Implementiere zentralisierte Logging für Zero Trust im HomeLab und verbinde mit AWS CloudWatch.

1. **Schritt 1**: Konfiguriere `rsyslog` im HomeLab (`rsyslog_setup.yml`):
   ```yaml
   - name: Konfiguriere rsyslog für Zero Trust
     hosts: lxc_hosts
     tasks:
       - name: Installiere rsyslog
         ansible.builtin.apt:
           name: rsyslog
           state: present
       - name: Konfiguriere rsyslog für CloudWatch
         ansible.builtin.copy:
           content: "*.* @your-log-server:514"
           dest: /etc/rsyslog.conf
           backup: yes
       - name: Starte rsyslog
         ansible.builtin.service:
           name: rsyslog
           state: restarted
   ```
2. **Schritt 2**: Erstelle Terraform für AWS CloudWatch Logs (`aws_cloudwatch.tf`):
   ```hcl
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_cloudwatch_log_group" "zero_trust_logs" {
     name              = "/zero-trust/homelab"
     retention_in_days = 365
   }
   ```
3. **Schritt 3**: Führe Ansible und Terraform aus:
   ```bash
   ansible-playbook -i inventory.yml rsyslog_setup.yml
   export AWS_ACCESS_KEY_ID=your-key
   export AWS_SECRET_ACCESS_KEY=your-secret
   terraform init && terraform apply -auto-approve
   # Simuliere Log-Eintrag
   logger "Zero Trust Test: Access Attempt"
   # Prüfe CloudWatch
   aws logs tail /zero-trust/homelab
   ```
4. **Schritt 4**: Integriere in GitHub Actions (siehe vorherige Anleitungen, erweitere für AWS-Credentials).

**Reflexion**: Wie gewährleistet zentralisiertes Logging die kontinuierliche Überwachung? Warum ist die Cloud-Integration für hybride Setups nützlich?

### Übung 3: Identitätsverifizierung mit SSH und VPN
**Ziel**: Implementiere Zero-Trust-Identitätsverifizierung im HomeLab und verbinde mit einer Cloud.

1. **Schritt 1**: Konfiguriere SSH mit Public-Key-Authentifizierung (`ssh_zero_trust.yml`):
   ```yaml
   - name: Zero Trust SSH-Konfiguration
     hosts: lxc_hosts
     tasks:
       - name: Installiere SSH
         ansible.builtin.apt:
           name: openssh-server
           state: present
       - name: Deaktiviere Passwort-Authentifizierung
         ansible.builtin.lineinfile:
           path: /etc/ssh/sshd_config
           regexp: '^PasswordAuthentication'
           line: 'PasswordAuthentication no'
       - name: Füge autorisierte Schlüssel hinzu
         ansible.builtin.copy:
           content: "your-ssh-public-key"
           dest: /root/.ssh/authorized_keys
           mode: '0600'
       - name: Starte SSH
         ansible.builtin.service:
           name: ssh
           state: restarted
   ```
2. **Schritt 2**: Konfiguriere WireGuard für VPN-Verbindung zum HomeLab (`wireguard_setup.yml`):
   ```yaml
   - name: Installiere und konfiguriere WireGuard
     hosts: lxc_hosts
     tasks:
       - name: Installiere WireGuard
         ansible.builtin.apt:
           name: wireguard
           state: present
       - name: Erstelle WireGuard-Konfiguration
         ansible.builtin.copy:
           content: |
             [Interface]
             PrivateKey = your-server-private-key
             Address = 10.0.0.1/24
             ListenPort = 51820
             [Peer]
             PublicKey = your-client-public-key
             AllowedIPs = 10.0.0.2/32
           dest: /etc/wireguard/wg0.conf
           mode: '0600'
       - name: Starte WireGuard
         ansible.builtin.command: wg-quick up wg0
   ```
3. **Schritt 3**: Führe die Playbooks aus und teste:
   ```bash
   ansible-playbook -i inventory.yml ssh_zero_trust.yml
   ansible-playbook -i inventory.yml wireguard_setup.yml
   # Teste SSH über VPN
   ssh -i your-key root@10.0.0.1
   ```
4. **Schritt 4**: Überprüfe Zugriffe mit `auditd`:
   ```bash
   ausearch -m USER_LOGIN -ts recent
   ```

**Reflexion**: Wie unterstützt Public-Key-Authentifizierung Zero Trust? Warum ist ein VPN für externe Zugriffe sicherer?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke Zugriffe auf spezifische IPs/Ports; vermeide breite Regeln wie `0.0.0.0/0`.
- **Monitoring**: Aktiviere `auditd` und `rsyslog` für Echtzeit-Logs; sende Logs an CloudWatch oder ähnliche Dienste.
- **Fehlerbehebung**: Prüfe `/var/log/syslog` und `ausearch` bei Zugriffsproblemen.
- **Best Practices**: Versioniere Ansible-Playbooks in Git, teste lokal vor CI/CD, nutze `ansible-lint`.
- **2025-Fokus**: Integriere Zero-Trust-Tools wie HashiCorp Boundary für erweiterte Identitätsverifizierung.

## Fazit
Du hast gelernt, Zero Trust im HomeLab mit `iptables`, `rsyslog` und SSH/VPN zu implementieren, um Netzwerksicherheit nach dem Prinzip „Verifiziere immer“ zu gewährleisten. Diese Übungen stärken die Sicherheit deines On-Prem-Setups und bereiten dich auf hybride Cloud-Integration vor. Wiederhole sie, um Konfigurationen zu verinnerlichen.

**Nächste Schritte**:
- Erkunde Tools wie HashiCorp Boundary oder OpenZiti für Zero Trust.
- Integriere hybride Verbindungen (z. B. AWS Direct Connect).
- Vertiefe dich in kontinuierliche Sicherheits-Checks mit `checkov`.

**Quellen**: Zero Trust Architecture NIST, Ansible Docs, WireGuard Docs, Debian Security Docs.
# Praxisorientierte Anleitung: Netzwerksicherheit mit Security Groups und NACLs

## Einführung
Netzwerksicherheit ist ein zentraler Bestandteil der Cloud- und Hybrid-Sicherheitsstrategie. Security Groups (SGs) und Network Access Control Lists (NACLs) steuern den Netzwerkverkehr in Multi-Cloud-Umgebungen (GCP, AWS, Azure) und hybriden Setups (z. B. Debian-HomeLab mit LXC). Diese Anleitung zeigt, wie man SGs und NACLs konfiguriert, um den Zugriff nach dem Least-Privilege-Prinzip zu beschränken und Angriffsflächen zu minimieren. Ziel ist es, dir praktische Übungen für sichere Netzwerkkonfigurationen in Cloud- und On-Prem-Systemen zu vermitteln.

Voraussetzungen:
- Zugang zu einem GCP-Projekt, AWS-Account, Azure-Abonnement und einem Debian-HomeLab (z. B. mit LXC-Containern).
- Installierte Tools: `terraform`, `gcloud`, `aws`, `az`, `iptables` (für On-Prem).
- Ein GitHub-Repository für CI/CD (z. B. GitHub Actions).
- Grundkenntnisse in Netzwerkkonzepten (z. B. Ports, IP-Bereiche, Ingress/Egress).
- Testumgebung für sichere Tests (keine Produktionsumgebung).

## Grundlegende Konzepte
Hier sind die wichtigsten Konzepte für SGs und NACLs:

1. **Security Groups (SGs)**:
   - **AWS**: Stateful, auf Instanz- oder Ressourcenebene, nur "Allow"-Regeln.
   - **Azure**: Network Security Groups (NSGs), stateful, auf Subnetz- oder NIC-Ebene.
   - **GCP**: Firewall-Regeln, stateful, auf VPC- oder Instanz-Ebene.
   - **Funktion**: Filtern Ingress/Egress-Verkehr basierend auf Protokoll, Port und IP.
2. **Network Access Control Lists (NACLs)**:
   - **AWS**: Stateless, auf Subnetz-Ebene, "Allow" und "Deny"-Regeln.
   - **Azure**: Kein direktes Äquivalent; NSGs übernehmen ähnliche Funktionen.
   - **GCP**: Kein direktes Äquivalent; VPC-Firewall-Regeln decken ähnliche Szenarien ab.
3. **On-Prem-Integration**:
   - Nutze `iptables` oder `nftables` für Netzwerkkontrolle in LXC-Containern.
   - Verbinde On-Prem mit Cloud via VPN oder Direct Connect.

## Übungen zum Verinnerlichen

### Übung 1: Security Groups in AWS konfigurieren
**Ziel**: Erstelle eine Security Group mit Least Privilege für eine EC2-Instance.

1. **Schritt 1**: Erstelle eine Terraform-Konfiguration für eine AWS Security Group (`aws_sg.tf`):
   ```hcl
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_security_group" "web_sg" {
     name        = "web-sg"
     description = "Allow HTTP and SSH with least privilege"
     vpc_id      = "your-vpc-id"

     ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["192.168.1.0/24"]  # Begrenze auf vertrautes Netzwerk
     }

     ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["your-ip/32"]  # Nur deine IP
     }

     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]  # Egress für Updates
     }
   }

   resource "aws_instance" "web" {
     ami           = "ami-0c55b159cbfafe1f0"  # Beispiel AMI
     instance_type = "t2.micro"
     vpc_security_group_ids = [aws_security_group.web_sg.id]
   }
   ```
2. **Schritt 2**: Erstelle eine GitHub Actions Workflow-Datei (`.github/workflows/aws-sg.yml`):
   ```yaml
   name: Deploy AWS Security Group
   on:
     push:
       branches: [ main ]
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       - uses: hashicorp/setup-terraform@v3
         with:
           terraform_version: 1.9.0
       - uses: aws-actions/configure-aws-credentials@v4
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-east-1
       - run: |
           terraform init
           terraform plan -out=tfplan
           terraform apply tfplan
   ```
3. **Schritt 3**: Füge AWS-Credentials als GitHub Secrets hinzu: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
4. **Schritt 4**: Pushe die Änderungen, überprüfe die Pipeline und teste:
   ```bash
   # Lokal testen
   export AWS_ACCESS_KEY_ID=your-key
   export AWS_SECRET_ACCESS_KEY=your-secret
   terraform init && terraform apply -auto-approve
   curl http://<ec2-public-ip>  # Sollte funktionieren
   ssh -i key.pem ec2-user@<ec2-public-ip>  # Sollte funktionieren
   ```

**Reflexion**: Warum ist es wichtig, Ingress auf spezifische IPs zu beschränken? Wie unterscheiden sich SGs von NACLs?

### Übung 2: NACLs in AWS und Firewall-Regeln in GCP konfigurieren
**Ziel**: Konfiguriere NACLs und GCP Firewall-Regeln für Subnetz-Sicherheit.

1. **Schritt 1**: Erstelle Terraform für AWS NACL und GCP Firewall (`aws_nacl_gcp_fw.tf`):
   ```hcl
   # AWS NACL
   provider "aws" {
     region = "us-east-1"
   }

   resource "aws_network_acl" "main" {
     vpc_id = "your-vpc-id"
     subnet_ids = ["your-subnet-id"]

     ingress {
       protocol   = "tcp"
       rule_no    = 100
       action     = "allow"
       cidr_block = "192.168.1.0/24"
       from_port  = 80
       to_port    = 80
     }

     ingress {
       protocol   = "tcp"
       rule_no    = 110
       action     = "allow"
       cidr_block = "your-ip/32"
       from_port  = 22
       to_port    = 22
     }

     egress {
       protocol   = "-1"
       rule_no    = 100
       action     = "allow"
       cidr_block = "0.0.0.0/0"
       from_port  = 0
       to_port    = 0
     }
   }

   # GCP Firewall
   provider "google" {
     project = "your-project-id"
     credentials = file("gcp-sa-key.json")
   }

   resource "google_compute_firewall" "web_fw" {
     name    = "web-fw"
     network = "default"
     allow {
       protocol = "tcp"
       ports    = ["80", "22"]
     }
     source_ranges = ["192.168.1.0/24", "your-ip/32"]
     target_tags   = ["web"]
   }
   ```
2. **Schritt 2**: Integriere in GitHub Actions (siehe Übung 1, erweitere für GCP mit `GCP_SA_KEY`).
3. **Schritt 3**: Pushe und teste:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS=gcp-sa-key.json
   terraform init && terraform apply -auto-approve
   # Teste AWS
   curl http://<aws-public-ip>
   # Teste GCP
   gcloud compute ssh web-instance --project=your-project-id
   ```
4. **Schritt 4**: Überprüfe Logs in CloudTrail (AWS) oder VPC Flow Logs (GCP).

**Reflexion**: Warum sind NACLs stateless? Wie ergänzen sie SGs in AWS?

### Übung 3: Hybrid-Setup mit On-Prem iptables
**Ziel**: Konfiguriere Netzwerksicherheit für LXC-Container im HomeLab und verbinde mit Cloud.

1. **Schritt 1**: Erstelle ein Ansible-Playbook für iptables in LXC (`iptables_lxc.yml`):
   ```yaml
   - name: Konfiguriere iptables für LXC
     hosts: lxc_hosts
     tasks:
       - name: Installiere iptables
         ansible.builtin.apt:
           name: iptables
           state: present
           update_cache: yes
       - name: Setze HTTP- und SSH-Regeln
         ansible.builtin.iptables:
           chain: INPUT
           protocol: tcp
           destination_port: "{{ item }}"
           source: "192.168.1.0/24"
           jump: ACCEPT
         loop: [80, 22]
       - name: Droppe anderen eingehenden Traffic
         ansible.builtin.iptables:
           chain: INPUT
           jump: DROP
       - name: Speichere iptables-Regeln
         ansible.builtin.command: iptables-save > /etc/iptables/rules.v4
   ```
2. **Schritt 2**: Erstelle ein Inventory für LXC-Container (`inventory.yml`):
   ```yaml
   lxc_hosts:
     hosts:
       game-container:
         ansible_host: 192.168.1.100
         ansible_user: root
   ```
3. **Schritt 3**: Führe das Playbook aus:
   ```bash
   ansible-playbook -i inventory.yml iptables_lxc.yml
   # Teste lokal
   curl http://192.168.1.100
   ssh root@192.168.1.100
   ```
4. **Schritt 4**: Verbinde On-Prem mit Cloud (z. B. AWS VPN):
   ```bash
   aws ec2 create-vpn-connection --type ipsec.1 --customer-gateway-id cgw-xxx --vpn-gateway-id vgw-xxx
   ```

**Reflexion**: Wie verbessert iptables die Sicherheit in LXC? Warum ist eine VPN-Verbindung für Hybrid-Setups wichtig?

## Tipps für den Erfolg
- **Least Privilege**: Beschränke Ingress auf minimale IPs/Ports; vermeide `0.0.0.0/0` für sensible Dienste.
- **Monitoring**: Aktiviere VPC Flow Logs (AWS/GCP), NSG Flow Logs (Azure) und `rsyslog` (On-Prem).
- **Fehlerbehebung**: Prüfe Logs (`/var/log/syslog`, CloudTrail) bei Zugriffsproblemen.
- **Best Practices**: Versioniere Konfigurationen in Git, teste lokal vor CI/CD, nutze `tflint` oder `ansible-lint`.
- **2025-Fokus**: Achte auf Zero Trust-Modelle und automatisierte Netzwerksicherheits-Checks.

## Fazit
Du hast gelernt, Security Groups und NACLs in AWS, GCP, Azure und On-Prem-LXC zu konfigurieren, um Netzwerksicherheit nach Least-Privilege-Prinzipien zu gewährleisten. Diese Übungen stärken deine Multi-Cloud- und Hybrid-Sicherheit. Wiederhole sie in Testumgebungen, um Konfigurationen zu verinnerlichen.

**Nächste Schritte**:
- Erkunde Zero Trust mit Tools wie AWS Network Firewall oder Azure Firewall.
- Integriere Sicherheits-Checks mit `checkov` für Netzwerkkonfigurationen.
- Vertiefe dich in VPN- oder Direct-Connect-Setups für Hybrid-Umgebungen.

**Quellen**: AWS VPC Docs, Azure NSG Docs, GCP Firewall Docs, Ansible Docs.
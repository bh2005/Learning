## Modul 12: Automatisierung mit APIs

Willkommen zu diesem optionalen, aber wichtigen Modul. Sie haben bisher gelernt, Ihre Netzwerkinfrastruktur über die Proxmox-Web-GUI zu konfigurieren. In professionellen Umgebungen werden viele dieser Aufgaben jedoch automatisiert. In diesem Modul lernen Sie, wie Sie Proxmox SDN-Funktionen über die robuste API steuern, um die Bereitstellung und Verwaltung zu beschleunigen.

-----

### Theoretische Grundlagen

#### Was ist eine API und warum automatisieren?

Eine **API** (Application Programming Interface) ermöglicht es Ihnen, mit einer Software zu interagieren, ohne die Benutzeroberfläche zu verwenden. Die Proxmox-API ist **RESTful**, was bedeutet, dass sie standardmäßige Web-Protokolle (HTTP-Anfragen) verwendet. Sie können `GET`-Anfragen senden, um Informationen abzurufen, oder `POST`/`PUT`-Anfragen, um Änderungen vorzunehmen.

Die Hauptvorteile der Automatisierung mit der API sind:

  * **Effizienz:** Erstellen Sie Skripte, die wiederkehrende Aufgaben in Sekunden erledigen.
  * **Konsistenz:** Skripte führen die gleichen Schritte jedes Mal auf die exakt gleiche Weise aus, was menschliche Fehler reduziert.
  * **Skalierbarkeit:** Verwalten Sie Hunderte von VMs und Netzwerken, ohne dass eine manuelle Konfiguration zu einem Engpass wird.

#### API-Authentifizierung

Aus Sicherheitsgründen müssen Sie sich bei der API authentifizieren. Die gebräuchlichste und sicherste Methode für Skripte ist die Verwendung von **API-Tokens**. Ein API-Token ist eine lange, zufällige Zeichenkette, die an einen Benutzer gebunden ist und Zugriffsrechte für die API gewährt. Sie können diese Tokens in der Proxmox-GUI unter `Datacenter` -\> `Berechtigungen` -\> `API Tokens` erstellen.

-----

### Praktische Übungen

**Ziel:** Erstellen Sie ein Python-Skript, das ein VNet über die Proxmox-API erstellt.

#### Übung 1: Vorbereitung der Umgebung und Authentifizierung

1.  **Python installieren:** Stellen Sie sicher, dass Python auf dem Rechner installiert ist, von dem Sie das Skript ausführen möchten.
2.  **API-Bibliothek installieren:** Wir verwenden die `proxmoxer`-Bibliothek, die die Arbeit mit der API vereinfacht.
    ```bash
    pip install proxmoxer
    ```
3.  **API-Token erstellen:** Erstellen Sie in der Proxmox-GUI einen API-Token für einen Benutzer (z. B. `root@pam`). Notieren Sie sich die Token-ID und den Secret-Wert, da sie nur einmal angezeigt werden.

#### Übung 2: Erstellen eines VNets mit Python

Kopieren Sie den folgenden Code in eine Datei namens `create_vnet.py` und passen Sie die Platzhalter (`<your_proxmox_host>`, `<your_api_token_id>`, `<your_api_token_secret>`) an.

```python
import sys
from proxmoxer import ProxmoxAPI

# Verbindungsparameter
# Ersetzen Sie die Platzhalter mit Ihren tatsächlichen Werten
PROXMOX_HOST = '<your_proxmox_host>'
API_USER = 'root@pam'
API_TOKEN_ID = '<your_api_token_id>'
API_TOKEN_SECRET = '<your_api_token_secret>'
PROXMOX_PORT = 8006

# Ziel-VNet-Konfiguration
VNET_NAME = 'vnet-api-01'
VNET_ZONE = 'private-zone' # Verwenden Sie die Zone aus Modul 3
VLAN_TAG = 40
CIDR = '10.40.1.0/24'
GATEWAY = '10.40.1.1'

print("Verbinde mit Proxmox API...")
try:
    # Authentifizierung mit dem API-Token
    proxmox_api = ProxmoxAPI(
        host=PROXMOX_HOST,
        user=API_USER,
        token_id=API_TOKEN_ID,
        token_secret=API_TOKEN_SECRET,
        port=PROXMOX_PORT,
        verify_ssl=False # Setzen Sie dies für die Produktion auf True
    )

    # Erstelle das VNet mit einem POST-Request an den SDN-Endpunkt
    print(f"Erstelle VNet '{VNET_NAME}'...")
    proxmox_api.cluster.sdn.vnets.post(
        vnet=VNET_NAME,
        zone=VNET_ZONE,
        tag=VLAN_TAG,
        cidr=CIDR,
        gateway=GATEWAY
    )

    print(f"VNet '{VNET_NAME}' erfolgreich erstellt.")

except Exception as e:
    print(f"Ein Fehler ist aufgetreten: {e}")
    sys.exit(1)
```

#### Übung 3: Ausführen des Skripts und Validierung

1.  **Skript ausführen:** Führen Sie das Skript von Ihrer Kommandozeile aus.
    ```bash
    python create_vnet.py
    ```
2.  **Validieren:** Melden Sie sich in der Proxmox-GUI an und navigieren Sie zu `Datacenter` -\> `SDN` -\> **VNets**. Sie sollten das neu erstellte VNet mit dem Namen `vnet-api-01` sehen.

#### Fragen zur Selbstreflexion:

  * Was ist der Hauptvorteil der Verwendung eines Skripts gegenüber der manuellen Konfiguration in der GUI, wenn Sie zehn ähnliche VNets erstellen müssen?
  * Warum ist die Verwendung von API-Tokens in Skripten sicherer als die Speicherung Ihres Benutzernamens und Passworts?
  * Welchen Endpunkt (`proxmox_api.cluster.sdn...`) müssten Sie ansprechen, um stattdessen einen IP-Pool zu erstellen?

Mit diesem Modul sind Sie in der Lage, die volle Automatisierungskraft der Proxmox-API zu nutzen und die SDN-Verwaltung auf ein neues Niveau zu heben.

**[zurück zur Übersicht](00_Übersicht_SDN.md)**
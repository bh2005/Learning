### Python Regex-Spickzettel für Netzwerkanwendungen 🐍

Reguläre Ausdrücke (Regex) sind ein mächtiges Werkzeug, um Textmuster zu finden und zu verarbeiten. In Python wird dies durch das eingebaute **`re`**-Modul ermöglicht. Dieser Spickzettel hilft dir dabei, gängige Netzwerkdaten zu extrahieren und zu validieren.

-----

### 1\. Grundlegende Regex-Syntax

| Zeichen | Bedeutung | Beispiel |
| :--- | :--- | :--- |
| `.` | Beliebiges Zeichen (außer Zeilenumbruch) | `a.b` matcht "acb", "a3b" |
| `*` | Null oder mehr Vorkommen | `a*` matcht "", "a", "aa" |
| `+` | Ein oder mehr Vorkommen | `a+` matcht "a", "aa" |
| `?` | Null oder ein Vorkommen | `a?` matcht "a", "" |
| `[]` | Zeichengruppe | `[abc]` matcht "a", "b", "c" |
| `()` | Gruppierung (zum Extrahieren) | `(abc)+` matcht "abc", "abcabc" |
| `^` | Start des Strings | `^Hallo` matcht "Hallo Welt" |
| `$` | Ende des Strings | `Welt$` matcht "Hallo Welt" |
| `\|` | ODER-Verknüpfung | `(a\|b)` matcht "a" oder "b" |

**Spezialsequenzen:**

  * `\d`: Ziffer (0-9)
  * `\D`: Keine Ziffer
  * `\w`: Wortzeichen (Buchstabe, Zahl, Unterstrich)
  * `\W`: Kein Wortzeichen
  * `\s`: Leerraum (Leerzeichen, Tabulator, Zeilenumbruch)
  * `\S`: Kein Leerraum

-----

### 2\. Die wichtigsten `re`-Funktionen in Python

| Funktion | Verwendung |
| :--- | :--- |
| **`re.search(pattern, string)`** | Sucht nach der ersten Stelle, an der das Muster im String passt. Gibt ein Match-Objekt zurück, sonst `None`. |
| **`re.match(pattern, string)`** | Prüft, ob das Muster am **Anfang** des Strings passt. Ist restriktiver als `re.search()`. |
| **`re.findall(pattern, string)`** | Findet **alle** nicht überlappenden Treffer des Musters im String und gibt sie als Liste zurück. |
| **`re.sub(pattern, repl, string)`** | Ersetzt alle Vorkommen des Musters im String durch eine Ersatzzeichenkette (`repl`). |

-----

### 3\. Regex-Muster für Netzwerkanwendungen

```python
import re

# Muster für IPv4-Adressen
# Matcht 0.0.0.0 bis 255.255.255.255
ipv4_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'

# Muster für MAC-Adressen
# Matcht Formate wie AA:BB:CC:11:22:33 oder AA-BB-CC-11-22-33
mac_pattern = r'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})'

# Muster für Portnummern
# Matcht Zahlen von 1 bis 65535
port_pattern = r'\b(6553[0-5]|655[0-2][0-9]|65[0-4][0-9]{2}|6[0-4][0-9]{3}|[1-5][0-9]{4}|[1-9][0-9]{1,3}|[0-9])\b'

# Muster für eine URL (vereinfacht)
# Matcht http(s)://...
url_pattern = r'https?:\/\/(?:www\.)?[\w\.-]+\.[\w]{2,6}(?:\/[\w\.-]*)*\/?'

# Muster für IPv6-Adressen (einfache Form, ohne erweiterte Kürzungen)
# Matcht 1234:5678:90ab:cdef:1234:5678:90ab:cdef
ipv6_pattern = r'(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4})'

# Muster für eine E-Mail-Adresse (vereinfacht)
# Matcht gängige Formate wie 'user.name@sub.domain.tld'
# Ist nicht für alle RFC-Spezifikationen ausgelegt
email_pattern = r'[\w\.-]+@[\w\.-]+\.\w+'

# Muster für einen DNS-Hostnamen ohne Domäne
# Extrahiert den Hostnamen aus einem FQDN (Fully Qualified Domain Name)
# Matcht 'server1' in 'server1.meinefirma.local'
hostname_pattern = r'^(?P<hostname>[\w-]+)\.'

# Muster für eine DNS-Domäne
# Extrahiert die Domäne aus einem FQDN
# Matcht 'meinefirma.local' in 'server1.meinefirma.local'
domain_pattern = r'[\w-]+\.(?P<domain>[\w-]+\.\w+)$'

# Muster für eine URL nur mit Domäne
# Extrahiert die Domäne aus einer kompletten URL
# Matcht 'google.com' in 'https://www.google.com/search'
url_domain_pattern = r'https?:\/\/(?:www\.)?(?P<domain>[\w-]+\.\w+)'
```

-----

### 4\. Praktisches Anwendungsbeispiel

Stellen Sie sich vor, Sie haben eine Log-Datei und möchten alle IPv4-Adressen und Portnummern extrahieren.

```python
import re

log_data = """
[INFO] Connection from 192.168.1.10 on port 8080.
[ERROR] Failed login attempt from 10.0.0.5:22.
[DEBUG] Scanning host 203.0.113.1 for open ports...
"""

# Pattern für IP-Adresse und Port
ip_pattern = r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
port_pattern = r'\b(\d{1,5})\b'

# Suchen nach allen IP-Adressen
ips_found = re.findall(ip_pattern, log_data)
print(f"Gefundene IP-Adressen: {ips_found}")

# Suchen nach allen Portnummern
ports_found = re.findall(port_pattern, log_data)
# Filtern, um nur gültige Ports (1-65535) zu erhalten
valid_ports = [port for port in ports_found if 0 < int(port) <= 65535]
print(f"Gefundene Portnummern: {valid_ports}")
```

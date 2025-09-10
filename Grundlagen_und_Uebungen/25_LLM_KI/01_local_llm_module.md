# Lernprojekt: Lokale LLMs für Programmierunterstützung, Dokumentenanalyse und Textgenerierung

## Einführung

**Large Language Models (LLMs)** wie Code Llama oder Llama 3.1 können lokal auf einer HomeLab-VM betrieben werden, um Aufgaben wie Programmierunterstützung, Dokumentenanalyse und kreative Textgenerierung zu ermöglichen. Dieses Lernprojekt nutzt **Ollama**, eine Open-Source-Plattform für lokale LLMs, und **Llama 3.1 (8B)**, ein effizientes Modell für CPUs. Es ist für Lernende mit Grundkenntnissen in Linux, Python und Docker geeignet und läuft auf einer lokalen VM (Proxmox VE) in einer HomeLab-Umgebung mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Das Projekt umfasst drei Übungen: Einrichtung eines Programmier-Assistenten mit Code Llama, Implementierung eines Chatbots für Dokumentenanalyse (PDFs) und Erstellung eines Tools für kreative Textgenerierung (z. B. E-Mails). Es integriert die HomeLab-Infrastruktur und vermeidet Cloud-Abhängigkeiten, um Datenschutz zu gewährleisten.

**Voraussetzungen**:
- Proxmox VE-Server (z. B. Version 8.x) in der HomeLab, erreichbar unter `192.168.30.10`.
- Ubuntu 22.04 VM auf Proxmox (z. B. ID 101, IP `192.168.30.101`), wie in `terraform_ansible_local_module.md`.
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher (für Llama 3.1 8B).
- Grundkenntnisse in Linux (z. B. `bash`, `nano`), Python und Docker.
- HomeLab mit TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement.
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub` und `~/.ssh/id_rsa`).
- Internetzugang für initiale Downloads (Ollama, Llama-Modelle).
- Beispiel-PDF-Datei für Dokumentenanalyse (z. B. `sample.pdf`).

**Ziele**:
- Einrichten eines Programmier-Assistenten mit Code Llama für Codegenerierung.
- Implementieren eines Chatbots für lokale Dokumentenanalyse (PDFs).
- Erstellen eines Tools für kreative Textgenerierung (z. B. E-Mails, Blog-Posts).
- Integration mit HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Das Projekt ist lokal und kostenlos, nutzt Open-Source-Tools und schützt die Privatsphäre, da keine Daten an externe Dienste gesendet werden.

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Webquellen:,,,,,[](https://t3n.de/news/ollama-lokale-ki-llama-deepseek-1701112/)[](https://pcwelts.de/ollama/)[](https://robert-leitinger.com/llm-lokal-nutzen-lm-studio/)

## Lernprojekt: Lokale LLMs mit Ollama

### Vorbereitung: VM und Umgebung einrichten
1. **Ubuntu-VM prüfen**:
   - Stelle sicher, dass eine Ubuntu 22.04 VM (z. B. `ansible-vm`, ID 101, IP `192.168.30.101`) auf Proxmox läuft, wie in `terraform_ansible_local_module.md` erstellt.
   - Verbinde dich:
     ```bash
     ssh ubuntu@192.168.30.101
     ```
2. **Docker installieren** (für Ollama):
   ```bash
   sudo apt update
   sudo apt install -y docker.io
   sudo systemctl enable docker
   sudo systemctl start docker
   sudo usermod -aG docker ubuntu
   ```
   - Melde dich ab und erneut an, um die Docker-Gruppe anzuwenden:
     ```bash
     exit
     ssh ubuntu@192.168.30.101
     ```
3. **Ollama installieren**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   sudo systemctl enable ollama
   sudo systemctl start ollama
   ollama --version  # Erwartet: ollama version 0.x.x
   ```
4. **Projektverzeichnis erstellen**:
   ```bash
   mkdir ~/llm-project
   cd ~/llm-project
   ```

**Tipp**: Arbeite auf der Ubuntu-VM (`192.168.30.101`) mit Zugriff auf den Proxmox-Server und TrueNAS.

### Übung 1: Programmier-Assistent mit Code Llama

**Ziel**: Einrichten eines Programmier-Assistenten mit Code Llama für Codegenerierung.

**Aufgabe**: Installiere Code Llama via Ollama und erstelle ein Python-Skript, das Code generiert.

1. **Code Llama installieren**:
   ```bash
   ollama pull codellama:7b
   ```
   - **Hinweis**: Code Llama 7B benötigt ~4 GB Speicher. Prüfe mit `free -h` und `df -h`, ob ausreichend Ressourcen vorhanden sind.

2. **Python-Skript für Codegenerierung erstellen**:
   ```bash
   nano code_assistant.py
   ```
   - Inhalt:
     ```python
     import requests
     import json

     def generate_code(prompt):
         url = "http://localhost:11434/api/generate"
         payload = {
             "model": "codellama:7b",
             "prompt": prompt,
             "stream": False
         }
         response = requests.post(url, json=payload)
         if response.status_code == 200:
             return json.loads(response.text)["response"]
         else:
             return f"Fehler: {response.status_code}"

     if __name__ == "__main__":
         prompt = "Erstelle ein Python-Skript, das die Fibonacci-Folge bis n=10 generiert."
         result = generate_code(prompt)
         print(result)
     ```
   - **Erklärung**:
     - Nutzt die Ollama-API (`http://localhost:11434`) zur Interaktion mit Code Llama.
     - Sendet einen Prompt und gibt den generierten Code aus.

3. **Skript ausführen**:
   ```bash
   python3 code_assistant.py
   ```
   - Erwartete Ausgabe (Beispiel):
     ```python
     def fibonacci(n):
         fib = [0, 1]
         for i in range(2, n):
             fib.append(fib[i-1] + fib[i-2])
         return fib

     print(fibonacci(10))
     # Output: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
     ```

4. **Code testen**:
   - Speichere den generierten Code:
     ```bash
     echo -e 'def fibonacci(n):\n    fib = [0, 1]\n    for i in range(2, n):\n        fib.append(fib[i-1] + fib[i-2])\n    return fib\n\nprint(fibonacci(10))' > fib.py
     python3 fib.py
     ```
   - Erwartete Ausgabe:
     ```
     [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
     ```

**Erkenntnis**: Code Llama kann lokal auf einer VM Code generieren, ohne Internetverbindung nach der Installation. Die Ollama-API ermöglicht einfache Integration in Python-Skripte.[](https://towardsai.net/p/data-science/how-to-build-your-own-llm-coding-assistant-with-code-llama)

### Übung 2: Chatbot für Dokumentenanalyse

**Ziel**: Implementieren eines Chatbots, der lokale PDFs analysiert und Fragen beantwortet.

**Aufgabe**: Installiere Llama 3.1, lade ein Beispiel-PDF und erstelle ein Python-Skript für die Dokumentenanalyse.

1. **Llama 3.1 installieren**:
   ```bash
   ollama pull llama3.1:8b
   ```
   - **Hinweis**: Llama 3.1 8B benötigt ~5 GB Speicher. Prüfe Ressourcen mit `free -h` und `df -h`.

2. **Abhängigkeiten für PDF-Verarbeitung installieren**:
   ```bash
   sudo apt install -y python3-pip
   pip3 install PyPDF2
   ```

3. **Beispiel-PDF erstellen**:
   ```bash
   nano sample.pdf
   ```
   - **Hinweis**: Für dieses Beispiel nehmen wir an, dass ein PDF (z. B. `sample.pdf`) vorhanden ist. Alternativ erstelle eine Textdatei und konvertiere sie:
     ```bash
     echo -e "# Testdokument\nDies ist ein Beispiel-PDF für die Dokumentenanalyse.\nInhalt: Lokale LLMs sind datenschutzfreundlich und laufen offline." > sample.txt
     sudo apt install -y pandoc
     pandoc sample.txt -o sample.pdf
     ```

4. **Python-Skript für Dokumentenanalyse erstellen**:
   ```bash
   nano document_analyzer.py
   ```
   - Inhalt:
     ```python
     import PyPDF2
     import requests
     import json

     def extract_text_from_pdf(pdf_path):
         with open(pdf_path, 'rb') as file:
             reader = PyPDF2.PdfReader(file)
             text = ""
             for page in reader.pages:
                 text += page.extract_text() + "\n"
             return text

     def query_document(prompt, document_text):
         url = "http://localhost:11434/api/generate"
         full_prompt = f"Dokument: {document_text}\nFrage: {prompt}"
         payload = {
             "model": "llama3.1:8b",
             "prompt": full_prompt,
             "stream": False
         }
         response = requests.post(url, json=payload)
         if response.status_code == 200:
             return json.loads(response.text)["response"]
         else:
             return f"Fehler: {response.status_code}"

     if __name__ == "__main__":
         pdf_path = "sample.pdf"
         document_text = extract_text_from_pdf(pdf_path)
         question = "Was sind die Vorteile von lokalen LLMs laut dem Dokument?"
         answer = query_document(question, document_text)
         print(answer)
     ```
   - **Erklärung**:
     - `PyPDF2`: Extrahiert Text aus dem PDF.
     - `query_document`: Sendet den PDF-Text und eine Frage an Llama 3.1 via Ollama-API.

5. **Skript ausführen**:
   ```bash
   python3 document_analyzer.py
   ```
   - Erwartete Ausgabe (Beispiel):
     ```
     Lokale LLMs sind datenschutzfreundlich und können offline betrieben werden.
     ```

**Erkenntnis**: Llama 3.1 ermöglicht lokale Dokumentenanalyse, indem es PDF-Inhalte verarbeitet und Fragen dazu beantwortet. Dies ist ideal für Forschung oder Wissensverwaltung ohne Cloud-Abhängigkeit.[](https://www.golan.ai/de/ai-news/entfesseln-sie-die-private-ki-kraft-auf-ihrem-pc-lokale-chatbot-einrichtung-einfach-gemacht-8AOAARhf1ds)

### Übung 3: Kreative Textgenerierung

**Ziel**: Erstellen eines Tools für kreative Textgenerierung (z. B. E-Mails).

**Aufgabe**: Nutze Llama 3.1, um ein Python-Skript zu erstellen, das E-Mails oder Blog-Posts generiert.

1. **Python-Skript für Textgenerierung erstellen**:
   ```bash
   nano text_generator.py
   ```
   - Inhalt:
     ```python
     import requests
     import json

     def generate_text(prompt):
         url = "http://localhost:11434/api/generate"
         payload = {
             "model": "llama3.1:8b",
             "prompt": prompt,
             "stream": False
         }
         response = requests.post(url, json=payload)
         if response.status_code == 200:
             return json.loads(response.text)["response"]
         else:
             return f"Fehler: {response.status_code}"

     if __name__ == "__main__":
         prompt = "Schreibe eine professionelle E-Mail, um einen Termin für ein Projektmeeting zu vereinbaren."
         result = generate_text(prompt)
         print(result)
     ```
   - **Erklärung**:
     - Sendet einen Prompt an Llama 3.1, um kreativen Text (z. B. E-Mail) zu generieren.

2. **Skript ausführen**:
   ```bash
   python3 text_generator.py
   ```
   - Erwartete Ausgabe (Beispiel):
     ```
     Betreff: Terminvereinbarung für Projektmeeting

     Sehr geehrte/r [Name],

     ich hoffe, es geht Ihnen gut. Ich möchte Sie herzlich zu einem Projektmeeting einladen, um die nächsten Schritte für unser Projekt zu besprechen.

     Vorschlag: 
     - Datum: 15. September 2025
     - Uhrzeit: 10:00 Uhr
     - Ort: Online (Zoom-Link wird bereitgestellt)

     Bitte lassen Sie mich wissen, ob der vorgeschlagene Termin für Sie passt oder ob wir einen alternativen Zeitpunkt finden sollten.

     Mit freundlichen Grüßen,
     [Dein Name]
     ```

3. **Text speichern**:
   ```bash
   python3 text_generator.py > email.txt
   nano email.txt
   ```
   - Bearbeite den Text für den tatsächlichen Gebrauch.

**Erkenntnis**: Llama 3.1 eignet sich hervorragend für kreative Textgenerierung, wie E-Mails oder Blog-Posts, ohne dass Daten an externe Dienste gesendet werden.[](https://www.golan.ai/de/ai-news/entfesseln-sie-die-private-ki-kraft-auf-ihrem-pc-lokale-chatbot-einrichtung-einfach-gemacht-8AOAARhf1ds)

### Schritt 4: Integration mit HomeLab
1. **Konfigurationen auf TrueNAS sichern**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/llm-project-backup-$(date +%F).tar.gz ~/llm-project
     rsync -av ~/llm-project-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/llm/
     ```
   - Automatisiere:
     ```bash
     nano /home/ubuntu/backup.sh
     ```
     - Inhalt (am Ende hinzufügen):
       ```bash
       DATE=$(date +%F)
       tar -czf /home/ubuntu/llm-project-backup-$DATE.tar.gz ~/llm-project
       rsync -av /home/ubuntu/llm-project-backup-$DATE.tar.gz root@192.168.30.100:/mnt/tank/backups/llm/
       ```
     - Ausführbar machen:
       ```bash
       chmod +x /home/ubuntu/backup.sh
       ```
2. **Wiederherstellung testen**:
   - Lade das Backup herunter:
     ```bash
     rsync -av root@192.168.30.100:/mnt/tank/backups/llm/llm-project-backup-2025-09-09.tar.gz /home/ubuntu/
     tar -xzf /home/ubuntu/llm-project-backup-2025-09-09.tar.gz -C ~/
     ```
   - Teste die Skripte:
     ```bash
     cd ~/llm-project
     python3 code_assistant.py
     ```

3. **Netzwerkmanagement mit OPNsense**:
   - Füge eine Firewall-Regel in OPNsense hinzu, um HTTP-Zugriff auf die VM (`192.168.30.101:80`) von `192.168.30.0/24` zu erlauben (falls Apache installiert ist).
   - Beispiel-Regel:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Port: `80`
     - Aktion: `Allow`

### Schritt 5: Erweiterung der Übungen
1. **Dokumentenanalyse mit Embeddings**:
   - Installiere `sentence-transformers` für lokale Embeddings:
     ```bash
     pip3 install sentence-transformers
     ```
   - Erstelle ein Skript für semantische Suche:
     ```bash
     nano semantic_search.py
     ```
     - Inhalt:
       ```python
       from sentence_transformers import SentenceTransformer
       import PyPDF2

       model = SentenceTransformer('all-MiniLM-L6-v2')

       def extract_text_from_pdf(pdf_path):
           with open(pdf_path, 'rb') as file:
               reader = PyPDF2.PdfReader(file)
               return [page.extract_text() for page in reader.pages]

       def semantic_search(query, document_pages):
           query_embedding = model.encode(query)
           page_embeddings = model.encode(document_pages)
           similarities = model.similarity(query_embedding, page_embeddings)[0]
           best_page_idx = similarities.argmax()
           return document_pages[best_page_idx], similarities[best_page_idx]

       if __name__ == "__main__":
           pdf_path = "sample.pdf"
           query = "Vorteile von lokalen LLMs"
           pages = extract_text_from_pdf(pdf_path)
           best_page, score = semantic_search(query, pages)
           print(f"Beste Übereinstimmung (Score: {score:.2f}):\n{best_page}")
       ```
   - Führe aus:
     ```bash
     python3 semantic_search.py
     ```

2. **Interaktive CLI für Textgenerierung**:
   - Erstelle ein interaktives Skript:
     ```bash
     nano interactive_text_generator.py
     ```
     - Inhalt:
       ```python
       import requests
       import json

       def generate_text(prompt):
           url = "http://localhost:11434/api/generate"
           payload = {
               "model": "llama3.1:8b",
               "prompt": prompt,
               "stream": False
           }
           response = requests.post(url, json=payload)
           if response.status_code == 200:
               return json.loads(response.text)["response"]
           else:
               return f"Fehler: {response.status_code}"

       if __name__ == "__main__":
           while True:
               prompt = input("Prompt (oder 'exit' zum Beenden): ")
               if prompt.lower() == 'exit':
                   break
               result = generate_text(prompt)
               print(result)
               print("-" * 50)
       ```
   - Führe aus:
     ```bash
     python3 interactive_text_generator.py
     ```

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Überwache RAM und Speicher:
    ```bash
    free -h
    df -h
    ```
  - Begrenze Ollama-Ressourcen in `docker run` (falls nötig):
    ```bash
    docker run -d --memory="6g" --cpus="4" -v ollama:/root/.ollama -p 11434:11434 ollama/ollama
    ```
- **Sicherheit**:
  - Schränke Zugriff auf Ollama-API ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 11434
    ```
  - Sichere SSH-Schlüssel:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Implementiere die 3-2-1-Regel:
    - 3 Kopien: Lokale Dateien, TrueNAS, zusätzliche Kopie (z. B. USB).
    - 2 Medien: Lokale Festplatte, TrueNAS HDD.
    - 1 Off-Site: TrueNAS (simuliert Off-Site in HomeLab).
- **Fehlerbehebung**:
  - Prüfe Ollama-Logs:
    ```bash
    docker logs $(docker ps -q -f ancestor=ollama/ollama)
    ```
  - Teste API-Verbindung:
    ```bash
    curl http://localhost:11434
    ```

**Quelle**: https://ollama.com/docs,[](https://t3n.de/news/ollama-lokale-ki-llama-deepseek-1701112/)

## Empfehlungen für Schüler

- **Setup**:
  - **Ollama**: Llama 3.1 (8B), Code Llama (7B).
  - **Workloads**: Codegenerierung, Dokumentenanalyse, Textgenerierung.
  - **HomeLab**: Backups auf TrueNAS (`/mnt/tank/backups/llm`).
- **Integration**:
  - Proxmox: Ubuntu-VM für LLM-Ausführung.
  - TrueNAS: Sichere Skripte und PDFs.
  - OPNsense: Netzwerkzugriff auf VM kontrollieren.
- **Beispiel**:
  - Programmier-Assistent: Fibonacci-Skript.
  - Chatbot: PDF-Analyse.
  - Textgenerierung: E-Mail-Vorlage.

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit kleinen Prompts und erweitere schrittweise.
- **Übung**: Experimentiere mit anderen Modellen (z. B. `mistral`, `deepseek-coder`) via `ollama pull`.
- **Fehlerbehebung**: Nutze `curl` für API-Tests und `docker logs` für Debugging.
- **Lernressourcen**: Nutze https://ollama.com/docs, https://github.com/meta-ai/llama, und https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`) für Referenz.

## Fazit

Dieses Lernprojekt bietet:
- **Praxisorientiert**: Lokale LLMs für Programmierung, Dokumentenanalyse und Textgenerierung.
- **Datenschutz**: Keine Cloud-Abhängigkeit, alle Daten bleiben lokal.
- **Lernwert**: Verständnis von Ollama, Llama-Modellen und HomeLab-Integration.

Es ist ideal für Schüler, die lokale KI in einer HomeLab-Umgebung erkunden möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu Monitoring mit Zabbix/Prometheus, Integration mit Terraform/Ansible für automatisierte LLM-Deployment, oder erweiterten Modellen (z. B. Llama 3.2)?

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,[](https://t3n.de/news/ollama-lokale-ki-llama-deepseek-1701112/)[](https://pcwelts.de/ollama/)[](https://robert-leitinger.com/llm-lokal-nutzen-lm-studio/)
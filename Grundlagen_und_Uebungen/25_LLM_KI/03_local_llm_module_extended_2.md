# Lernprojekt: Zusätzliche Übung zum Aufbau einer lokalen KI mit LLMs

## Einführung

Diese zusätzliche Übung erweitert das Lernprojekt `02_local_llm_module_extended.md`, das lokale Large Language Models (LLMs) wie **Llama 3.1 (8B)** mit **Ollama** auf einer Ubuntu-VM (Proxmox VE, IP `192.168.30.101`) in einer HomeLab-Umgebung nutzt. Die Übung ist für Lernende mit Grundkenntnissen in Linux, Python und Docker geeignet und integriert die HomeLab-Infrastruktur mit Proxmox VE, TrueNAS (`192.168.30.100`) für Backups und OPNsense (`192.168.30.1`) für Netzwerkmanagement. Sie konzentriert sich auf den Aufbau einer einfachen **künstlichen Intelligenz (KI)**, die ein lokales Frage-Antwort-System basierend auf einem benutzerdefinierten Datensatz (z. B. Textdokumente) erstellt. Dabei wird **Ollama** verwendet, um Llama 3.1 mit einem benutzerdefinierten Kontext zu "trainieren" (simuliertes Fine-Tuning durch Kontext-Einbettung). Die Übung umfasst die Erstellung eines Datensatzes, die Entwicklung eines Frage-Antwort-Skripts und die Integration in die HomeLab. Das Projekt bleibt lokal, kostenlos und datenschutzfreundlich.

**Voraussetzungen** (wie in `02_local_llm_module_extended.md`):
- Ubuntu 22.04 VM auf Proxmox (ID 101, IP `192.168.30.101`), eingerichtet mit Ollama und Llama 3.1 (8B).
- Hardware: Mindestens 8 GB RAM, 4 CPU-Kerne, 20 GB freier Speicher.
- Docker, Python und `sentence-transformers` installiert:
  ```bash
  sudo apt install -y docker.io python3-pip
  pip3 install sentence-transformers
  ```
- HomeLab mit TrueNAS (`192.168.30.100`) und OPNsense (`192.168.30.1`).
- SSH-Schlüsselpaar (z. B. `~/.ssh/id_rsa.pub`, `~/.ssh/id_rsa`).
- Projektverzeichnis: `~/llm-project` auf der VM.
- Ollama mit Llama 3.1 (8B):
  ```bash
  ollama pull llama3.1:8b
  ```

**Ziele**:
- Aufbau einer einfachen KI für ein Frage-Antwort-System basierend auf einem lokalen Datensatz.
- Nutzung von Llama 3.1 mit benutzerdefiniertem Kontext für kontextbezogene Antworten.
- Integration mit der HomeLab für Backups und Netzwerkmanagement.

**Hinweis**: Da echtes Fine-Tuning von Llama 3.1 ressourcenintensiv ist, simulieren wir es durch Kontext-Einbettung mit einem benutzerdefinierten Datensatz. Das Projekt bleibt lokal und datenschutzfreundlich.

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Sentence-Transformers: https://sbert.net
- Webquellen:,,,,,

## Übung 7: Aufbau einer lokalen KI für ein Frage-Antwort-System

**Ziel**: Erstellen einer KI, die Fragen basierend auf einem benutzerdefinierten Datensatz (Textdokumente) beantwortet, mit Llama 3.1 und Sentence-Transformers.

**Aufgabe**: Erstelle einen benutzerdefinierten Datensatz, entwickle ein Python-Skript für ein Frage-Antwort-System und integriere es in die HomeLab.

1. **Benutzerdefinierten Datensatz erstellen**:
   - Verbinde dich mit der VM:
     ```bash
     ssh ubuntu@192.168.30.101
     cd ~/llm-project
     ```
   - Erstelle ein Verzeichnis für den Datensatz:
     ```bash
     mkdir -p dataset
     ```
   - Erstelle Beispiel-Textdokumente (z. B. Wissensbasis für ein HomeLab-Projekt):
     ```bash
     echo -e "HomeLab-Dokumentation\n\nProxmox VE ist eine Virtualisierungsplattform, die auf Debian basiert. Sie unterstützt VMs und LXC-Container.\nIP: 192.168.30.10" > dataset/proxmox.txt
     echo -e "TrueNAS-Dokumentation\n\nTrueNAS ist ein Open-Source-Speichersystem für Backups.\nIP: 192.168.30.100\nPfad: /mnt/tank/backups" > dataset/truenas.txt
     echo -e "OPNsense-Dokumentation\n\nOPNsense ist eine Firewall- und Router-Software.\nIP: 192.168.30.1" > dataset/opnsense.txt
     ```

2. **Python-Skript für Frage-Antwort-System erstellen**:
   - Erstelle das Skript:
     ```bash
     nano qa_system.py
     ```
     - Inhalt:
       ```python
       import os
       import requests
       import json
       from sentence_transformers import SentenceTransformer

       model = SentenceTransformer('all-MiniLM-L6-v2')

       def load_dataset(directory):
           documents = []
           for filename in os.listdir(directory):
               if filename.endswith(".txt"):
                   with open(os.path.join(directory, filename), 'r') as file:
                       text = file.read()
                       documents.append({"filename": filename, "text": text})
           return documents

       def semantic_search(query, documents):
           texts = [doc["text"] for doc in documents]
           query_embedding = model.encode(query)
           doc_embeddings = model.encode(texts)
           similarities = model.similarity(query_embedding, doc_embeddings)[0]
           best_idx = similarities.argmax()
           return documents[best_idx], similarities[best_idx]

       def query_llm(prompt, context):
           url = "http://localhost:11434/api/generate"
           full_prompt = f"Kontext: {context}\n\nFrage: {prompt}\nAntwort im Stil einer präzisen, professionellen Dokumentation."
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
           dataset_dir = "dataset"
           documents = load_dataset(dataset_dir)
           print(f"Geladene Dokumente: {[doc['filename'] for doc in documents]}")
           while True:
               query = input("Frage (oder 'exit' zum Beenden): ")
               if query.lower() == "exit":
                   break
               best_doc, score = semantic_search(query, documents)
               print(f"Beste Übereinstimmung: {best_doc['filename']} (Score: {score:.2f})")
               answer = query_llm(query, best_doc["text"])
               print("Antwort:")
               print(answer)
               print("-" * 50)
       ```
     - **Erklärung**:
       - `load_dataset`: Lädt Textdokumente aus dem `dataset`-Verzeichnis.
       - `semantic_search`: Findet das relevanteste Dokument mit Sentence-Transformers.
       - `query_llm`: Stellt die Frage an Llama 3.1 mit dem Kontext des besten Dokuments.
       - Interaktive CLI für Fragen und Antworten.

3. **Skript ausführen**:
   ```bash
   python3 qa_system.py
   ```
   - Beispiel:
     ```
     Geladene Dokumente: ['proxmox.txt', 'truenas.txt', 'opnsense.txt']
     Frage (oder 'exit' zum Beenden): Was ist TrueNAS?
     Beste Übereinstimmung: truenas.txt (Score: 0.95)
     Antwort:
     TrueNAS ist ein Open-Source-Speichersystem, das für Backups verwendet wird. Es ist unter der IP-Adresse 192.168.30.100 erreichbar, und Backups werden im Pfad /mnt/tank/backups gespeichert.
     ```

4. **Antworten speichern**:
   - Speichere Antworten für die Dokumentation:
     ```bash
     python3 qa_system.py | tee -a qa_log.txt
     ```

**Erkenntnis**: Durch Kombination von Sentence-Transformers für semantische Suche und Llama 3.1 für kontextbezogene Antworten kann eine einfache KI für ein lokales Frage-Antwort-System aufgebaut werden, die auf einem benutzerdefinierten Datensatz basiert.

### Integration mit HomeLab
1. **Backups auf TrueNAS**:
   - Archiviere das Projekt:
     ```bash
     tar -czf ~/llm-project-backup-$(date +%F).tar.gz ~/llm-project
     rsync -av ~/llm-project-backup-$(date +%F).tar.gz root@192.168.30.100:/mnt/tank/backups/llm/
     ```
   - Aktualisiere das Backup-Skript:
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

2. **Netzwerkmanagement mit OPNsense**:
   - Stelle sicher, dass die Firewall-Regel in OPNsense den Zugriff auf `192.168.30.101:11434` (Ollama-API) von `192.168.30.0/24` erlaubt:
     - Quelle: `192.168.30.0/24`
     - Ziel: `192.168.30.101`
     - Port: `11434`
     - Aktion: `Allow`

### Erweiterungsvorschläge
1. **Datensatz erweitern**:
   - Füge weitere Dokumente hinzu (z. B. Projektnotizen, Handbücher) und teste die Skalierbarkeit:
     ```bash
     echo -e "Projektnotizen\n\nDas HomeLab-Projekt umfasst Terraform, Ansible und LLMs." > dataset/project_notes.txt
     python3 qa_system.py
     ```

2. **REST-API für das Frage-Antwort-System**:
   - Erstelle eine Flask-API:
     ```bash
     pip3 install flask
     nano qa_api.py
     ```
     - Inhalt:
       ```python
       from flask import Flask, request, jsonify
       import os
       import requests
       import json
       from sentence_transformers import SentenceTransformer

       app = Flask(__name__)
       model = SentenceTransformer('all-MiniLM-L6-v2')

       def load_dataset(directory):
           documents = []
           for filename in os.listdir(directory):
               if filename.endswith(".txt"):
                   with open(os.path.join(directory, filename), 'r') as file:
                       text = file.read()
                       documents.append({"filename": filename, "text": text})
           return documents

       def semantic_search(query, documents):
           texts = [doc["text"] for doc in documents]
           query_embedding = model.encode(query)
           doc_embeddings = model.encode(texts)
           similarities = model.similarity(query_embedding, doc_embeddings)[0]
           best_idx = similarities.argmax()
           return documents[best_idx], similarities[best_idx]

       def query_llm(prompt, context):
           url = "http://localhost:11434/api/generate"
           full_prompt = f"Kontext: {context}\n\nFrage: {prompt}\nAntwort im Stil einer präzisen, professionellen Dokumentation."
           payload = {"model": "llama3.1:8b", "prompt": full_prompt, "stream": False}
           response = requests.post(url, json=payload)
           return json.loads(response.text)["response"] if response.status_code == 200 else f"Fehler: {response.status_code}"

       @app.route("/qa", methods=["POST"])
       def qa():
           data = request.json
           query = data.get("query", "")
           documents = load_dataset("dataset")
           best_doc, score = semantic_search(query, documents)
           answer = query_llm(query, best_doc["text"])
           return jsonify({
               "question": query,
               "answer": answer,
               "document": best_doc["filename"],
               "score": float(score)
           })

       if __name__ == "__main__":
           app.run(host="0.0.0.0", port=5000)
       ```
     - Führe aus:
       ```bash
       python3 qa_api.py
       ```
     - Teste:
       ```bash
       curl -X POST -H "Content-Type: application/json" -d '{"query":"Was ist TrueNAS?"}' http://192.168.30.101:5000/qa
       ```

## Best Practices für Schüler

- **Ressourcenmanagement**:
  - Begrenze Ollama-Ressourcen:
    ```bash
    docker run -d --memory="6g" --cpus="4" -v ollama:/root/.ollama -p 11434:11434 ollama/ollama
    ```
  - Überwache:
    ```bash
    free -h
    df -h
    ```
- **Sicherheit**:
  - Schränke Ollama-API-Zugriff ein:
    ```bash
    sudo ufw allow from 192.168.30.0/24 to any port 11434
    ```
  - Sichere Dateien:
    ```bash
    chmod 600 ~/.ssh/id_rsa
    ```
- **Backup-Strategie**:
  - Nutze die 3-2-1-Regel: 3 Kopien (lokal, TrueNAS, USB), 2 Medien, 1 Off-Site (TrueNAS).
- **Fehlerbehebung**:
  - Prüfe Ollama-Logs:
    ```bash
    docker logs $(docker ps -q -f ancestor=ollama/ollama)
    ```
  - Teste API:
    ```bash
    curl http://localhost:11434
    ```

**Quelle**: https://ollama.com/docs, https://sbert.net

## Empfehlungen für Schüler

- **Setup**: Ollama mit Llama 3.1, Ubuntu-VM, TrueNAS-Backups.
- **Workload**: Frage-Antwort-System basierend auf benutzerdefiniertem Datensatz.
- **Integration**: Proxmox (VM), TrueNAS (Backups), OPNsense (Netzwerk).
- **Beispiel**: Fragen zur HomeLab-Dokumentation (Proxmox, TrueNAS, OPNsense).

## Tipps für den Erfolg

- **Einfachheit**: Beginne mit wenigen Dokumenten und präzisen Fragen.
- **Übung**: Erweitere den Datensatz mit weiteren Texten (z. B. Projektnotizen).
- **Fehlerbehebung**: Nutze `curl` für API-Tests und `docker logs` für Debugging.
- **Lernressourcen**: https://ollama.com/docs, https://sbert.net, https://pve.proxmox.com/wiki.
- **Dokumentation**: Speichere diese Anleitung auf TrueNAS (`/mnt/tank/docs`).

## Fazit

Diese Übung bietet:
- **Praxisorientiert**: Aufbau einer lokalen KI für ein Frage-Antwort-System.
- **Datenschutz**: Lokale Verarbeitung ohne Cloud-Abhängigkeit.
- **Lernwert**: Verständnis von Kontext-Einbettung und semantischer Suche.

Sie ist ideal für Schüler, die eine einfache KI in einer HomeLab erstellen möchten.

**Nächste Schritte**: Möchtest du eine Anleitung zu echtem Fine-Tuning (z. B. mit LoRA), Integration mit Terraform/Ansible oder Monitoring mit Zabbix/Prometheus?

**Quellen**:
- Ollama-Dokumentation: https://ollama.com
- Llama-Dokumentation: https://github.com/meta-ai/llama
- Sentence-Transformers: https://sbert.net
- Proxmox VE-Dokumentation: https://pve.proxmox.com/pve-docs/
- Webquellen:,,,,,

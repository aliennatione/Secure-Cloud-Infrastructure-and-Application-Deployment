```markdown
# Secure Cloud Infrastructure & Application Deployment

Questo progetto open-source fornisce una soluzione completa per il provisioning, l'hardening e il deployment di infrastrutture cloud sicure e applicazioni. Adotta un approccio "Infrastructure as Code" (IaC) per gestire le risorse cloud (Hetzner), Ansible per la configurazione del sistema operativo, HashiCorp Vault per la gestione centralizzata dei segreti (inclusa la passphrase LUKS), e InSpec per la verifica della conformità di sicurezza. L'intera pipeline è automatizzata tramite GitHub Actions, garantendo un ciclo di vita del deployment sicuro, deterministico e robusto, con particolare attenzione alla crittografia LUKS e allo sblocco remoto delle VPS Ubuntu.

## Funzionalità Principali

*   **Sicurezza End-to-End**: Implementa la crittografia completa del filesystem (LUKS) per i volumi sensibili e HashiCorp Vault per la gestione sicura e centralizzata di tutti i segreti.
*   **Determinismo**: La pipeline di deployment è progettata per essere "fail-fast" su qualsiasi non conformità di sicurezza o errore di configurazione, con tutta la configurazione interamente versionata.
*   **Automazione Completa CI/CD**: Utilizza GitHub Actions per orchestrare l'intero processo, dal provisioning dell'infrastruttura, all'hardening del sistema operativo, all'audit di sicurezza e al deployment dell'applicazione.
*   **Recupero da Disastro & Sblocco Remoto**: Incorpora Dropbear, un server SSH leggero, per consentire lo sblocco remoto dei volumi crittografati LUKS anche dopo un riavvio del server.
*   **Conformità Continua**: Applica InSpec per la verifica automatica e continua dello stato di sicurezza e conformità dell'infrastruttura rispetto a policy definite.
*   **Scalabilità e Modularità**: L'architettura modulare supporta facilmente ambienti multipli (ad esempio, `dev`, `prod`), facilitando l'espansione e la gestione.
*   **Standard di Compliance**: Progettato per soddisfare requisiti stringenti di sicurezza e compliance, come SOC2, ISO 27001 e GDPR.

## Tecnologie Utilizzate

*   **Terraform**: Per l'Infrastructure as Code (IaC) e il provisioning di macchine virtuali (VPS) su Hetzner Cloud.
*   **Ansible**: Per la configurazione del sistema operativo Ubuntu, l'hardening del server, l'installazione di LUKS, Dropbear e l'agente Vault.
*   **HashiCorp Vault**: Per la gestione sicura dei segreti, l'archiviazione delle passphrase LUKS e la distribuzione delle credenziali.
*   **Hetzner Cloud**: Il provider cloud utilizzato per il provisioning delle risorse di calcolo.
*   **LUKS (Linux Unified Key Setup)**: Per la crittografia a livello di blocco del volume del filesystem.
*   **Dropbear**: Un'implementazione leggera del server SSH, configurato nell'initramfs per consentire l'accesso e lo sblocco remoto dei volumi LUKS.
*   **InSpec**: Uno strumento di audit e compliance per la verifica automatica della configurazione di sicurezza del sistema.
*   **GitHub Actions**: Piattaforma CI/CD per l'automazione completa dei workflow di deployment e sicurezza.
*   **Python / FastAPI**: Utilizzato per l'applicazione di esempio containerizzata e il client per interagire con Vault.
*   **Docker / Docker Compose**: Per la containerizzazione e l'orchestrazione locale dell'applicazione di esempio.
*   **Make**: Utilizzato per semplificare l'esecuzione dei comandi di sviluppo e deployment locali.
*   **Cloud-init**: Per l'inizializzazione e la configurazione iniziale dei server al primo avvio.

## Struttura del Progetto

Il repository è organizzato in modo logico per separare le diverse responsabilità:

*   `terraform/`: Contiene i moduli Terraform generici e le configurazioni specifiche per ambiente (`dev`, `prod`) per il provisioning dell'infrastruttura.
*   `ansible/`: Ospita i playbook e i ruoli Ansible per la configurazione del sistema operativo, l'hardening, la gestione di LUKS e Dropbear, e l'installazione dell'agente Vault.
*   `security_policy/`: Definisce i controlli di sicurezza InSpec per l'audit continuo della conformità dell'infrastruttura.
*   `application/`: Include il codice sorgente di un'applicazione FastAPI di esempio, il suo `Dockerfile` e configurazioni per l'interazione con Vault.
*   `vault/`: Contiene script di inizializzazione e policy per HashiCorp Vault, inclusa la configurazione di metodi di autenticazione come AppRole.
*   `.github/workflows/`: Definisce i workflow di GitHub Actions per l'automazione del deployment, dei controlli di sicurezza e della gestione di Terraform.
*   `Makefile`: Fornisce comandi di alto livello per semplificare l'esecuzione delle operazioni più comuni.

## Installazione e Utilizzo

### 1. Prerequisiti

Per iniziare, assicurati di avere installati i seguenti strumenti sulla tua macchina locale:

*   **Git**
*   **Terraform** (versione 1.8.5 o superiore)
*   **Vault CLI** (versione 1.16.0 o superiore)
*   **Python 3** (versione 3.11 o superiore) e **pip**
*   **Ansible** (versione 2.16.0 o superiore) e le librerie Python `hvac`, `requests`, `cryptography`
*   **InSpec** (versione 5.22.0 o superiore)

Puoi installare la maggior parte di questi con i seguenti comandi (esempio per sistemi basati su Debian/Ubuntu):

```bash
# Installare Terraform e Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform vault

# Installare Python, pip, Ansible e dipendenze
sudo apt-get install python3 python3-pip
pip install ansible==2.16.0 hvac requests cryptography

# Installare InSpec (richiede Ruby)
sudo apt-get install ruby-full # Installa Ruby se non presente
gem install inspec -v 5.22.0
```

### 2. Configurazione Iniziale

1.  **Clona il repository:**
    ```bash
    git clone https://github.com/tuo-username/secure-infrastructure.git
    cd secure-infrastructure
    ```

2.  **Configura i segreti GitHub:**
    Questo progetto utilizza GitHub Secrets per gestire le credenziali sensibili all'interno della pipeline CI/CD. Devi configurare i seguenti segreti nel tuo repository GitHub:
    *   `HCLOUD_TOKEN`: Il token API di Hetzner Cloud, necessario per Terraform per creare e gestire le risorse.
    *   `VAULT_ADDR`: L'indirizzo del tuo server Vault.
    *   `ADMIN_SSH_PRIVATE_KEY`: La chiave SSH privata (in formato PEM) che verrà iniettata nella VPS per l'accesso `root` durante la fase di hardening Ansible.

3.  **Inizializza Vault (esegui una volta):**
    Esegui lo script di inizializzazione di Vault per configurare le policy necessarie e abilitare il metodo di autenticazione AppRole. Questo genererà `VAULT_ROLE_ID` e `VAULT_SECRET_ID` che dovrai poi aggiungere come segreti GitHub.
    ```bash
    make vault-init
    ```
    Dopo l'esecuzione, lo script stamperà `VAULT_ROLE_ID` e `VAULT_SECRET_ID`. Assicurati di aggiungerli come segreti nel tuo repository GitHub.

### 3. Deployment

Il deployment può essere eseguito automaticamente tramite GitHub Actions o manualmente.

#### Deployment automatico (GitHub Actions)

Per un deployment completo orchestrato da GitHub Actions, semplicemente:
```bash
git push origin main
```
Questo attiverà il workflow `deploy.yml` che provvederà in sequenza al provisioning dell'infrastruttura, all'hardening del sistema, all'audit di sicurezza e al deployment dell'applicazione.

#### Deployment manuale

Per eseguire i passaggi manualmente in sequenza:

1.  **Provisioning dell'infrastruttura con Terraform:**
    ```bash
    make tf-init
    make tf-apply
    ```
    Dopo l'applicazione, recupera l'indirizzo IP del server (`server_ip`) e il percorso della passphrase LUKS (`luks_passphrase_path`) dai relativi `terraform output` nella directory `terraform/environments/prod`.

2.  **Hardening del server con Ansible:**
    Avrai bisogno dell'IP del server, della chiave SSH privata (`~/.ssh/id_rsa` preconfigurata o specificata con `-i`), e potenzialmente del token Vault e del percorso della passphrase LUKS (che il workflow GitHub Actions inietta automaticamente).
    ```bash
    # Per il deployment manuale, assicurati che la tua chiave SSH privata
    # sia autorizzata sulla VPS o aggiungila con ssh-add.
    # L'inventario dinamico è configurato per Hetzner, ma puoi specificare l'IP direttamente.
    ansible-playbook -i "SERVER_IP," -u root --private-key ~/.ssh/id_rsa \
      ansible/playbooks/hardening.yml \
      --extra-vars "luks_passphrase_path=<LUKS_PASSPHRASE_PATH_FROM_TF> vault_token=<YOUR_VAULT_TOKEN>"
    ```
    *Sostituisci `SERVER_IP`, `LUKS_PASSPHRASE_PATH_FROM_TF` e `YOUR_VAULT_TOKEN` con i valori appropriati.*

3.  **Esecuzione dei test di sicurezza InSpec:**
    ```bash
    # Assicurati che ~/.ssh/id_rsa sia la chiave corretta per accedere al server.
    SERVER_IP="<L'IP_DEL_TUO_SERVER>" make inspec-test
    ```

4.  **Deployment dell'applicazione:**
    Il workflow GitHub Actions usa `scp` e `ssh` per copiare i file dell'applicazione e avviarla. Puoi replicare questi passaggi manualmente.
    ```bash
    SERVER_IP="<L'IP_DEL_TUO_SERVER>"
    scp -o StrictHostKeyChecking=no -r application/src root@${SERVER_IP}:/mnt/secure/app
    ssh -o StrictHostKeyChecking=no root@${SERVER_IP} "
      cd /mnt/secure/app
      python3 -m venv venv
      source venv/bin/activate
      pip install -r requirements.txt
      python main.py
    "
    ```

### 4. Verifica

1.  **Verifica lo stato dell'applicazione:**
    Controlla che l'applicazione sia in esecuzione e accessibile sulla porta 8000.
    ```bash
    curl http://<SERVER_IP>:8000/health
    ```

2.  **Verifica la crittografia LUKS:**
    Connettiti alla VPS via SSH e controlla lo stato del volume crittografato.
    ```bash
    ssh root@<SERVER_IP> "cryptsetup status cryptroot"
    ```

3.  **Verifica Dropbear (sblocco remoto LUKS):**
    Riavvia la VPS (`hcloud server reboot <SERVER_ID>`). Poco dopo il riavvio, dovresti essere in grado di connetterti via SSH alla porta 2222.
    ```bash
    ssh -p 2222 root@<SERVER_IP>
    ```
    Questo ti permetterà di sbloccare il volume LUKS se necessario, anche se lo script di sblocco nell'initramfs dovrebbe tentare di farlo automaticamente.

## Contribuire

Accogliamo con favore i contributi a questo progetto! Se hai suggerimenti, segnalazioni di bug o desideri contribuire con nuove funzionalità, ti preghiamo di seguire queste linee guida:

1.  **Fork** il repository.
2.  Crea un nuovo **branch** per la tua funzionalità o correzione (`git checkout -b feature/nome-funzionalita`).
3.  Effettua le tue modifiche, assicurandoti che il codice sia ben documentato e i test, se applicabili, siano aggiornati.
4.  **Commit** le tue modifiche con un messaggio chiaro e conciso.
5.  **Push** il branch al tuo fork (`git push origin feature/nome-funzionalita`).
6.  Apri una **Pull Request** sul repository originale, descrivendo chiaramente le tue modifiche e il loro scopo.

## Licenza

Questo progetto è rilasciato sotto la licenza MIT.
```
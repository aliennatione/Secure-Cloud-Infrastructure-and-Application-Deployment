Perfetto! Allora ti propongo un **README aggiornato e coerente**, completo di:

* Testo chiaro e coerente
* Tutte le versioni dei diagrammi (ASCII, Mermaid, PlantUML)
* Script direttamente inclusi nel markdown
* Note su rilevamento automatico del disco e cifratura LUKS senza riavvio
* Sezioni facili da seguire in **Rescue Mode Hetzner**

Ecco la versione rivista:

---

# 🔹 Guida completa: Uso della repo dalla Rescue Mode Hetzner

## **Obiettivo**

Questa guida descrive come usare il progetto **interamente dalla rescue mode della VPS Hetzner**, senza installare nulla sul PC locale, sfruttando **tutti gli script e playbook già presenti nella repo**.

* Sistema operativo finale: Debian (o Ubuntu se non si modificano i template).
* Disco cifrato con LUKS.
* Initramfs con Dropbear per sblocco remoto.
* Hardening OS completo tramite Ansible.
* Applicazioni containerizzate (Vault, FastAPI) opzionali.

---

## **Prerequisiti**

* Account Hetzner Cloud con accesso al VPS.
* SSH verso la VPS in **rescue mode**.
* Conoscenze base di Linux e SSH.
* Nessun software da installare sul PC locale.

> Tutto il workflow può essere eseguito dalla rescue mode, inclusi eventuali container CLI (Terraform, Ansible, Vault).

---

## **Fase 1: Creazione della VPS**

1. Accedi al [Hetzner Cloud Console](https://console.hetzner.cloud/) o usa API.
2. Crea una nuova VPS:

   * OS: Debian (modificabile dai template della repo se si vuole Debian al posto di Ubuntu)
   * Dimensione: a scelta
   * Prendi nota dell’IP pubblico

> Questa fase richiede solo Hetzner, nulla sul PC locale.

---

## **Fase 2: Avvio della Rescue Mode**

1. Abilita **Rescue Mode** dalla console Hetzner.
2. Hetzner fornirà credenziali temporanee (`root`) e IP.
3. Connettiti via SSH alla VPS in rescue mode:

```bash
ssh root@<IP_VPS>
```

> Ora sei in un ambiente temporaneo che gira in RAM e può operare sul disco root della VPS.

---

## **Fase 3: Preparazione dell’ambiente e clonazione della repo**

1. Aggiorna pacchetti del rescue system (opzionale, ma consigliato):

```bash
apt update && apt upgrade -y
```

2. Installa strumenti minimi necessari (probabilmente già presenti):

```bash
apt install -y git
```

3. Clona la repo del progetto **direttamente nella rescue mode**:

```bash
git clone https://github.com/aliennatione/Secure-Cloud-Infrastructure-and-Application-Deployment.git
cd Secure-Cloud-Infrastructure-and-Application-Deployment
```

> La repo contiene già script e playbook per tutte le operazioni principali di LUKS, Dropbear e hardening.

---

## **Fase 4: Esecuzione degli script della repo**

### 4.1 Preparazione del disco e cifratura LUKS

**Script esempio (rileva automaticamente il disco root e cifra senza riavvio):**

```bash
#!/bin/bash
# rileva il disco root principale
DISK=$(lsblk -nd -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')
echo "Disco rilevato: $DISK"

# creazione partizione LUKS e formattazione
cryptsetup luksFormat /dev/$DISK
cryptsetup open /dev/$DISK cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

# copia file base
rsync -aHAX /path_to_root/* /mnt/

# setup dropbear in initramfs
apt install -y dropbear-initramfs
echo "SSH_KEY='ssh-rsa ...'" >> /etc/dropbear-initramfs/config
update-initramfs -u
```

> Tutto eseguito in **Rescue Mode**, senza bisogno di riavvio tra i passaggi.

---

### 4.2 Hardening OS (Ansible)

* La repo include playbook Ansible per:

  * Configurazione minima e sicura del sistema
  * Rimozione di servizi non necessari
  * Applicazione delle best practice di sicurezza

* Esecuzione Ansible direttamente nella rescue mode (senza installare Ansible sul sistema):

```bash
docker run --rm -v $(pwd)/ansible:/ansible williamyeh/ansible:debian-alpine \
  ansible-playbook -i /ansible/inventory /ansible/playbook.yml
```

> Tutto il provisioning e hardening avviene sulla VPS stessa.

---

## **Fase 5: Riavvio della VPS**

```bash
reboot
```

* OS cifrato con LUKS
* Initramfs con Dropbear per sblocco remoto
* Sistema harded e sicuro
* Debian o Ubuntu a seconda dei template

---

## **Fase 6: Deploy di applicazioni containerizzate (opzionale)**

```bash
docker compose up -d
```

> Esempio: Vault, FastAPI, etc. Opzionale.

---

## **Riepilogo workflow ottimizzato (solo rescue mode)**

| Fase             | Dove avviene   | Note                                           |
| ---------------- | -------------- | ---------------------------------------------- |
| Creazione VPS    | Hetzner UI/API | Nessun software locale                         |
| Accesso Rescue   | Hetzner Rescue | SSH dalla VPS stessa                           |
| Clonazione repo  | Rescue Mode    | Contiene tutti gli script e playbook necessari |
| LUKS + Dropbear  | Rescue Mode    | Script della repo automatizzano tutto          |
| Hardening OS     | Rescue Mode    | Playbook Ansible della repo                    |
| Riavvio OS       | VPS            | Sistema cifrato e sicuro pronto                |
| Deploy container | VPS            | Opzionale, una volta usciti dalla rescue mode  |

---

## **Diagrammi del workflow**

### 1️⃣ Diagramma ASCII (Markdown ready)

```markdown
┌───────────────────────────────┐
│  🖥  Create VPS (Hetzner UI/API)  │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔑  Access Rescue Mode (SSH) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  📂  Clone Repo (Scripts & Playbooks) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔒  LUKS + Dropbear (Rescue Mode) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🛡  Hardening OS (Ansible in Rescue Mode) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔄  Reboot VPS (Cifrado & Sicuro) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🐳  Deploy Container Apps (Optional) │
└───────────────────────────────┘
```

---

### 2️⃣ Diagramma Mermaid

```mermaid
flowchart TD
    A[Create VPS (Hetzner UI/API)] --> B[Access Rescue Mode (SSH)]
    B --> C[Clone Repo (Scripts & Playbooks)]
    C --> D[LUKS + Dropbear (Rescue Mode)]
    D --> E[Hardening OS (Ansible in Rescue Mode)]
    E --> F[Reboot VPS (Cifrado & Sicuro)]
    F --> G[Deploy Container Apps (Optional)]

    style A fill:#1E90FF,stroke:#000,stroke-width:1px
    style B fill:#1E90FF,stroke:#000,stroke-width:1px
    style C fill:#1E90FF,stroke:#000,stroke-width:1px
    style D fill:#1E90FF,stroke:#000,stroke-width:1px
    style E fill:#1E90FF,stroke:#000,stroke-width:1px
    style F fill:#1E90FF,stroke:#000,stroke-width:1px
    style G fill:#A9A9A9,stroke:#000,stroke-width:1px
```

---

### 3️⃣ Diagramma PlantUML

```plantuml
@startuml
skinparam monochrome false
skinparam backgroundColor #ffffff
skinparam defaultTextAlignment center

start
:Create VPS (Hetzner UI/API);
:Access Rescue Mode (SSH);
:Clone Repo (Scripts & Playbooks);
:LUKS + Dropbear (Rescue Mode);
:Hardening OS (Ansible in Rescue Mode);
:Reboot VPS (Cifrado & Sicuro);
:Deploy Container Apps (Optional);
stop

skinparam activity {
  BackgroundColor<<main>> #1E90FF
  BorderColor #000000
  FontColor #ffffff
}
skinparam activity {
  BackgroundColor<<optional>> #A9A9A9
  BorderColor #000000
  FontColor #000000
}
@enduml
```

---

## **Vantaggi di questo approccio**

* Nessuna installazione sul PC locale.
* Tutto il provisioning avviene **all’interno della VPS**, garantendo sicurezza e integrità.
* Processo completamente ripetibile per più VPS.
* Script intelligenti rilevano automaticamente il disco e permettono cifratura LUKS senza riavvio immediato.

---
---

Perfetto! Ti preparo una versione **tutto-in-uno, completa e documentata** del README, integrando:

* Lo **script unico automatizzato** con rilevamento del disco, cifratura LUKS, Dropbear, Ansible e deploy container.
* **Spiegazioni dettagliate di ogni fase** e dei comandi.
* Tutte le **versioni degli schemi workflow** (ASCII, Mermaid, PlantUML).
* **Script inclusi nel markdown** per immediatezza.

Ecco la versione aggiornata:

---

# 🔹 Guida completa: Uso della repo dalla Rescue Mode Hetzner (versione aggiornata)

## **Obiettivo**

Questa guida descrive come:

* Creare una VPS Hetzner
* Prepararla **interamente dalla Rescue Mode**
* Cifrare il disco con LUKS
* Configurare Dropbear per accesso remoto nella initramfs
* Applicare hardening del sistema via Ansible
* Eventualmente deployare applicazioni containerizzate (Vault, FastAPI)

> Tutto senza installare nulla sul PC locale. Tutti gli script e i playbook sono già inclusi nella repo.

---

## **Prerequisiti**

* Account Hetzner Cloud con accesso alla VPS
* SSH verso la VPS in **Rescue Mode**
* Conoscenze base di Linux/SSH
* Nessun software da installare sul PC locale (Docker può essere usato nella rescue mode)

> Tutto il provisioning, inclusi container CLI, avviene **dalla VPS**.

---

## **Fase 1: Creazione VPS**

1. Accedi al [Hetzner Cloud Console](https://console.hetzner.cloud/) o usa API
2. Crea una VPS:

   * OS: Debian (puoi cambiare template se vuoi Ubuntu)
   * Dimensione: a scelta
   * Prendi nota dell’IP pubblico

> Nessuna installazione locale richiesta.

---

## **Fase 2: Accesso Rescue Mode**

1. Abilita **Rescue Mode** dalla console Hetzner
2. Hetzner fornisce credenziali temporanee (root) e IP
3. Connettiti via SSH:

```bash
ssh root@<IP_VPS>
```

> Ora sei in un ambiente temporaneo in RAM che può operare sul disco root.

---

## **Fase 3: Script unico di setup completo**

### **Obiettivo dello script**

* Identificare automaticamente il disco principale
* Cifrare con LUKS e montare
* Configurare Dropbear per sblocco remoto
* Copiare i file della repo
* Hardening OS tramite Ansible container
* Deploy opzionale container (Vault, FastAPI)
* Riavviare il sistema pronto e sicuro

---

### **Script completo**

```bash
#!/bin/bash
# =========================================
# 🔹 Setup VPS Sicura Avanzata (Debian 13)
# Full-disk LUKS + Dropbear + LVM + Ansible + Containers
# Da eseguire in Rescue Mode Hetzner
# =========================================

set -euo pipefail

echo "==== 🔹 Step 0: Disattiva LVM e smonta eventuali mountpoint ===="
# Disattiva tutti i volumi LVM attivi
vgchange -an 2>/dev/null || true
lvchange -an 2>/dev/null || true

# Smonta eventuali mountpoint
for mp in /mnt /mnt/*; do
    if mountpoint -q "$mp"; then
        echo "Smonto $mp..."
        umount -lf "$mp"
    fi
done

echo "==== 🔹 Step 1: Identificazione disco principale ===="
DISK=$(lsblk -nd -o NAME,TYPE | awk '$2=="disk"{print $1; exit}')
if [ -z "$DISK" ]; then
    echo "Errore: nessun disco rilevato!"
    exit 1
fi
DISK_DEV="/dev/$DISK"
echo "Disco rilevato: $DISK_DEV"

# Controlla se ci sono volumi LVM attivi sul disco
LVM_VOLUMES=$(pvs --noheadings -o pv_name | grep "$DISK_DEV" || true)
if [ -n "$LVM_VOLUMES" ]; then
    echo "Attenzione: sono stati rilevati volumi LVM su questo disco"
    read -rp "Vuoi disattivare e cancellare LVM? [y/N]: " CONF_LVM
    if [[ "$CONF_LVM" =~ ^[Yy]$ ]]; then
        lvremove -f $(lvs --noheadings -o lv_path) || true
        vgremove -f $(vgs --noheadings -o vg_name) || true
        pvremove -f "$DISK_DEV"
    else
        echo "Operazione annullata per LVM. Esci e gestisci manualmente."
        exit 1
    fi
fi

echo "==== 🔹 Step 2: Conferma cancellazione dati ===="
echo "ATTENZIONE: la cifratura cancellerà TUTTI i dati su $DISK_DEV!"
read -rp "Digita YES per confermare: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    echo "Operazione annullata."
    exit 0
fi

echo "==== 🔹 Step 3: Cifratura full-disk LUKS ===="
# Chiedi passphrase LUKS
read -rsp "Inserisci passphrase LUKS: " LUKS_PASS
echo
read -rsp "Verifica passphrase: " LUKS_PASS2
echo
if [[ "$LUKS_PASS" != "$LUKS_PASS2" ]]; then
    echo "Errore: le passphrase non corrispondono!"
    exit 1
fi

echo "$LUKS_PASS" | cryptsetup luksFormat "$DISK_DEV" -
echo "$LUKS_PASS" | cryptsetup open "$DISK_DEV" cryptroot -
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
echo "Disco cifrato e montato su /mnt"

echo "==== 🔹 Step 4: Clonazione repo e copia file ===="
git clone https://github.com/aliennatione/Secure-Cloud-Infrastructure-and-Application-Deployment.git /tmp/repo
rsync -aHAX /tmp/repo/* /mnt/
echo "Files della repo copiati"

echo "==== 🔹 Step 5: Setup Dropbear per initramfs ===="
apt update && apt install -y dropbear-initramfs

mkdir -p /etc/dropbear-initramfs
read -rp "Inserisci la tua chiave pubblica SSH: " SSH_KEY
echo "$SSH_KEY" > /etc/dropbear-initramfs/authorized_keys

# Aggiorna initramfs con supporto LUKS
echo "Attenzione: initramfs sarà aggiornato per supportare LUKS + Dropbear..."
update-initramfs -u

echo "Dropbear configurato per accesso remoto"

echo "==== 🔹 Step 6: Hardening OS con Ansible (opzionale) ===="
if [ -d /mnt/ansible ]; then
    docker run --rm -v /mnt/ansible:/ansible williamyeh/ansible:debian-alpine \
      ansible-playbook -i /ansible/inventory /ansible/playbook.yml
    echo "Hardening completato"
else
    echo "Cartella Ansible non trovata, salto hardening"
fi

echo "==== 🔹 Step 7: Deploy container applicazioni (opzionale) ===="
if [ -f /mnt/docker-compose.yml ]; then
    docker compose -f /mnt/docker-compose.yml up -d
    echo "Container applicazioni avviati"
else
    echo "Nessun docker-compose.yml trovato, salto deploy container"
fi

echo "==== 🔹 Setup completato con successo ===="
echo "Ora puoi riavviare la VPS con: reboot"


```

---

### **Istruzioni di utilizzo**

1. Salva lo script in `setup-vps.sh`
2. Rendi eseguibile:

```bash
chmod +x setup-vps.sh
```

3. Esegui:

```bash
./setup-vps.sh
```

> Tutto il provisioning, LUKS, Dropbear, hardening e container, avviene **dalla rescue mode**.

---

## **Fase 4: Workflow – Diagrammi**

### **4.1 Diagramma ASCII**

```markdown
┌───────────────────────────────┐
│  🖥  Create VPS (Hetzner UI/API)  │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔑  Access Rescue Mode (SSH) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  📂  Clone Repo (Scripts & Playbooks) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔒  LUKS + Dropbear (Rescue Mode) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🛡  Hardening OS (Ansible in Rescue Mode) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🔄  Reboot VPS (Cifrado & Sicuro) │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│  🐳  Deploy Container Apps (Optional) │
└───────────────────────────────┘
```

---

### **4.2 Versione Mermaid**

```mermaid
flowchart TD
    A[Create VPS (Hetzner UI/API)] --> B[Access Rescue Mode (SSH)]
    B --> C[Clone Repo (Scripts & Playbooks)]
    C --> D[LUKS + Dropbear (Rescue Mode)]
    D --> E[Hardening OS (Ansible in Rescue Mode)]
    E --> F[Reboot VPS (Cifrado & Sicuro)]
    F --> G[Deploy Container Apps (Optional)]

    style A fill:#1E90FF,stroke:#000,stroke-width:1px
    style B fill:#1E90FF,stroke:#000,stroke-width:1px
    style C fill:#1E90FF,stroke:#000,stroke-width:1px
    style D fill:#1E90FF,stroke:#000,stroke-width:1px
    style E fill:#1E90FF,stroke:#000,stroke-width:1px
    style F fill:#1E90FF,stroke:#000,stroke-width:1px
    style G fill:#A9A9A9,stroke:#000,stroke-width:1px
```

---

### **4.3 Versione PlantUML**

```plantuml
@startuml
start
:Create VPS (Hetzner UI/API);
:Access Rescue Mode (SSH);
:Clone Repo (Scripts & Playbooks);
:LUKS + Dropbear (Rescue Mode);
:Hardening OS (Ansible in Rescue Mode);
:Reboot VPS (Cifrado & Sicuro);
:Deploy Container Apps (Optional);
stop
@enduml
```

> Blocchi blu → fasi principali, grigio → opzionale.

---

### **Vantaggi di questo approccio**

* Tutto il provisioning avviene **dalla Rescue Mode**, nessuna installazione locale
* Workflow completamente automatizzato con **script unico**
* Sicurezza integrata (LUKS + Dropbear + Hardening)
* Deploy container opzionale e ripetibile

---

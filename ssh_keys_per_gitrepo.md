# SSH Key für das `training_k8s_fluxcd_root` Repository

Zuerst wird ein dedizierter SSH Key für den Zugriff auf das GitHub-Repository erzeugt.  
Dieser Key wird später von FluxCD verwendet, um Änderungen im Repository lesen **und schreiben** zu können.

```bash
ssh-keygen -f ~/.ssh/id_rsa_fluxcd_root -C fluxcd_root
```

Der Befehl erzeugt:
- einen **privaten Key** (`id_rsa_fluxcd_root`)
- einen **öffentlichen Key** (`id_rsa_fluxcd_root.pub`)

---

## Public Key als Deploy Key im GitHub Repository hinterlegen

Im nächsten Schritt muss der **öffentliche Schlüssel** im GitHub-Repository als **Deploy Key** hinterlegt werden.

Den Public Key anzeigen:

```bash
cat ~/.ssh/id_rsa_fluxcd_root.pub
```

### Deploy Key in GitHub anlegen

1. Öffne das **geforkte GitHub Repository** (z. B. `training_k8s_fluxcd_root`)
2. Navigiere zu  
   **Settings → Deploy keys**
3. Klicke auf **Add deploy key**
4. Trage folgende Werte ein:
   - **Title**: z. B. `fluxcd_root`
   - **Key**: den kompletten Inhalt der `.pub`-Datei einfügen
5. **Wichtig:**  
   Aktiviere unbedingt die Option  
   **☑ Allow write access**

🔑 **Warum Write Access?**  
FluxCD benötigt Schreibrechte, um z. B.:
- GitOps-Änderungen zurück ins Repository zu committen
- Konfigurationsänderungen zu verwalten oder zu aktualisieren

Deploy Keys sind **repository-spezifisch** und sicherer als persönliche SSH Keys, da sie nur Zugriff auf genau dieses eine Repository haben.

---

## Repository mit dem dedizierten SSH Key klonen

Vor dem Klonen muss der GitHub-Benutzername angepasst werden  
(`mschreibjambit` → **dein eigener GitHub User**).

```bash
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa_fluxcd_root" git clone git@github.com:mschreibjambit/training_k8s_fluxcd_root.git

cd training_k8s_fluxcd_root

git config core.sshCommand "ssh -i ~/.ssh/id_rsa_fluxcd_root"
```

Damit ist sichergestellt, dass **ausschließlich dieser SSH Key** für alle Git-Operationen in diesem Repository verwendet wird.

---

## Weiteres Repository: `training_k8s_fluxcd_namespace_demo`

Für jedes weitere Git-Repository wird **ein eigener SSH Key** verwendet.  
Das Vorgehen ist identisch:

```bash
ssh-keygen -f ~/.ssh/id_rsa_fluxcd_namespace_demo -C fluxcd_namespace_demo

cat ~/.ssh/id_rsa_fluxcd_namespace_demo.pub
```

Der Public Key muss auch hier wieder als **Deploy Key mit Write Access** im jeweiligen Repository hinterlegt werden.

Anschließend das Repository klonen (GitHub User anpassen):

```bash
GIT_SSH_COMMAND="ssh -i ~/.ssh/id_rsa_fluxcd_namespace_demo" git clone git@github.com:mschreibjambit/training_k8s_fluxcd_namespace_demo.git

cd training_k8s_fluxcd_namespace_demo

git config core.sshCommand "ssh -i ~/.ssh/id_rsa_fluxcd_namespace_demo"
```
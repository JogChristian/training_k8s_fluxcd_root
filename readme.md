# Aufgaben

## Setup-Aufgabe

* Forkt bitte die Git-Repositories  
  https://github.com/jambit-k8s-training/training_k8s_fluxcd_root und  
  https://github.com/jambit-k8s-training/training_k8s_fluxcd_namespace_demo
* Klont beide geforkten Repositories.
* Wir arbeiten zunächst im geforkten **training_k8s_fluxcd_root** Repository.

## Fluxcd Bootstrap

* Führt in dem GitRepo direnv allow aus. Damit wird auch ein Githook in dem Repo aktiviert.
* Die Verzeichnisstruktur richtig sich nach dieser Anleitung: https://fluxcd.io/flux/guides/repository-structure/. 
* Die eigentliche Flux Installation wird über das Verzeichnis fluxcd/clusters/local gesteuert. local steht dabei für die lokale Umgebung. Später können mehr folgen. 
* Legt in "age-key-secret.yaml" eueren age-key ab. Zudem passt die Datei .sops.yaml an. Hier soll der Public Key von euerem Age Key hinterlegt werden. 
* Verschlüsselt die Datei age-key-secret.yaml mit `sops -i -e age-key-secret.yaml`. 
* Niemals – wirklich **niemals** – die Datei flux-components.yaml bearbeiten, da sie generiert wird und Änderungen verloren gehen.
* Öffne eine weiteres Terminal und lege einen ssh-key außerhalb des Git Repositories an. Dieser darf nicht in Git eingecheckt werden.

```
ssh-keygen -C fluxcd_key -f ./identity
ssh-keyscan github.com > ./known_hosts
```
* Damit mit diesem Schlüssel auf das Git-Repository zugegriffen werden kann, muss der öffentliche Schlüssel (identity.pub) als Deployment Key hinzugefügt werden. https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys
* Erstelle daraus ein generic k8s secret mit den drei Keys identity, identity.pub und known_hosts mit dem Namen git-pull-secret. Tipp: 
    * `kubectl create secret generic -h`
    * Benutzt bei euerem Befehl noch folgende Optionen: `--dry-run=client -o yaml`  damit wird das Yaml ausgegeben. 
Bei dieser Aufgabe kommt in etwas das hier raus:
```
apiVersion: v1
data:
    identity: ......
    identity.pub: ....
    known_hosts: ....
kind: Secret
metadata:
    name: git-pull-secret
```

Wenn ihr die Secret Datei habt, legt diese in das GitRepo unter fluxcd/clusters/local und ersetzt damit git-pull-secret.yaml. Verschlüsselt es mit sops!

* Nun muss die Datei flux-sync.yaml noch angepasst werden. Die Git Url muss für euer Git Repository stimmen.
  git commit und push nicht vergessen. 

* Jetzt könnt ihr `./install.sh` ausführen.

  Ihr solltet sowas sehen:
  ```
  kubectl get pods -n flux-system
  NAME                                       READY   STATUS    RESTARTS   AGE
  helm-controller-56fc8dd99d-f4f78           1/1     Running   0          3h44m
  kustomize-controller-b98f664d9-6rvsq       1/1     Running   0          3h44m
  source-controller-7f66565fb8-r95n5         1/1     Running   0          3h44m
  notification-controller-644f548fb6-bhcvl   1/1     Running   0          3h44m
  ```

  Jetzt prüfen wir noch den Status von GitRepository:

  ```
  kubectl get GitRepository -n flux-system
  NAME          URL                                                           AGE     READY   STATUS
  flux-system   ssh://git@github.com/mschreibjambit/k8s-training-fluxcd.git   3h47m   True    stored artifact for revision 'main/a6c456a6e46d2e6675feaa082922dd07b9a5eee6'
  ```
  Wie zu sehen ist, hat der Source Controller die Git Revision a6c456a6e46d2e6675feaa082922dd07b9a5eee6 (GitHash) im Main Branch gefunden. Wollt ihr den lokalen Stand sehen,
  könnt ihr diesen mit `git rev-parse main` oder `git rev-parse HEAD` prüfen.

  Die Kustomization muss noch geprüft werden:

  ```
  kubectl get Kustomization -n flux-system
  NAME             AGE     READY   STATUS
  flux-system      3h51m   True    Applied revision: main/a6c456a6e46d2e6675feaa082922dd07b9a5eee6
  ```

  Wenn dies der Fall ist, hat sich FluxCD erfolgreich selbst installiert und alles funktioniert wie erwartet. 

  Tipp: Wenn ihr mich mal seht, wie ich `kubectl get ks -A` oder `kubectl get gitrepo -A` tipp - ich habe die Shortnames benutzt. Probiert mal `kubectl api-resources` aus.

* Wie führt man jetzt ein update von fluxcd aus?

  * Schaut mal welche Version gerade installiert ist. 
  * Runterladen und installieren der aktuellsten flux cli Version (https://github.com/fluxcd/flux2/releases)
  * wechselt in fluxcd/clusters/local und führt folgendes aus:

  ```
  flux install --export > flux-components.yaml
  ```

  * git add & commit und push - schon wird flux sich selbst updaten.

## Aufgaben Infrastructure

* Damit FluxCD auch das `infrastructure`-Verzeichnis überwacht, muss in `clusters/local` eine Flux-Kustomization hinzugefügt werden. Siehe hierzu die Datei `flux-sync.yaml`.

* Nun soll die Ingress Controller Installation mit FluxCD automatisiert werden. 

  Manuell würde der Ingress Controller wie folgt installiert werden:

  ```
  helm repo add traefik https://helm.traefik.io/traefik
  helm install my-traefik traefik/traefik \
  --version v38.0.2 \
  --namespace traefik
  ```
  
  Wie das Automatisieren mit FluxCD nun geht, findet ihr hier https://fluxcd.io/flux/use-cases/helm/#getting-started. An die Create Befehle solltet ihr unbedingt ein `--export` ran hängen.

* Leider fehlen hier nun noch gewisse Values. Diese müssen auch noch integriert werden, bevor alles klappt. Folgende Values sollen gesetzt werden:

  ```
  providers:
    kubernetesGateway:
      enabled: true
  ports:
    web:
      expose:
        default: true
      exposedPort: 80
    websecure:
      expose:
        default: true
      exposedPort: 443
  service:
    type: LoadBalancer  
  ```

  > [!NOTICE] Achtet auf die Einrückung: `providers`, `ports` und `service` dürfen keine führenden Whitespaces haben. Alle darunterliegenden Konfigurationen 
  > müssen entsprechend konsistent eingerückt werden.

  Ihr findet auch hier Infos: https://fluxcd.io/flux/components/source/helmrepositories/ und https://fluxcd.io/flux/components/helm/helmreleases/

  Es gibt hier zwei grundsätzlich unterschiedliche Wege, die Values zu definieren. Ihr könnt sie entweder direkt inline im HelmRelease angeben oder über eine ConfigMap und/oder ein Secret referenzieren. Der Inline-Weg ist für den Einstieg einfacher und schneller umzusetzen. Der Ansatz über ConfigMap und Secret ist jedoch in der Praxis meist die bessere Wahl – insbesondere, wenn man sich Gedanken darüber macht, wo und wie Konfigurationswerte langfristig gepflegt werden sollen.

  Dabei stellt sich auch die Frage, ob die Values im base-Verzeichnis oder im local-Verzeichnis definiert werden sollten. Das hängt davon ab, ob es sich um umgebungsspezifische Konfigurationen handelt oder um Werte, die in allen Umgebungen identisch sind.

  Entscheidet ihr euch für den Weg über ConfigMap und Secret, gibt es eine Besonderheit zu beachten: Die Custom Resources von Flux (z. B. HelmRelease) werden von Kustomize nicht automatisch korrekt verarbeitet, wenn ConfigMapGenerator oder SecretGenerator verwendet werden. Konkret weiß Kustomize in diesem Fall nicht, an welchen Stellen der Name der generierten ConfigMap bzw. des Secrets im HelmRelease angepasst werden muss.

  Dieses Verhalten lässt sich jedoch konfigurieren. Da dies leider nicht besonders gut dokumentiert ist, wird das Vorgehen hier explizit beschrieben.

  Fügt hierzu in die kustomization.yaml folgendes hinzu:

  ```
  configurations:
    - kustomizeconfig.yaml
  ```
  
  Jetzt muss noch die Datei `kustomizeconfig.yaml` mit folgendem Inhalt angelegt werden:

  ```
  nameReference:
    - kind: ConfigMap
      version: v1
      fieldSpecs:
        - path: spec/valuesFrom/name
          kind: HelmRelease
    - kind: Secret
      version: v1
      fieldSpecs:
        - path: spec/valuesFrom/name
          kind: HelmRelease  
  ``` 

* Nun suchen wir die aktuelle Version des ingress-Helm-Charts heraus und pinnen diese. Wo würdet ihr das Pinning hinschreiben: base/traefik oder local/traefik? Warum?

* Wir haben zuvor die Values konfiguriert. Überlege dir nun, wo diese sinnvoll definiert werden sollten (`base/traefik` oder `local/traefik`). Maßgeblich ist dabei, ob es sich um umgebungsspezifische Values handelt oder um solche, die in allen Umgebungen identisch gesetzt werden.

* im scripte Ordner gibt es das Script `validate.sh`. Ihr solltet also im infrastructure Ordner mal `validate.sh . && echo OK` ausführen. Wenn zum Schluß OK steht, war die Validierung in Ordnung.

* Teste deine Installation. 

  Das HelmRelease ist eine Custom Resource von FluxCD und zeigt an, dass es erfolgreich war, oder einen Fehler gibt. 

  ```
  kubectl get helmrelease -n traefik
  NAME            AGE     READY   STATUS
  traefik         6h36m   True    Release reconciliation succeeded
  ```
  
  Folgendes zeigt die Liste der Helm Releases im Namespace nginx-ingress an. Dabei handelt es sich jedoch nicht um die Custom Resource von FluxCD, sondern um eine Funktion von Helm.
  ```
  helm list -n traefik                                                                                                                                         
  NAME   	NAMESPACE  	REVISION	UPDATED                                	STATUS  	CHART         	APP VERSION
  traefik	traefik	    1       	2026-01-22 13:30:37.557531437 +0000 UTC	deployed	traefik-38.0.2	v3.6.6
  ```

## Aufgaben Teams

* Nun soll `local/demo` angepasst werden. Das `base`-Verzeichnis ist bereits vordefiniert. Ziel ist es, ein weiteres Repository
  (das geforkte `training_k8s_fluxcd_namespace_demo`) einzubinden. Dafür müssen folgende Punkte vervollständigt werden:

  * `age-key-secret.yaml` – Eigentlich ist hier ein neuer Age-Key sinnvoll. Es funktioniert jedoch auch der aus `clusters/local`.
    Dies ist eine Vereinfachung, die man in einem produktiven Setup vermutlich nicht so umsetzen würde.

  * `git-pull-secret.yaml` – Hier wird zwingend ein neu generiertes `git-pull-secret` benötigt. Nutzt dafür folgendes Skript:  
    `mk_git-pull_secret.sh demo > git-pull-secret.yaml`
  
  * `tls-secret.yaml` – Diese Datei könnt ihr aus **Kubernetes_Basics (Schulung Tag 1)**,  
    `08_ingress`, übernehmen und hierher kopieren.

  * `kustomization.yaml` – Hier müssen die `GitRepository`-URL sowie der Pfad (`flux-kustomization`) mittels Patch angepasst werden.

  * Damit FluxCD auch das `teams`-Verzeichnis überwacht, muss in `clusters/local` eine Flux-Kustomization hinzugefügt werden.
    Siehe hierzu die Datei `flux-sync.yaml`.

* Nun wechseln wir in das geforkte **training_k8s_fluxcd_namespace_demo** Repository. Dieses haben wir ganz am Anfang geforkt
  und geklont. Hier soll nun die HelloWorld-Anwendung hinterlegt werden.  
  Dazu werden die Ergebnisse aus **Kustomize_Basics (Schulung Tag 2)**,
  `02_kustomize_structure/variante01`, übernommen und entsprechend angepasst.
    
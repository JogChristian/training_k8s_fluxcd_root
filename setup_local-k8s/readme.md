# Lokaler K3D

Der Kubernetes Cluster kann leicht neu angelegt werden und auch wieder gelöscht werden:

## Anlegen eines Clusters

```
./local-k8s.sh start
```

## Löschen eines Clusters

```
./local-k8s.sh delete
```

## Registry

Es wird ebenfalls eine lokale Registry eingerichtet. Dort können Images für die lokale Entwicklung gespeichert werden. Die URL für die Registry lautet:

```
http://k3d-registry.127.0.0.1.nip.io:5000
```

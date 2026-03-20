# Wazuh TP — Environnement Docker

> Environnement Wazuh entièrement conteneurisé : un manager et deux agents sur des distributions Linux différentes (Debian 12 et Ubuntu 22.04). Sans indexer ni dashboard — validation via les logs et fichiers d'alerte.

[![Wazuh](https://img.shields.io/badge/Wazuh-4.14.4-blue)](https://wazuh.com)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose/)

---

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│  Agent Debian   │     │  Agent Ubuntu   │     │  Wazuh Manager    │
│  (debian:12)    │────▶│  (ubuntu:22.04) │────▶│  (4.14.4)        │
└─────────────────┘     └─────────────────┘     └──────────────────┘
         │                        │                        │
         └────────────────────────┴────────────────────────┘
                          Réseau wazuh-net
```

| Composant | Image | Ports |
|-----------|-------|-------|
| Wazuh Manager | `wazuh/wazuh-manager:4.14.4` | 1514, 1515, 514, 55000 |
| Agent Debian | `debian:12-slim` + wazuh-agent | — |
| Agent Ubuntu | `ubuntu:22.04` + wazuh-agent | — |

---

## Prérequis

- **Docker** et **Docker Compose** (ou `docker-compose`)
- **4 Go RAM** minimum recommandé
- Accès internet pour le premier téléchargement des images

---

## Installation

### 1. Cloner le dépôt

```bash
git clone https://github.com/Thyvesma/wazuh-tp.git
cd wazuh-tp
```

### 2. Générer les certificats

```bash
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh
```

### 3. Lancer la stack

```bash
docker compose up -d
# ou : docker-compose up -d
```

### 4. Attendre le démarrage (~2 minutes)

Le manager met un peu de temps à démarrer. Vérifier les logs :

```bash
docker compose logs -f wazuh-manager
```

---

## Enrôlement des agents

Une fois le manager prêt :

```bash
# Agent Debian
docker exec -it wazuh-agent-debian /var/ossec/bin/agent-auth -m wazuh-manager

# Agent Ubuntu
docker exec -it wazuh-agent-ubuntu /var/ossec/bin/agent-auth -m wazuh-manager
```

---

## Vérification

```bash
# État des conteneurs
docker compose ps

# Agents connectés
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l

# Alertes en temps réel
docker exec -it wazuh-manager tail -F /var/ossec/logs/alerts/alerts.json
```

Ou lancer le script de vérification :

```bash
chmod +x scripts/verifier-installation.sh
./scripts/verifier-installation.sh
```

---

## Commandes utiles

| Action | Commande |
|--------|----------|
| Démarrer | `docker compose up -d` |
| Arrêter | `docker compose down` |
| Logs manager | `docker compose logs -f wazuh-manager` |
| Shell manager | `docker exec -it wazuh-manager /bin/bash` |
| Shell agent | `docker exec -it wazuh-agent-debian /bin/bash` |
| Statut Wazuh | `docker exec -it wazuh-manager /var/ossec/bin/ossec-control status` |

---

## Structure du projet

```
wazuh-tp/
├── docker-compose.yml       # Orchestration des services
├── config/
│   ├── wazuh_manager.conf   # Config manager (indexer désactivé)
│   └── certs/               # Certificats SSL (générés)
├── agents/
│   ├── agent-debian/        # Dockerfile + entrypoint
│   └── agent-ubuntu/
├── scripts/
│   ├── generate-certs.sh    # Génération des certificats
│   ├── verifier-installation.sh
│   ├── enroll-agents.sh
│   └── test-events.sh      # Génération d'événements de test
├── RAPPORT_TP_WAZUH.md     # Rapport détaillé
└── README.md
```

---

## Dépannage

| Problème | Solution |
|----------|----------|
| `docker compose` non trouvé | Utiliser `docker-compose` (avec tiret) |
| Permission denied sur script | `chmod +x scripts/*.sh` |
| Docker ne répond pas | Vérifier que Docker Desktop est lancé |
| Manager ne démarre pas | Attendre 2–3 min, vérifier `docker compose logs wazuh-manager` |

---

## Rapport PDF

Pour générer le rapport en PDF avec sommaire et liens cliquables :

```bash
pandoc RAPPORT_TP_WAZUH.md -o RAPPORT_TP_WAZUH.pdf --pdf-engine=xelatex --toc
```

Le fichier Markdown contient déjà les métadonnées (titre, auteur, date) et l'option `--toc` génère automatiquement le sommaire.

---

## Licence

Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)

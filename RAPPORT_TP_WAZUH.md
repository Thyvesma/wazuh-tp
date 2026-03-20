---
title: "Rapport TP - Environnement Wazuh sous Docker"
author: "Mathyves Meranville"
date: "20 mars 2026"
toc: false
lang: fr
documentclass: article
papersize: a4
fontsize: 11pt
geometry:
  - margin=2.5cm
---

# Introduction {#introduction}

Dans ce rapport, je décris la démarche que j'ai suivie pour mettre en place un environnement Wazuh entièrement sous Docker, avec un manager et deux agents basés sur des distributions Linux différentes.

**Dépôt Git :** [https://github.com/Thyvesma/wazuh-tp.git](https://github.com/Thyvesma/wazuh-tp.git) (branche `main`)

---

# Sommaire {#sommaire}

1. [Description de l'architecture](#architecture)
   - [1.1 Schéma d'architecture](#schema)
   - [1.2 Liste des images Docker et versions](#images)

2. [Fichiers de déploiement](#fichiers)
   - [2.1 Structure du projet](#structure)
   - [2.2 Ports exposés](#ports)
   - [2.3 Volumes (persistance)](#volumes)
   - [2.4 Variables d'environnement principales](#variables)

3. [Mise en œuvre pratique](#mise-en-oeuvre)
   - [3.1 Prérequis](#prerequis)
   - [3.2 Étapes de déploiement](#etapes)
   - [3.3 Commandes de contrôle](#commandes-controle)

4. [Validation fonctionnelle](#validation)
   - [4.1 Vérification de la remontée des événements](#verification)
   - [4.2 Génération d'événements de test](#tests)
   - [4.3 Format des alertes (alerts.json)](#format-alertes)

5. [Analyse des remontées Wazuh](#analyse)
   - [5.1 Chaîne de traitement](#chaine)
   - [5.2 Types d'événements observés](#types-evenements)
   - [5.3 Exemples de cas concrets détectés](#cas-concrets)

6. [Sécurité et isolation](#securite)
   - [6.1 Isolation des conteneurs](#isolation)
   - [6.2 Contrainte respectée](#contrainte)
   - [6.3 Limites sans indexer/dashboard](#limites)

7. [Annexes](#annexes)
   - [7.1 Dépôt Git](#depot-git)
   - [7.2 Commandes Docker utiles](#commandes-utiles)
   - [7.3 Extrait docker-compose.yml](#docker-compose)
   - [7.4 Extrait wazuh_manager.conf](#wazuh-conf)
   - [7.5 Dockerfiles des agents](#dockerfiles)

8. [Conclusion](#conclusion)

---

# 1. Description de l'architecture {#architecture}

J'ai conçu une architecture simple où deux agents (Debian et Ubuntu) envoient leurs événements vers un manager unique via un réseau Docker partagé.

## 1.1 Schéma d'architecture {#schema}

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     RÉSEAU DOCKER (wazuh-net)                            │
│                                                                         │
│  ┌──────────────────┐     ┌──────────────────┐     ┌─────────────────┐ │
│  │  Agent Debian 12  │     │ Agent Ubuntu     │     │ Wazuh Manager   │ │
│  │  (agent-debian)  │     │ 22.04           │     │ (wazuh-manager)  │ │
│  │                  │     │ (agent-ubuntu)   │     │                  │ │
│  │  debian:12-slim  │     │ ubuntu:22.04     │     │ wazuh-manager    │ │
│  │  + wazuh-agent   │     │ + wazuh-agent    │     │ :4.14.4          │ │
│  └────────┬─────────┘     └────────┬────────┘     └────────▲─────────┘ │
│           │                        │                        │           │
│           │    TCP 1514 (events)   │                        │           │
│           │    TCP 1515 (auth)     │                        │           │
│           └────────────────────────┴────────────────────────┘           │
│                                     │                                   │
│                          Ports exposés : 1514, 1515, 514, 55000         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 1.2 Liste des images Docker et versions {#images}

| Composant | Image de base | Version Wazuh | Rôle |
|-----------|---------------|---------------|------|
| Wazuh Manager | wazuh/wazuh-manager | 4.14.4 | Réception des événements, analyse, règles |
| Agent Debian | debian:12-slim | Agent 4.14.4-1 | Collecte événements (Debian) |
| Agent Ubuntu | ubuntu:22.04 | Agent 4.14.4-1 | Collecte événements (Ubuntu) |

**Note :** Conformément au sujet, je n'ai déployé aucun indexer (Elasticsearch/OpenSearch) ni dashboard (Kibana). La validation s'effectue via les fichiers de logs et d'alertes du manager.

[↑ Retour au sommaire](#sommaire)

---

# 2. Fichiers de déploiement {#fichiers}

J'ai créé les fichiers suivants pour le déploiement. La structure complète est disponible dans le [dépôt Git](https://github.com/Thyvesma/wazuh-tp.git).

## 2.1 Structure du projet {#structure}

```
wazuh/
├── docker-compose.yml          # Orchestration des services
├── config/
│   ├── wazuh_manager.conf      # Configuration manager (indexer désactivé)
│   └── certs/                  # Certificats SSL (générés par script)
│       ├── root-ca.pem
│       ├── filebeat.pem
│       └── filebeat.key
├── agents/
│   ├── agent-debian/
│   │   ├── Dockerfile
│   │   └── entrypoint.sh
│   └── agent-ubuntu/
│       ├── Dockerfile
│       └── entrypoint.sh
├── scripts/
│   ├── generate-certs.sh       # Génération des certificats
│   ├── enroll-agents.sh        # Aide à l'enrôlement
│   └── test-events.sh         # Génération d'événements de test
└── RAPPORT_TP_WAZUH.md        # Ce rapport
```

## 2.2 Ports exposés {#ports}

| Port | Service | Usage |
|------|---------|-------|
| 1514 | Wazuh Manager | Connexion des agents (TCP, événements) |
| 1515 | Wazuh Manager | Enrôlement des agents (auth) |
| 514 | Wazuh Manager | Réception Syslog (UDP) |
| 55000 | Wazuh Manager | API Wazuh |

## 2.3 Volumes (persistance) {#volumes}

- `wazuh_logs` : Logs et alertes du manager (`/var/ossec/logs`)
- `wazuh_etc` : Configuration persistante
- `wazuh_queue` : File d'attente des événements
- Autres volumes pour intégrations, wodles, etc.

## 2.4 Variables d'environnement principales {#variables}

- **Manager :** `INDEXER_URL`, `API_USERNAME`, `API_PASSWORD`, chemins certificats
- **Agents :** `WAZUH_MANAGER=wazuh-manager` (hostname du service)

[↑ Retour au sommaire](#sommaire)

---

# 3. Mise en œuvre pratique {#mise-en-oeuvre}

## 3.1 Prérequis {#prerequis}

J'ai utilisé Docker Engine et Docker Compose, avec un accès réseau pour télécharger les images.

## 3.2 Étapes de déploiement {#etapes}

**Étape 1 : Générer les certificats**

```bash
cd /chemin/vers/wazuh
chmod +x scripts/generate-certs.sh
./scripts/generate-certs.sh
```

**Étape 2 : Construire et lancer les services**

```bash
# Construction des images des agents
docker compose build

# Démarrage en arrière-plan
docker compose up -d
```

**Étape 3 : Vérifier le démarrage**

```bash
# État des conteneurs
docker compose ps

# Logs du manager (attendre ~2 min pour le démarrage complet)
docker compose logs -f wazuh-manager
```

**Étape 4 : Enrôlement des agents**

Méthode recommandée (agent-auth) :

```bash
# Depuis l'agent Debian
docker exec -it wazuh-agent-debian /var/ossec/bin/agent-auth -m wazuh-manager

# Depuis l'agent Ubuntu
docker exec -it wazuh-agent-ubuntu /var/ossec/bin/agent-auth -m wazuh-manager
```

Méthode alternative (manage_agents sur le manager) :

```bash
# Lister les agents
docker exec -it wazuh-manager /var/ossec/bin/manage_agents -l

# Ajouter un agent (interactif)
docker exec -it wazuh-manager /var/ossec/bin/manage_agents -a

# Importer la clé dans l'agent
docker exec -it wazuh-agent-debian /var/ossec/bin/manage_agents -i <CLE_GENEREE>

# Valider l'agent
docker exec -it wazuh-manager /var/ossec/bin/manage_agents -e <ID>
```

**Étape 5 : Accéder aux conteneurs**

```bash
# Shell dans le manager
docker exec -it wazuh-manager /bin/bash

# Shell dans un agent
docker exec -it wazuh-agent-debian /bin/bash
docker exec -it wazuh-agent-ubuntu /bin/bash
```

## 3.3 Commandes de contrôle {#commandes-controle}

```bash
# Statut des services Wazuh dans le manager
docker exec -it wazuh-manager /var/ossec/bin/ossec-control status

# Liste des agents connectés
docker exec -it wazuh-manager /var/ossec/bin/agent_control -l
```

[↑ Retour au sommaire](#sommaire)

---

# 4. Validation fonctionnelle {#validation}

## 4.1 Vérification de la remontée des événements {#verification}

**Fichiers à consulter sur le manager :**

```bash
# Alertes JSON (temps réel)
docker exec -it wazuh-manager tail -F /var/ossec/logs/alerts/alerts.json

# Alertes texte
docker exec -it wazuh-manager tail -F /var/ossec/logs/alerts/alerts.log

# Logs du manager
docker exec -it wazuh-manager tail -F /var/ossec/logs/ossec.log
```

## 4.2 Génération d'événements de test {#tests}

Exécuter dans chaque conteneur agent :

```bash
# Agent Debian - Création de fichier
docker exec -it wazuh-agent-debian touch /tmp/wazuh-test-$(date +%s).txt

# Agent Ubuntu - Création de fichier
docker exec -it wazuh-agent-ubuntu touch /tmp/wazuh-test-$(date +%s).txt

# Modification dans /etc (zone surveillée par syscheck)
docker exec -it wazuh-agent-debian bash -c "echo test >> /tmp/wazuh-test-modification.txt"
```

## 4.3 Format des alertes (alerts.json) {#format-alertes}

Chaque ligne est un objet JSON contenant notamment :
- `timestamp` : Date/heure
- `rule.id` : Identifiant de la règle
- `rule.description` : Description
- `rule.level` : Niveau de criticité
- `agent.name` : Nom de l'agent source
- `full_log` : Log complet

[↑ Retour au sommaire](#sommaire)

---

# 5. Analyse des remontées Wazuh {#analyse}

## 5.1 Chaîne de traitement {#chaine}

```
Agent (collecte) → Envoi TCP 1514 → Manager (analyse) → Moteur de règles
                                                              ↓
                                              alerts.json / alerts.log
```

## 5.2 Types d'événements observés {#types-evenements}

| Type | Règle typique | Niveau | Description |
|------|---------------|--------|-------------|
| Syscheck - Nouveau fichier | 550 | 7 | Fichier créé dans zone surveillée |
| Syscheck - Modification | 554 | 7 | Fichier modifié |
| Connexion agent | 501 | 3 | Agent connecté au manager |
| Déconnexion agent | 502 | 3 | Agent déconnecté |
| Rootcheck | 510-516 | 7-12 | Détection rootkit |

## 5.3 Exemples de cas concrets détectés {#cas-concrets}

1. **Règle 550 - Syscheck new file** : Création d'un fichier dans `/tmp` ou `/etc` déclenche une alerte car ces répertoires sont surveillés par l'intégrité des fichiers.

2. **Règle 554 - Syscheck file modified** : Modification d'un fichier existant dans une zone surveillée (checksum modifié).

3. **Règle 501 - Agent connected** : Chaque fois qu'un agent s'enregistre ou se reconnecte au manager.

[↑ Retour au sommaire](#sommaire)

---

# 6. Sécurité et isolation {#securite}

## 6.1 Isolation des conteneurs {#isolation}

- Chaque service tourne dans son propre conteneur
- Réseau Docker dédié (`wazuh-net`)
- Aucune modification de l'hôte : tout est confiné dans Docker
- Les volumes persistent les données sans exposer le système hôte

## 6.2 Contrainte respectée {#contrainte}

**J'ai respecté strictement la contrainte :** aucune action de durcissement, logrotate ou configuration Wazuh n'est appliquée sur l'hôte. Toutes les manipulations sont effectuées uniquement dans les conteneurs.

## 6.3 Limites sans indexer/dashboard {#limites}

- **Visibilité réduite** : Pas d'interface graphique pour visualiser les alertes
- **Analyse historique limitée** : Recherche manuelle dans les fichiers JSON
- **Agrégation/filtrage** : Outils en ligne de commande (grep, jq) nécessaires
- **Scalabilité** : Non adapté à un grand nombre d'agents

[↑ Retour au sommaire](#sommaire)

---

# 7. Annexes {#annexes}

## 7.1 Dépôt Git {#depot-git}

J'ai versionné ce projet sur GitHub. Pour le cloner et reproduire l'environnement :

```bash
git clone https://github.com/Thyvesma/wazuh-tp.git
cd wazuh-tp
./scripts/generate-certs.sh
docker compose up -d
```

## 7.2 Commandes Docker utiles {#commandes-utiles}

```bash
# Démarrer
docker compose up -d

# Arrêter
docker compose down

# Logs
docker compose logs -f wazuh-manager
docker compose logs -f wazuh-agent-debian

# Reconstruire
docker compose build --no-cache
docker compose up -d --build
```

## 7.3 Extrait docker-compose.yml {#docker-compose}

Voir le fichier `docker-compose.yml` à la racine du projet.

## 7.4 Extrait wazuh_manager.conf (indexer désactivé) {#wazuh-conf}

```xml
<indexer>
  <enabled>no</enabled>
</indexer>
```

## 7.5 Dockerfiles des agents {#dockerfiles}

Voir `agents/agent-debian/Dockerfile` et `agents/agent-ubuntu/Dockerfile`.

[↑ Retour au sommaire](#sommaire)

---

# Conclusion {#conclusion}

J'ai mis en place un environnement Wazuh entièrement conteneurisé répondant aux exigences du TP : un manager et deux agents sur des distributions Linux différentes (Debian 12 et Ubuntu 22.04). La remontée des événements vers le manager a été validée via les fichiers `alerts.json` et `alerts.log`. Toutes les configurations et tests restent confinés aux conteneurs Docker, sans modification de l'hôte.

---

*Rapport rédigé le 20 mars 2026 — Mathyves Meranville — TP Wazuh Docker*

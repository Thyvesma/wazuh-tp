#!/bin/bash
# Script pour générer des événements de test dans les conteneurs agents
# À exécuter manuellement dans chaque agent pour provoquer des alertes Wazuh
# Usage: docker exec -it wazuh-agent-debian bash -c "$(cat scripts/test-events.sh)"

echo "=== Génération d'événements de test Wazuh ==="
echo "Heure: $(date -Iseconds)"
echo ""

# 1. Création de fichier (déclenche syscheck / alert_new_files)
echo "1. Création d'un fichier de test..."
touch /tmp/wazuh-test-$(date +%s).txt
echo "Fichier créé dans /tmp"

# 2. Modification de fichier
echo "2. Modification d'un fichier..."
echo "Test Wazuh $(date)" >> /tmp/wazuh-test-modification.txt 2>/dev/null || echo "Test" > /tmp/wazuh-test-modification.txt

# 3. Exécution de commande (peut déclencher des règles)
echo "3. Exécution de commandes système..."
whoami
id
uname -a

# 4. Simulation d'échec SSH (insertion dans auth.log si disponible)
echo "4. Tentative de connexion SSH (génère événement auth)..."
# Sur Debian/Ubuntu, /var/log/auth.log peut ne pas exister dans le container
if [ -w /var/log/auth.log ]; then
    echo "$(date '+%b %d %H:%M:%S') $(hostname) sshd[$$]: Failed password for invalid user wazuh-test from 192.168.1.100" >> /var/log/auth.log
fi

# 5. Création dans /etc (surveillé par syscheck)
echo "5. Création dans /etc (zone surveillée)..."
touch /etc/wazuh-test-$(date +%s) 2>/dev/null && echo "Fichier créé" || echo "Permission refusée (normal)"

echo ""
echo "=== Fin des tests - Vérifiez alerts.json sur le manager ==="

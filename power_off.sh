#!/bin/zsh

# Déterminer le répertoire où se trouve le script
SCRIPT_DIR=$(dirname "$0")

# Fichier de configuration
CONFIG_FILE="$SCRIPT_DIR/config.txt"

# Source le fichier de configuration
source "$CONFIG_FILE"

# Chemin vers le fichier TXT avec les adresses IP des Raspberry Pi
PI_MAP_FILE="$SCRIPT_DIR/pi_map.txt"

# Initialiser un tableau associatif pour la PI_MAP
declare -A PI_MAP

# Lire le fichier pi_map.txt et remplir le tableau associatif PI_MAP
while IFS='=' read -r key value; do
    PI_MAP[$key]=$value
done < "$PI_MAP_FILE"

# Fonction pour vérifier si le Raspberry Pi est en ligne
is_pi_online() {
    local pi_ip=$1
    # Pinger le Raspberry Pi pour vérifier la connectivité
    ping -c 1 $pi_ip &> /dev/null
    return $?
}

# Fonction pour obtenir la date et l'heure actuelles dans un format approprié pour la commande `date`
get_current_time() {
    date +"%Y-%m-%d %H:%M:%S"
}

current_time=$(get_current_time)

# Fonction pour régler l'horloge d'un Raspberry Pi
set_clock() {
    local pi_ip=$1
    echo "Réglage de l'horloge pour le Raspberry Pi à $pi_ip à $current_time..."
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '$PI_PASSWORD' | sudo -S date -s '$current_time'"
}

# Fonction pour désactiver les notifications de mise à jour sur un Raspberry Pi
disable_update_notifications() {
    local pi_ip=$1
    echo "Désactivation des notifications de mise à jour pour le Raspberry Pi à $pi_ip..."
    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "dconf write /org/gnome/desktop/notifications/application/update-manager/enable false"
}

# Fonction pour éteindre un Raspberry Pi
shutdown_pi() {
    local pi_ip=$1
    # Vérifier si le Raspberry Pi est en ligne
    if is_pi_online "$pi_ip"; then
        echo "Le Raspberry Pi à $pi_ip est en ligne. ⏰ Procéder à la synchronisation de l'horloge et à l'arrêt..."
        #set_clock "$pi_ip"
        #disable_update_notifications "$pi_ip"
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$pi_ip" "echo '$PI_PASSWORD' | sudo -S poweroff"
    else
        echo "😴 Le Raspberry Pi à $pi_ip n'est pas en ligne. Ignorer l'arrêt."
    fi
}

# Logique principale du script
if [[ -n "$1" ]]; then
    # Si un argument est fourni, éteindre le Raspberry Pi spécifique par ID
    pi_id=$1
    pi_ip=${PI_MAP[$pi_id]}
    if [[ -n "$pi_ip" ]]; then
        echo "Tentative d'arrêt du Raspberry Pi avec ID: $pi_id et IP: $pi_ip"
        shutdown_pi "$pi_ip"
    else
        echo "❌ ID de Raspberry Pi invalide: $pi_id"
    fi
else
    # Si aucun argument n'est fourni, éteindre tous les Raspberry Pi
    for pi_id in ${(on)${(k)PI_MAP}}; do
        pi_ip=${PI_MAP[$pi_id]}
        echo "Tentative d'arrêt du Raspberry Pi avec IP: $pi_ip"
        shutdown_pi "$pi_ip"
    done
fi

echo "✅ Processus d'arrêt initié."

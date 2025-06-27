#!/bin/bash

CONFIG_FILE="/boot/config.txt"

# --- LIGNES À ADAPTER SELON TON CONFIG.TXT ---
# Motifs regex pour les lignes de l'écran Beepy
# Assure-toi que ces motifs correspondent exactement aux lignes dans ton config.txt
BEEPY_LINES=(
    "dtparam=spi=on"
    "dtoverlay=sharp-drm" # <--- MODIFIE CE NOM SI DIFFÉRENT !
    #"dtparam=dc=23"
    #"framebuffer_width="
    #"framebuffer_height="
    #"display_rotate=" # Inclut si cette ligne est spécifique à l'écran Beepy
)

# Motifs regex pour les lignes HDMI
HDMI_LINES=(
    "hdmi_force_hotplug=1"
    #"hdmi_group="
    #"hdmi_mode="
)
# ---------------------------------------------


function enable_beepy_display() {
    echo "Activation de l'écran Beepy et désactivation de l'HDMI..."

    # Décommenter les lignes du Beepy
    for line in "${BEEPY_LINES[@]}"; do
        sudo sed -i "/^#*${line}/s/^#*//g" "$CONFIG_FILE"
    done

    # Commenter les lignes HDMI
    for line in "${HDMI_LINES[@]}"; do
        sudo sed -i "/^${line}/s/^/#/" "$CONFIG_FILE"
    done

    echo "Modification de $CONFIG_FILE terminée. Un redémarrage est nécessaire."
    echo "Pour redémarrer maintenant, exécutez: sudo reboot"
}

function enable_hdmi_display() {
    echo "Activation de l'HDMI et désactivation de l'écran Beepy..."

    # Décommenter les lignes HDMI
    for line in "${HDMI_LINES[@]}"; do
        sudo sed -i "/^#*${line}/s/^#*//g" "$CONFIG_FILE"
    done

    # Commenter les lignes du Beepy
    for line in "${BEEPY_LINES[@]}"; do
        sudo sed -i "/^${line}/s/^/#/" "$CONFIG_FILE"
    done

    echo "Modification de $CONFIG_FILE terminée. Un redémarrage est nécessaire."
    echo "Pour redémarrer maintenant, exécutez: sudo reboot"
}

case "$1" in
    beepy)
        enable_beepy_display
        ;;
    hdmi)
        enable_hdmi_display
        ;;
    *)
        echo "Usage: $0 {beepy|hdmi}"
        echo "  beepy: Active l'écran du Beepy, désactive l'HDMI."
        echo "  hdmi:  Active l'HDMI, désactive l'écran du Beepy."
        ;;
esac

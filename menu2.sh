#!/bin/bash
#pre requis:
#sudo apt update
#sudo apt install wpasupplicant wireless-tools iproute2 whiptail

# Fonction pour obtenir l'adresse IP locale
get_local_ip() {
    ip addr show | grep -E 'inet (192\.168|10\.)' | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# Fonction pour vérifier si le WiFi est activé (retourne 0 si ON, 1 si OFF)
is_wifi_on() {
    ip link show wlan0 | grep -q "state UP"
    return $?
}

# Fonction pour obtenir le SSID courant
get_current_ssid() {
    sudo wpa_cli -i wlan0 status | grep '^ssid=' | cut -d= -f2
}


# Fonction pour vérifier si le Bluetooth est activé (retourne 0 si ON, 1 si OFF)
is_bluetooth_on() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        return 0
    else
        return 1
    fi
}

# Fonction pour vérifier si le rétroéclairage est activé (retourne 0 si ON, 1 si OFF)
is_backlight_on() {
    if python3 backlight.py --status | grep -q "ON"; then
        return 0
    else
        return 1
    fi
}

# Sous-menu Display
display_menu() {
    display_choix=$(whiptail --title "Display Options" --menu "Choose a display option" 10 50 2 \
    "W" "HDMI" \
    "E" "Beepy" 3>&1 1>&2 2>&3)

    case $display_choix in
        W)
            display.sh hdmi
            ;;
        E)
            display.sh beepy
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            return
            ;;
    esac

    reboot_choix=$(whiptail --title "Reboot" --menu "Do you want to reboot now?" 10 50 2 \
    "W" "Yes" \
    "E" "No" 3>&1 1>&2 2>&3)

    case $reboot_choix in
        W)
            sudo reboot
            ;;
        E)
            return
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            ;;
    esac
}

# Sous-menu WiFi avec toggle et affichage AP connecté
wifi_menu() {
    while true; do
        if is_wifi_on; then
            wifi_status="ON"
            toggle_option="WiFi [ON|off]"
        else
            wifi_status="off"
            toggle_option="WiFi [on|OFF]"
        fi

        current_ssid=$(get_current_ssid)
        if [ -z "$current_ssid" ]; then
            ap_status="Not connected"
        else
            ap_status="Connected to: $current_ssid"
        fi

        wifi_choix=$(whiptail --title "WiFi Options" --menu "$ap_status" 15 50 5 \
        "W" "$toggle_option" \
        "E" "List nearby WiFi networks" \
        "R" "Connect to a WiFi network" \
        "S" "Disconnect from WiFi" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $wifi_choix in
            W)
                if [ "$wifi_status" = "ON" ]; then
                    sudo ip link set wlan0 down
                    whiptail --title "WiFi" --msgbox "WiFi has been turned off." 10 50
                else
                    sudo ip link set wlan0 up
                    whiptail --title "WiFi" --msgbox "WiFi has been turned on." 10 50
                fi
                ;;
            E)
                networks=$(sudo iwlist wlan0 scan | grep 'ESSID' | sed 's/.*ESSID:"\(.*\)"/\1/' | grep -v '^$' | sort | uniq)
                whiptail --title "Nearby WiFi Networks" --msgbox "$networks" 20 50
                ;;
            R)
                networks=$(sudo iwlist wlan0 scan | grep 'ESSID' | sed 's/.*ESSID:"\(.*\)"/\1/' | grep -v '^$' | sort | uniq)
                menu_items=()
                i=1
                while read -r ssid; do
                    menu_items+=("$i" "$ssid")
                    i=$((i+1))
                done <<< "$networks"
                ssid_choice=$(whiptail --title "Select WiFi" --menu "Choose SSID" 20 50 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ -z "$ssid_choice" ]; then
                    continue
                fi
                ssid=$(echo "$networks" | sed -n "${ssid_choice}p")
                password=$(whiptail --title "WiFi Password" --passwordbox "Enter password for $ssid:" 10 50 3>&1 1>&2 2>&3)
                if [ -z "$password" ]; then
                    whiptail --title "WiFi" --msgbox "No password entered." 10 50
                    continue
                fi
                # Ajout et connexion via wpa_cli
                network_id=$(sudo wpa_cli -i wlan0 add_network | grep -E '^[0-9]+$')
                sudo wpa_cli -i wlan0 set_network "$network_id" ssid "\"$ssid\""
                sudo wpa_cli -i wlan0 set_network "$network_id" psk "\"$password\""
                sudo wpa_cli -i wlan0 enable_network "$network_id"
                sudo wpa_cli -i wlan0 select_network "$network_id"
                sudo wpa_cli -i wlan0 save_config
                sleep 5
                if sudo wpa_cli -i wlan0 status | grep -q "wpa_state=COMPLETED"; then
                    whiptail --title "WiFi" --msgbox "Connected to $ssid." 10 50
                else
                    whiptail --title "WiFi" --msgbox "Failed to connect to $ssid." 10 50
                fi
                ;;
            S)
                sudo wpa_cli -i wlan0 disconnect
                whiptail --title "WiFi" --msgbox "WiFi has been disconnected." 10 50
                ;;
            Q)
                break
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid choice." 10 50
                ;;
        esac
    done
}
# Sous-menu gestion des appareils Bluetooth
bluetooth_devices_menu() {
    while true; do
        bt_choice=$(whiptail --title "Bluetooth Devices" --menu "Choose an action" 20 50 7 \
        "W" "Make device visible" \
        "E" "Make device invisible" \
        "R" "Scan for nearby devices" \
        "S" "Connect to a nearby device" \
        "D" "List connected devices" \
        "F" "Disconnect from a connected device" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $bt_choice in
            W)
                sudo bluetoothctl discoverable on
                whiptail --title "Bluetooth" --msgbox "Device is now visible." 10 50
                ;;
            E)
                sudo bluetoothctl discoverable off
                whiptail --title "Bluetooth" --msgbox "Device is now invisible." 10 50
                ;;
            R)
                scan_output=$(timeout 10s bluetoothctl scan on | grep Device | awk '{$1=$2=""; print $0}' | sort | uniq)
                whiptail --title "Nearby Bluetooth Devices" --msgbox "${scan_output:-No devices found.}" 20 50
                ;;
            S)
                devices=$(timeout 10s bluetoothctl scan on | grep Device | awk '{print $3 " " substr($0, index($0,$3))}' | sort | uniq)
                menu_items=()
                while read -r line; do
                    mac=$(echo "$line" | awk '{print $1}')
                    name=$(echo "$line" | cut -d' ' -f2-)
                    menu_items+=("$mac" "$name")
                done <<< "$devices"
                if [ ${#menu_items[@]} -eq 0 ]; then
                    whiptail --title "Bluetooth" --msgbox "No devices found." 10 50
                    continue
                fi
                mac_choice=$(whiptail --title "Connect Bluetooth" --menu "Select device to connect" 20 50 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ -n "$mac_choice" ]; then
                    sudo bluetoothctl pair "$mac_choice"
                    sudo bluetoothctl connect "$mac_choice" && \
                        whiptail --title "Bluetooth" --msgbox "Connected to $mac_choice." 10 50 || \
                        whiptail --title "Bluetooth" --msgbox "Failed to connect to $mac_choice." 10 50
                fi
                ;;
            D)
                connected=$(bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}')
                whiptail --title "Connected Bluetooth Devices" --msgbox "${connected:-No connected devices.}" 20 50
                ;;
            F)
                connected=$(bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}')
                menu_items=()
                while read -r line; do
                    mac=$(echo "$line" | awk '{print $1}')
                    name=$(echo "$line" | cut -d' ' -f2-)
                    menu_items+=("$mac" "$name")
                done <<< "$connected"
                if [ ${#menu_items[@]} -eq 0 ]; then
                    whiptail --title "Bluetooth" --msgbox "No connected devices." 10 50
                    continue
                fi
                mac_choice=$(whiptail --title "Disconnect Bluetooth" --menu "Select device to disconnect" 20 50 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ -n "$mac_choice" ]; then
                    sudo bluetoothctl disconnect "$mac_choice"
                    whiptail --title "Bluetooth" --msgbox "Disconnected from $mac_choice." 10 50
                fi
                ;;
            Q)
                break
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid choice." 10 50
                ;;
        esac
    done
}

# Sous-menu Bluetooth avec toggle et gestion des appareils
bluetooth_menu() {
    while true; do
        if is_bluetooth_on; then
            bluetooth_status="ON"
            toggle_option="Bluetooth [ON|off]"
        else
            bluetooth_status="off"
            toggle_option="Bluetooth [on|OFF]"
        fi

        bluetooth_choix=$(whiptail --title "Bluetooth Options" --menu "Bluetooth is $bluetooth_status" 15 50 3 \
        "W" "$toggle_option" \
        "E" "Manage devices" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $bluetooth_choix in
            W)
                if [ "$bluetooth_status" = "ON" ]; then
                    sudo bluetoothctl power off
                    whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned off." 10 50
                else
                    sudo bluetoothctl power on
                    whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned on." 10 50
                fi
                ;;
            E)
                bluetooth_devices_menu
                ;;
            Q)
                break
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid choice." 10 50
                ;;
        esac
    done
}

# Sous-menu Backlight avec toggle
backlight_menu() {
    while true; do
        if is_backlight_on; then
            backlight_status="ON"
            toggle_option="Backlight [ON|off]"
        else
            backlight_status="off"
            toggle_option="Backlight [on|OFF]"
        fi

        backlight_choix=$(whiptail --title "Backlight Options" --menu "Backlight is $backlight_status" 10 50 2 \
        "W" "$toggle_option" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $backlight_choix in
            W)
                if [ "$backlight_status" = "ON" ]; then
                    python3 backlight.py --off
                    whiptail --title "Backlight" --msgbox "Backlight has been turned off." 10 50
                else
                    python3 backlight.py --on
                    whiptail --title "Backlight" --msgbox "Backlight has been turned on." 10 50
                fi
                ;;
            Q)
                break
                ;;
            *)
                whiptail --title "Error" --msgbox "Invalid choice." 10 50
                ;;
        esac
    done
}

# Récupération des infos système
local_ip=$(get_local_ip)
battery_percent=$(cat /sys/firmware/beepy/battery_percent)
# Boucle principale
while true; do
    current_time=$(date +"%H:%M:%S")
    if is_wifi_on; then
        wifi_menu_label="WiFi      [ON]"
    else
        wifi_menu_label="WiFi      [OFF]"
    fi
    if is_bluetooth_on; then
        bluetooth_menu_label="Bluetooth [ON]"
    else
        bluetooth_menu_label="Bluetooth [OFF]"
    fi
    if is_backlight_on; then
        backlight_menu_label="Backlight [ON]"
    else
        backlight_menu_label="Backlight [OFF]"
    fi

    choix=$(whiptail --title "$current_time - Battery: $battery_percent% - IP: $local_ip" --menu "Choose an option" 15 50 6 \
    "W" "$wifi_menu_label" \
    "E" "$bluetooth_menu_label" \
    "R" "Display" \
    "S" "$backlight_menu_label" \
    "Q" "Quit" 3>&1 1>&2 2>&3)

    case $choix in
        W)
            wifi_menu
            ;;
        E)
            bluetooth_menu
            ;;
        R)
            display_menu
            ;;
        S)
            backlight_menu
            ;;
        Q)
            whiptail --title "Goodbye" --msgbox "Goodbye!" 10 50
            exit 0
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            ;;
    esac
done

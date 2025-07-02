#!/bin/bash

# Fonction pour obtenir l'adresse IP locale
get_local_ip() {
    ip addr show | grep -E 'inet (192\.168|10\.)' | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# Fonction pour vérifier si le WiFi est activé (retourne 0 si ON, 1 si OFF)
is_wifi_on() {
    if ifconfig wlan0 | grep -q "UP"; then
        return 0
    else
        return 1
    fi
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
    if python3 /home/user/backlight.py --status | grep -q "ON"; then
        return 0
    else
        return 1
    fi
}

# Sous-menu Display
display_menu() {
    display_choix=$(whiptail --title "Display Options" --menu "Choose a display option" 10 50 2 \
    "W" "HDMI" \
    "S" "Beepy" 3>&1 1>&2 2>&3)

    case $display_choix in
        W)
            /home/user/display.sh hdmi
            ;;
        S)
            /home/user/display.sh beepy
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            return
            ;;
    esac

    reboot_choix=$(whiptail --title "Reboot" --menu "Do you want to reboot now?" 10 50 2 \
    "W" "Yes" \
    "S" "No" 3>&1 1>&2 2>&3)

    case $reboot_choix in
        W)
            sudo reboot
            ;;
        S)
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
        current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)
        if [ -z "$current_ssid" ]; then
            ap_status="Not connected"
        else
            ap_status="Connected to: $current_ssid"
        fi

        wifi_choix=$(whiptail --title "WiFi Options" --menu "$ap_status" 15 60 5 \
        "1" "$toggle_option" \
        "2" "List nearby WiFi networks" \
        "3" "Connect to a WiFi network" \
        "4" "Disconnect from WiFi" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $wifi_choix in
            1)
                if [ "$wifi_status" = "ON" ]; then
                    sudo ifconfig wlan0 down
                    whiptail --title "WiFi" --msgbox "WiFi has been turned off." 10 50
                else
                    sudo ifconfig wlan0 up
                    whiptail --title "WiFi" --msgbox "WiFi has been turned on." 10 50
                fi
                ;;
            2)
                networks=$(nmcli -t -f SSID,SIGNAL device wifi list | awk -F: '{printf "%s (%s%%)\n", $1, $2}' | grep -v '^$')
                whiptail --title "Nearby WiFi Networks" --msgbox "$networks" 20 60
                ;;
            3)
                ssid_list=$(nmcli -t -f SSID device wifi list | grep -v '^$' | sort | uniq)
                menu_items=()
                i=1
                while read -r ssid; do
                    menu_items+=("$i" "$ssid")
                    i=$((i+1))
                done <<< "$ssid_list"
                ssid_choice=$(whiptail --title "Select WiFi" --menu "Choose SSID" 20 60 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
                if [ -z "$ssid_choice" ]; then
                    continue
                fi
                ssid=$(echo "$ssid_list" | sed -n "${ssid_choice}p")
                password=$(whiptail --title "WiFi Password" --passwordbox "Enter password for $ssid:" 10 60 3>&1 1>&2 2>&3)
                if [ -z "$password" ]; then
                    whiptail --title "WiFi" --msgbox "No password entered." 10 50
                    continue
                fi
                nmcli device wifi connect "$ssid" password "$password" ifname wlan0 && \
                    whiptail --title "WiFi" --msgbox "Connected to $ssid." 10 50 || \
                    whiptail --title "WiFi" --msgbox "Failed to connect to $ssid." 10 50
                ;;
            4)
                nmcli device disconnect wlan0
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

# Sous-menu Bluetooth avec toggle
bluetooth_menu() {
    while true; do
        if is_bluetooth_on; then
            bluetooth_status="ON"
            toggle_option="Bluetooth [ON|off]"
        else
            bluetooth_status="off"
            toggle_option="Bluetooth [on|OFF]"
        fi

        bluetooth_choix=$(whiptail --title "Bluetooth Options" --menu "Bluetooth is $bluetooth_status" 10 50 2 \
        "1" "$toggle_option" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $bluetooth_choix in
            1)
                if [ "$bluetooth_status" = "ON" ]; then
                    sudo bluetoothctl power off
                    whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned off." 10 50
                else
                    sudo bluetoothctl power on
                    whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned on." 10 50
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
        "1" "$toggle_option" \
        "Q" "Back" 3>&1 1>&2 2>&3)

        case $backlight_choix in
            1)
                if [ "$backlight_status" = "ON" ]; then
                    python3 /home/user/backlight.py --off
                    whiptail --title "Backlight" --msgbox "Backlight has been turned off." 10 50
                else
                    python3 /home/user/backlight.py --on
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

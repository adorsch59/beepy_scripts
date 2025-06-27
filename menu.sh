#!/bin/bash

# Function to get the local IP address
get_local_ip() {
    ip addr show | grep -E 'inet (192\.168|10\.)' | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# Function to check if WiFi is on
is_wifi_on() {
    if ifconfig wlan0 | grep -q "UP"; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# Function to check if Bluetooth is on
is_bluetooth_on() {
    if bluetoothctl show | grep -q "Powered: yes"; then
        echo "ON"
    else
        echo "OFF"
    fi
}


# Function to check if Backlight is on
is_backlight_on() {
    # Assuming the Python script can output the status
    # Modify this part according to how your script indicates the status
    if python3 /home/user/backlight.py --status | grep -q "ON"; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# Function to handle the display submenu
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

    # Ask if the user wants to reboot now
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

# Function to handle WiFi
wifi_menu() {
    wifi_choix=$(whiptail --title "WiFi Options" --menu "Choose a WiFi option" 10 50 2 \
    "W" "Turn on WiFi" \
    "S" "Turn off WiFi" 3>&1 1>&2 2>&3)

    case $wifi_choix in
        W)
            sudo ifconfig wlan0 up
            whiptail --title "WiFi" --msgbox "WiFi has been turned on." 10 50
            ;;
        S)
            sudo ifconfig wlan0 down
            whiptail --title "WiFi" --msgbox "WiFi has been turned off." 10 50
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            ;;
    esac
}

# Function to handle Bluetooth
bluetooth_menu() {
    bluetooth_choix=$(whiptail --title "Bluetooth Options" --menu "Choose a Bluetooth option" 10 50 2 \
    "W" "Turn on Bluetooth" \
    "S" "Turn off Bluetooth" 3>&1 1>&2 2>&3)

    case $bluetooth_choix in
        W)
            sudo bluetoothctl power on
            whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned on." 10 50
            ;;
        S)
            sudo bluetoothctl power off
            whiptail --title "Bluetooth" --msgbox "Bluetooth has been turned off." 10 50
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            ;;
    esac
}

# Function to handle Backlight
backlight_menu() {
    backlight_choix=$(whiptail --title "Backlight Options" --menu "Choose a Backlight option" 10 50 2 \
    "W" "Turn on Backlight" \
    "S" "Turn off Backlight" 3>&1 1>&2 2>&3)

    case $backlight_choix in
        W)
            python3 /home/user/backlight.py --on
            whiptail --title "Backlight" --msgbox "Backlight has been turned on." 10 50
            ;;
        S)
            python3 /home/user/backlight.py --off
            whiptail --title "Backlight" --msgbox "Backlight has been turned off." 10 50
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice." 10 50
            ;;
    esac
}

# Get the local IP address
local_ip=$(get_local_ip)

# Read the battery percentage
battery_percent=$(cat /sys/firmware/beepy/battery_percent)

# Check WiFi status
wifi_status=$(is_wifi_on)

# Check Bluetooth status
bluetooth_status=$(is_bluetooth_on)

# Check Backlight status
backlight_status=$(is_backlight_on)

# Main menu loop
while true; do
    current_time=$(date +"%H:%M:%S")
    choix=$(whiptail --title "$current_time - Battery: $battery_percent% - IP: $local_ip" --menu "Choose an option" 15 50 6 \
    "W" "WiFi [$wifi_status]" \
    "S" "Bluetooth [$bluetooth_status]" \
    "Z" "Display" \
    "E" "Backlight [$backlight_status]" \
    "Q" "Quit" 3>&1 1>&2 2>&3)

    case $choix in
        W)
            wifi_menu
            wifi_status=$(is_wifi_on)
            ;;
        S)
            bluetooth_menu
            bluetooth_status=$(is_bluetooth_on)
            ;;
        Z)
            display_menu
            ;;
        E)
            backlight_menu
            backlight_status=$(is_backlight_on)
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

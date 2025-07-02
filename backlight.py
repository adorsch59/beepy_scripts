#!/usr/bin/env python3

import RPi.GPIO as GPIO
import os
import sys
import argparse

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)
GPIO.setwarnings(False)

def get_backlight_status():
    """
    Vérifie le statut actuel du rétroéclairage en se basant sur l'existence de /tmp/backlight.
    Retourne "ON" si le fichier existe, "OFF" sinon.
    """
    if os.path.exists('/tmp/backlight'):
        return "ON"
    else:
        return "OFF"

def set_backlight(status):
    """
    Définit l'état du rétroéclairage sur "on" ou "off".
    Met à jour l'état du GPIO et le fichier de statut /tmp/backlight.
    """
    if status == "on":
        GPIO.output(18, GPIO.HIGH)  # Allume la LED
        if not os.path.exists('/tmp/backlight'):
            os.mknod('/tmp/backlight')
        print("Backlight turned ON.")
    elif status == "off":
        GPIO.output(18, GPIO.LOW)   # Éteint la LED
        if os.path.exists('/tmp/backlight'):
            os.remove('/tmp/backlight')
        print("Backlight turned OFF.")

def main():
    parser = argparse.ArgumentParser(description="Contrôle le rétroéclairage via GPIO.")
    parser.add_argument(
        "--on",
        action="store_true",
        help="Allume le rétroéclairage."
    )
    parser.add_argument(
        "--off",
        action="store_true",
        help="Éteint le rétroéclairage."
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="Affiche le statut actuel du rétroéclairage (ON/OFF)."
    )
    parser.add_argument(
        "--toggle",
        action="store_true",
        help="Change l'état du rétroéclairage (ON vers OFF, OFF vers ON)."
    )
    
    args = parser.parse_args()

    try:
        # If no arguments are provided, act as if --toggle was specified
        #if not any(vars(args).values()):
        #    args.toggle = True

        if args.on:
            set_backlight("on")
        elif args.off:
            set_backlight("off")
        elif args.status:
            status = get_backlight_status()
            print(f"{status}")
        elif args.toggle:
            current_status = get_backlight_status()
            if current_status == "on":
                set_backlight("off")
            else:
                set_backlight("on")
        else:
            parser.print_help()
            sys.exit(1)
    finally:
        pass #GPIO.cleanup()
        
if __name__ == "__main__":
    main()

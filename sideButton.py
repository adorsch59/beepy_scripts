import RPi.GPIO as GPIO
import time
import os

# Configuration des paramètres
BUTTON_PIN = 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

### commands/actions
BATTERY = '/home/user/./battery.sh'
BACKLIGHT = 'python /home/user/backlight.py --toggle'

last_press_time = 0
press_count = 0

def read_file(file_path):
    # Exécuter la commande cat et capturer la sortie
    stream = os.popen(f'cat {file_path}')
    output = stream.read()
    stream.close()
    return output

def short_press():
    print("Pression courte détectée")
    os.system(BACKLIGHT)

def long_press():
    print("Pression longue détectée")
    #os.system(BATTERY)
    #batteryPercent = read_file('/sys/firmware/beepy/battery_percent')
    #batteryPercent = '% Battery = ' + batteryPercent
    #os.system(f'echo "{batteryPercent}" | wall')

def double_press():
    print("Double pression détectée")

def button_callback(channel):
    global last_press_time, press_count
    current_time = time.time()
    
    # Vérification du délai entre les pressions
    #if current_time - last_press_time < 1:  # Intervalle pour double pression
    #    press_count += 1
    #else:
    #    press_count = 1
    
    last_press_time = current_time

    if press_count == 2:
        double_press()
        press_count = 0
    else:
        # Attendre que le bouton soit relâché
        time.sleep(0.01)  # Un petit délai pour stabiliser
        if GPIO.input(BUTTON_PIN) == GPIO.LOW:  # Vérifier si toujours enfoncé
            time.sleep(1)  # Attendre une seconde pour détecter une pression longue
            if GPIO.input(BUTTON_PIN) == GPIO.LOW:  # Vérifier si toujours enfoncé
                long_press()
            else:
                short_press()
        else:
            short_press()

# Lier l'événement de pression du bouton
GPIO.add_event_detect(BUTTON_PIN, GPIO.FALLING, callback=button_callback, bouncetime=300)

try:
    print("Appuyez sur le bouton. Quittez avec Ctrl+C.")
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    GPIO.cleanup()

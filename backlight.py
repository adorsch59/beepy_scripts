import RPi.GPIO as GPIO
import os
GPIO.setmode(GPIO.BCM) 
GPIO.setup(18, GPIO.OUT)

if not os.path.exists('/tmp/backlight'):
	print('backlight is off')	
	GPIO.output(18, GPIO.HIGH)  # Turn on the LED
	os.mknod('/tmp/backlight')

else:
	print('backlight is on')	
	GPIO.output(18, GPIO.LOW)  # Turn off the LED
	os.remove('/tmp/backlight')

# coding=utf-8

import os
import sys
import base64
import signal
import RPi.GPIO as GPIO

#from apa102_pi.colorschemes import colorschemes

IS_PY3 = sys.version_info.major == 3
NUM_LED = 12
MOSI = 23  # Hardware SPI uses BCM 10 & 11. Change these values for bit bang mode
SCLK = 24  # e.g. MOSI = 23, SCLK = 24 for Pimoroni Phat Beat or Blinkt!
LED_BRIGHTNESS = 20
#KEY_GPIO = 24 #5
KEY_GPIO = 6 #6
KEY_STATE = 1
KEY_NEWSTATE = 1
FLAG_EXIT = 0
SYS_STATE = 0


def init_gpio():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(KEY_GPIO,GPIO.IN)
    
 
def key_checking():
    global KEY_STATE,FLAG_EXIT
    while FLAG_EXIT is not 1:
        KEY_STATE=GPIO.input(KEY_GPIO)


def sigint_handler(signum, frame):
    global FLAG_EXIT
    FLAG_EXIT = 1
    print('catched interrupt signal!')
    sys.exit(0)

if __name__ == '__main__':
    signal.signal(signal.SIGINT, sigint_handler)
    init_gpio()
    print("Please press the button on the board,press Ctrl + C to exit.")

    while True:
        if GPIO.input(KEY_GPIO) != KEY_STATE:
            print("Button pressed")
        KEY_STATE=GPIO.input(KEY_GPIO)
    FLAG_EXIT = 1
    sys.exit(0)


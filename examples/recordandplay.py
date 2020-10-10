# coding=utf-8

import os
import sys
import json
import time
import wave
import base64
import signal
import apa102_pi
import pyaudio
import threading
import RPi.GPIO as GPIO
from apa102_pi.driver import apa102
#from apa102_pi.colorschemes import colorschemes

IS_PY3 = sys.version_info.major == 3
NUM_LED = 12
MOSI = 23  # Hardware SPI uses BCM 10 & 11. Change these values for bit bang mode
SCLK = 24  # e.g. MOSI = 23, SCLK = 24 for Pimoroni Phat Beat or Blinkt!
LED_BRIGHTNESS = 20
#KEY_GPIO = 24 #5
KEY_GPIO = 6 #6
KEY_STATE = 0
FLAG_EXIT = 0
SYS_STATE = 0
WIDTH = 2
CHANNELS = 1

if IS_PY3:
    from urllib.request import urlopen
    from urllib.request import Request
    from urllib.error import URLError
    from urllib.parse import urlencode
    timer = time.perf_counter
else:
    from urllib2 import urlopen
    from urllib2 import Request
    from urllib2 import URLError
    from urllib import urlencode
    if sys.platform == "win32":
        timer = time.clock
    else:
        # On most other platforms the best timer is time.time()
        timer = time.time

class key_thread (threading.Thread):
    def __init__(self, name):
        threading.Thread.__init__(self)
        self.name = name
    def run(self):
        print ("Start thread:" + self.name)
        key_checking()
        print ("Exit thread:" + self.name)

class led_thread (threading.Thread):
    def __init__(self, name):
        threading.Thread.__init__(self)
        self.name = name
    def run(self):
        print ("Start thread:" + self.name)
        led()
        print ("Exit thread:" + self.name)


RATE = 16000

card = pyaudio.PyAudio()
stream = card.open(
			rate = RATE,
			format = card.get_format_from_width(WIDTH),
			channels = CHANNELS,
			input = True,
			start = False,)

class DemoError(Exception):
    pass


"""  TOKEN start """

def init_gpio():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(KEY_GPIO,GPIO.IN)
    
def init_apa102():
    global strip
    strip = apa102.APA102(num_led=12, global_brightness=20, mosi=MOSI, sclk=SCLK,
                      order='rbg')
    strip.clear_strip()
    
def key_checking():
    global KEY_STATE,FLAG_EXIT
    while FLAG_EXIT is not 1:
        KEY_STATE=GPIO.input(KEY_GPIO)

def led():
    global SYS_STATE,strip,last_state
    last_state = 0
    direction = 1
    while FLAG_EXIT is not 1:
        if last_state != SYS_STATE:
            LED_BRIGHTNESS = 20
            direction = 1
        elif last_state == 0:
            strip.clear_strip()
            continue
        if SYS_STATE == 0:
            strip.clear_strip()
            LED_BRIGHTNESS = 20
        elif SYS_STATE == 1:
            strip.set_pixel_rgb(6,0xFF0000,LED_BRIGHTNESS)
            strip.show()
            if LED_BRIGHTNESS == 100:
                direction = 0
            if LED_BRIGHTNESS == 0:
                direction = 1
            if direction == 1:
                LED_BRIGHTNESS += 1
            else:
                LED_BRIGHTNESS -= 1
            time.sleep(0.001)
        elif SYS_STATE == 2:
            strip.set_pixel_rgb(5,0x0000FF,LED_BRIGHTNESS)
            strip.set_pixel_rgb(6,0x0000FF,LED_BRIGHTNESS)
            strip.set_pixel_rgb(7,0x0000FF,LED_BRIGHTNESS)
            strip.show()
            if LED_BRIGHTNESS == 100:
                direction = 0
            if LED_BRIGHTNESS == 0:
                direction = 1
            if direction == 1:
                LED_BRIGHTNESS += 1
            else:
                LED_BRIGHTNESS -= 1
            time.sleep(0.001)
        last_state = SYS_STATE

def record():
    global KEY_STATE,strip,SYS_STATE,card
    print("LED is red!Start recording.")
    SYS_STATE = 1
# strip.set_pixel_rgb(24, 0xFFFFFF)  # White
# strip.set_pixel_rgb(40, 0x00FF00)  # Green
    wf = wave.open("temp.wav", 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(2)
    wf.setframerate(RATE)
    stream.start_stream()
    print("* recording")
    frames = []
    while KEY_STATE == 0:
        data = stream.read(1024)
        wf.writeframes(data)
        #frames.append(data)
        #print("adding frame")
    stream.stop_stream()
    wf.close
    SYS_STATE = 2
    print("Play recorded file")
    os.system("aplay temp.wav")
    SYS_STATE = 0


def sigint_handler(signum, frame):
    global FLAG_EXIT
    stream.stop_stream()
    stream.close()
    FLAG_EXIT = 1
    print('catched interrupt signal!')
    sys.exit(0)

if __name__ == '__main__':
    signal.signal(signal.SIGINT, sigint_handler)
    init_gpio()
    init_apa102()
    thread1 = key_thread("key_checking")
    thread1.start()
    thread2 = led_thread("led_thread")
    thread2.start()
    
    while FLAG_EXIT is not 1:
        if KEY_STATE == 0:
            record()
    FLAG_EXIT = 1
    exit


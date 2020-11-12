# coding=utf-8

import os
import sys
import json
import time
import wave
import base64
import signal
import pyaudio
import threading
#from apa102_pi.colorschemes import colorschemes

IS_PY3 = sys.version_info.major == 3

WIDTH = 2
CHANNELS = 1
RECORD_SECONDS = 5
CHUNK = 1024

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
def record():
    global KEY_STATE,strip,SYS_STATE,card
    SYS_STATE = 1
    stream.start_stream()
    print("* recording for 5 seconds")
    frames = []
    for i in range(0, int(RATE / CHUNK * RECORD_SECONDS)):
        data = stream.read(CHUNK)
        frames.append(data)

    stream.stop_stream()
    stream.close()
    wf = wave.open("recordtest.wav", 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(card.get_sample_size(card.get_format_from_width(WIDTH)))
    wf.setframerate(RATE)
    wf.writeframes(b''.join(frames))
    wf.close
    SYS_STATE = 2
    print("Play recorded file")
    os.system("aplay recordtest.wav")
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
    record()
    sys.exit(0)


from bravia_tv import BraviaRC
import types
import logging as log
import time


### Monkey-patch the method BraviaRC.set_volume_level()
# Translate .01-1 >>> 1-100 
# In the "bravia-tv" python module's set_volume_level() it multiplies input by 100
# My TV doesnt like that, and i dont want to modify the source so i can pull the dependency as much as id like
def patched_set_volume_level(self, volume, audio_output=None):
    if audio_output is None:
        audio_output = 'speaker'
    
    # Remove the *100 multiplication
    api_volume = str(int(round(volume)))  # <-- no * 100

    params = {'target': audio_output, 'volume': api_volume}
    jdata = self._jdata_build('setAudioVolume', params)
    self.bravia_req_json('audio', jdata)


# +--------------------+
# +-- Main Execution --+
# +--------------------+

# TV: 
ip_address = 'XXX.XXX.XXX.XXX'
name = None
pin = '0000' # The pin can be a pre-shared key (PSK) or you can receive a pin from the tv by making the pin 0000
# Settings:
default_volume = 10
default_source = 'SHIELD'
default_hdmi_title = 'HDMI 3/ARC'
default_hdmi_command = 'Hdmi3'

braviarc = BraviaRC(ip_address)
braviarc.set_volume_level = types.MethodType(patched_set_volume_level, braviarc)

# Connect to TV
def main():
    log.info(f'[PYTHON] Connecting to {ip_address}')
    braviarc.connect(pin, 'fooby', 'fooby')
    if not braviarc.is_connected():
        raise RuntimeError('[ERROR] Connection not detected after running connect()')

    # Power up and check power status
    log.info(f'[PYTHON] Powering up {ip_address} ')
    power_status = braviarc.get_power_status()
    if power_status == 'standby':
        braviarc.turn_on()
        power_status = braviarc.get_power_status()
    
    if power_status != 'active':
        raise RuntimeError('[ERROR] Power status hasnt changed to active after get_power_status()')

    # Normalize the volume
    log.info(f'[PYTHON] Normalizing volume 🔉')
    volume_info = braviarc.get_volume_info()
    if not volume_info:
        raise RuntimeError('[ERROR] No volume info returned after running get_volume_info()')
    current_volume = volume_info.get('volume')
    if current_volume > default_volume:
        log.info(f'[PYTHON] Volume is: {current_volume} thats too high 🔊')
        diff = current_volume - default_volume
        while diff > 0:
            braviarc.volume_down()
            diff -= 1
    elif current_volume < default_volume:
        log.info(f'[PYTHON] Volume is: {current_volume} thats too low 🔇')
        diff = default_volume - current_volume
        while diff > 0:
            braviarc.volume_up()
            diff -= 1
    else:
        log.info(f'[PYTHON] Volume is: {current_volume} thats just right 😮‍💨')



    # Check theinput
    source_list = {}
    log.info('[PYTHON] Normalizing input source 📺')
    log.info(f'[PYTHON] Setting input source: "{default_hdmi_command}"')
    
    # IR Command is faster and more reliable
    # braviarc.select_source(default_source)
    
    braviarc.send_command(default_hdmi_command)
    time.sleep(1) # get_playing_info() has a little lag before it populates
    playing_info = braviarc.get_playing_info()
 
    if playing_info.get('title') != default_hdmi_title:
        log.warning(f'[PYTHON] Source selction issue detected: {playing_info.get('title')} != {default_hdmi_title}')
        source_list = braviarc.load_source_list()
        if source_list.get(default_hdmi_title):
            log.info(f'[PYTHON] Found Source \"{default_hdmi_title}\" in source_list after failed select_source()')
            log.info(f'[PYTHON] Retrying source selection to "{default_hdmi_title}"')
            # IR Command is faster and more reliable
            # braviarc.select_source(default_source)
            braviarc.send_command(default_hdmi_command)
        else:
            raise RuntimeError(f'[ERROR] Source: \"{default_hdmi_title}\" doesnt appear to be connected according to load_source_list()')
    
    time.sleep(1)
    playing_info = braviarc.get_playing_info()

    if playing_info.get('title') != default_hdmi_title:
        raise RuntimeError(f'[ERROR] Source didnt change to \"{default_hdmi_title}\" after running select_source()')
    
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')

    bruteforce = 10
    while bruteforce > 0:
        braviarc.send_command('CursorUp')
        time.sleep(.01)
        braviarc.send_command('CursorLeft')
        time.sleep(.01)
        bruteforce -= 1

    # Tailscale Start
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorUp')
    braviarc.send_command('CursorUp')
    braviarc.send_command('CursorUp')
    braviarc.send_command('CursorUp')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorRight')
    braviarc.send_command('DpadCenter')
    time.sleep(7.5)
    braviarc.send_command('Return')
    time.sleep(2)

    # Jellyfin Start
    braviarc.send_command('CursorLeft')
    braviarc.send_command('DpadCenter')

    


## SEARCH LOGIC START
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('DpadCenter')
    # time.sleep(.5)

    # # J
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorDown')

    # # E
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorUp')
    # braviarc.send_command('DpadCenter')

    # # LL
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('DpadCenter')
    # braviarc.send_command('DpadCenter')

    # # Y
    # braviarc.send_command('CursorUp')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('DpadCenter')

    # # F
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('DpadCenter')

    # # I
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorUp')
    # braviarc.send_command('DpadCenter')

    # # N
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('DpadCenter')

    # # Search
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('CursorRight')
    # braviarc.send_command('DpadCenter')

    # exit()
    # braviarc.send_command('CursorUp')
    # braviarc.send_command('CursorDown')
    # braviarc.send_command('CursorLeft')
    # braviarc.send_command('CursorRight')
## SEARCH LOGIC END

    # print(json.dumps(source_list, indent=2))
    # print(json.dumps(playing_info, indent=2))
    # braviarc.set_volume_level(0)



    # print('applist::')
    # resp = braviarc.load_app_list()
    # print(resp)



    # # Get playing info
    # playing_content = braviarc.get_playing_info()

    # # Print current playing channel
    # print (playing_content.get('title'))

    # # Get volume info
    # volume_info = braviarc.get_volume_info()

    # # Print current volume
    # print (volume_info.get('volume'))
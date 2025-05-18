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
# Implement monkey-patch
braviarc.set_volume_level = types.MethodType(patched_set_volume_level, braviarc)

# Main Execution
def main():
    # Connect to device
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

    # Normalize the volume level
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


    # Normalize the input source
    source_list = {}
    log.info('[PYTHON] Normalizing input source 📺')
    log.info(f'[PYTHON] Setting input source: "{default_hdmi_command}"')

    # Change input source to default
    braviarc.send_command(default_hdmi_command)
    # [REMOVED] IR Command is faster and more reliable
    # braviarc.select_source(default_source)
    
    # Validate the input source change
    time.sleep(1) # get_playing_info() has a little lag before it populates
    playing_info = braviarc.get_playing_info()
    if playing_info.get('title') != default_hdmi_title:
        log.warning(f'[PYTHON] Source selction issue detected: {playing_info.get('title')} != {default_hdmi_title}')
        source_list = braviarc.load_source_list()

        # Give it one more try if the device shows in the source list (if its not there throw an error)
        if source_list.get(default_hdmi_title):
            log.info(f'[PYTHON] Found Source \"{default_hdmi_title}\" in source_list after failed select_source()')
            log.info(f'[PYTHON] Retrying source selection to "{default_hdmi_title}"')
            braviarc.send_command(default_hdmi_command)
            # [REMOVED] IR Command is faster and more reliable
            # braviarc.select_source(default_source)
        else:
            raise RuntimeError(f'[ERROR] Source: \"{default_hdmi_title}\" doesnt appear to be connected according to load_source_list()')
    
    # Throw exception if it still hasnt changed input sources
    time.sleep(1)
    playing_info = braviarc.get_playing_info()
    if playing_info.get('title') != default_hdmi_title:
        raise RuntimeError(f'[ERROR] Source didnt change to \"{default_hdmi_title}\" after running select_source()')
    
    # Make sure were in the AndroidTV menu
    # (In case we resume a recent session and it drops us somewhere non standard)
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')

    # Make sure the cursor is in the top-left corner of AndroidTV
    bruteforce = 10
    while bruteforce > 0:
        braviarc.send_command('CursorUp')
        time.sleep(.01)
        braviarc.send_command('CursorLeft')
        time.sleep(.01)
        bruteforce -= 1

    # Navigate to "Apps" tab in the top menu. (Make sure tab is selected with a few CursorUp's)
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
    
    # Navigate to "Tailscale", click it, and Wait for the app to start
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorRight')
    braviarc.send_command('DpadCenter')
    time.sleep(7.5)

    # Return to "Applications" page
    braviarc.send_command('Return')
    time.sleep(2)

    # Navigate to "Jellyfin" and click it
    braviarc.send_command('CursorLeft')
    braviarc.send_command('DpadCenter')

    log.info('[PYTHON] Done! 🎉 🎉 🎉 🎉 🎉')

# I was having issues with getting the Search to behave consistently
# Kept making me do licensing stuff after a power cycle.
# I prefer this over location based selection, but it is too unreliable
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

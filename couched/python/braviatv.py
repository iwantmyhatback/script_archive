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
    
# Connect to device by IP
def initiate_connection():
    log.info(f'[PYTHON] 🛜 🔳  Connecting to {ip_address}')
    braviarc.connect(pin, 'fooby', 'fooby')
    if braviarc.is_connected():
        log.info('[PYTHON] 🛜 ✅ Connection achieved\n')
    else:
        log.error('[PYTHON] 🛜 ❎ Connection not detected after running connect()')
        raise RuntimeError()

# Power up and check power status
def normalize_power_state():
    log.info(f'[PYTHON] ⚡️🔳 Normalizing power state {ip_address}')
    power_status = braviarc.get_power_status()
    if power_status == 'standby':
        log.info(f'[PYTHON] ⚡️🎚️ Sending power ON state')
        braviarc.turn_on()
        power_status = braviarc.get_power_status()
    
    if power_status != 'active':
        log.error('[PYTHON] ⚡️❎ Power status hasnt changed to active after get_power_status()')
        raise RuntimeError()
    else:
        log.info(f'[PYTHON] ⚡️✅ Power normalized\n')

# Normalize the volume level
def normalize_volume_level():
    log.info(f'[PYTHON] 🔉🔳 Normalizing volume')
    volume_info = braviarc.get_volume_info()
    if not volume_info:
        log.error('[PYTHON] 🔉❎ No volume info returned after running get_volume_info()')
        raise RuntimeError()
    current_volume = volume_info.get('volume')
    if current_volume > default_volume:
        log.info(f'[PYTHON] 🔉⏬ Volume is: {current_volume} thats too high')
        diff = current_volume - default_volume
        while diff > 0:
            braviarc.volume_down()
            diff -= 1
    elif current_volume < default_volume:
        log.info(f'[PYTHON] 🔉⏫ Volume is: {current_volume} thats too low')
        diff = default_volume - current_volume
        while diff > 0:
            braviarc.volume_up()
            diff -= 1
    else:
        log.info(f'[PYTHON] 🔉👌 Volume is: {current_volume} thats just right')

    volume_info = braviarc.get_volume_info()
    if not volume_info or volume_info.get('volume') != default_volume:
        log.error('[PYTHON] 🔉❎ Target volume not achieved')
        raise RuntimeError()
    else:
        log.info('[PYTHON] 🔉✅ Volume normalized\n')

# Normalize the input source
def normalize_input_source():
    source_list = {}
    log.info('[PYTHON] 🖥️ 🔳 Normalizing input source')
    log.info(f'[PYTHON] 🖥️ ⚙️ Setting input source: "{default_hdmi_command}"')

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
            log.info(f'[PYTHON] 🖥️ 🔍 Found Source \"{default_hdmi_title}\" in source_list after failed select_source()')
            log.info(f'[PYTHON] 🖥️ ⚙️ Retrying source selection to "{default_hdmi_title}"')
            braviarc.send_command(default_hdmi_command)
            # [REMOVED] IR Command is faster and more reliable
            # braviarc.select_source(default_source)
        else:
            log.error(f'[PYTHON] 🖥️ ❎ Source: \"{default_hdmi_title}\" doesnt appear to be connected according to load_source_list()')
            raise RuntimeError()
    
    # Throw exception if it still hasnt changed input sources
    time.sleep(1)
    playing_info = braviarc.get_playing_info()
    if playing_info.get('title') != default_hdmi_title:
        log.error(f'[PYTHON] 🖥️ ❎ Source didnt change to \"{default_hdmi_title}\" after running select_source()')
        raise RuntimeError()
    else:
        log.info('[PYTHON] 🖥️ ✅ Input source normalized\n')

# Navigate cursor to Home @ Top-Left Corner of the screen
def home_cursor():
    log.info('[PYTHON] 🏠✅ Homing cursor')
    # Make sure were in the AndroidTV menu
    # (In case we resume a recent session and it drops us somewhere non standard)
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')
    braviarc.send_command('Return')

    # Make sure the cursor is in the top-left corner of AndroidTV
    bruteforce = 17 # Down-most travel steps possible at current observation
    while bruteforce > 0:
        braviarc.send_command('CursorUp')
        bruteforce -= 1
    
    bruteforce = 7 # Right-most travel steps possible at current observation
    while bruteforce > 0:
        braviarc.send_command('CursorLeft')
        bruteforce -= 1

def navigate_apps_tab(*, home_cursor = True):
    if home_cursor:
        home_cursor()
    log.info('[PYTHON] 📁✅ Navigating to Apps tab')
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


# Navigate to "Tailscale" and click it
def start_tailscale(*, navigate_apps_tab = True, exit = True):
    if navigate_apps_tab:
        navigate_apps_tab(home_cursor = True)
    log.info('[PYTHON] ⚖️ ✅ Starting Tailscale')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorRight')
    braviarc.send_command('DpadCenter')
    time.sleep(7.5)
    if exit:
        braviarc.send_command('Return')
        time.sleep(2)


# Navigate to "Jellyfin" and click it
def start_jellyfin(*, navigate_apps_tab = True):
    if navigate_apps_tab:
        navigate_apps_tab(home_cursor = True)
    log.info('[PYTHON] 🪼 ✅ Starting Jellyfin')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('DpadCenter')


# I was having issues with getting the Search to behave consistently
# Kept making me do licensing stuff after a power cycle.
# I prefer this over location based selection, but it is too unreliable
def start_jellyfin_by_search(*, home_cursor = True):
    if home_cursor:
        home_cursor()
    
    log.info('[PYTHON] 🪼 ✅ Starting Jellyfin')
    braviarc.send_command('CursorRight')
    braviarc.send_command('DpadCenter')
    time.sleep(.5)

    # J
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorDown')

    # E
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorUp')
    braviarc.send_command('DpadCenter')

    # LL
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorDown')
    braviarc.send_command('DpadCenter')
    braviarc.send_command('DpadCenter')

    # Y
    braviarc.send_command('CursorUp')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('DpadCenter')

    # F
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorDown')
    braviarc.send_command('DpadCenter')

    # I
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorUp')
    braviarc.send_command('DpadCenter')

    # N
    braviarc.send_command('CursorLeft')
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorDown')
    braviarc.send_command('DpadCenter')

    # Search
    braviarc.send_command('CursorDown')
    braviarc.send_command('CursorRight')
    braviarc.send_command('CursorRight')
    braviarc.send_command('DpadCenter')



# +--------------------+
# +-- Main Execution --+
# +--------------------+

# TV: 
ip_address = 'XXX.XXX.XXX.XXX'
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
    log.info('[PYTHON] 🛋️ 🔳  Starting Couched Routine!\n')
    initiate_connection()
    normalize_power_state()
    normalize_volume_level()
    normalize_input_source()
    home_cursor()
    navigate_apps_tab(
        home_cursor=False
    )
    start_tailscale(
        navigate_apps_tab = False, 
        exit = True
    )
    start_jellyfin(
        navigate_apps_tab = False
    )

    log.info('[PYTHON] 🛋️ ✅ Finished Couched Routine! 🎉')



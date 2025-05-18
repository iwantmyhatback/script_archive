# "couched" 
### The button i click when i sit down on my couch,
### when complete it puts my tv in the ideal state for me to start browsing
Simple TCP interaction over the network to send a few commands which normalizes power state, input source, and volume level. Then it starts a couple apps and returns control to the user.

**Can be used in 2 entrypoint methods:**
1. `shell/run.sh` which runs baremetial on the machine
2. `shell/run_docker.sh` which creates, maintains, and runs a container to then execute `shell/run.sh`


### Order of execution:
1. **Execute `shell/run_docker.sh` :**
    1. Check if `docker` is installed and fail out if not
    2. Export environment variables from `configuration/environment.properties` if `ALREADY_SOURCED` is not already in the environment
    3. if :
    * Docker image does not exist
    * Repository HEAD has changed
    * `FORCE_DOCKER_REBUILD` is set to "TRUE"
        
    4. **Execute `shell/build_image.sh` :**
        1. Export environment variables from `configuration/environment.properties` if `ALREADY_SOURCED` is not already in the environment
        2. Deactivate and delete any existing bare metal Python virtual environment
        3. Get Python base Docker image
        4. Delete old python-wrapper Docker image
        5. Create a new python-wrapper Docker image
    5. Otherwise : 
        1. Deactivate and delete any existing bare metal Python virtual environment
    6. **Execute `shell/run.sh` :**
        1. Export environment variables from `configuration/environment.properties` if `ALREADY_SOURCED` is not already in the environment
        2. Create, activate, and upgrade Python virtual environment if not already existing
        3. Install requirements from `requirements.txt`
        4. **Execute `python/main.py` :**
            1. Create Python log handler
            2. Run couched


## Notes:
**API / IR Documentation**
<br>[Sony Bravia API](https://pro-bravia.sony.net/develop/integrate/ip-control/index.html)
<br>[Python Bravia TV](https://github.com/dcnielsen90/python-bravia-tv)
<br>
**IR Command Names**<br>
```json
{
  "Num1": "AAAAAQAAAAEAAAAAAw==",
  "Num2": "AAAAAQAAAAEAAAABAw==",
  "Num3": "AAAAAQAAAAEAAAACAw==",
  "Num4": "AAAAAQAAAAEAAAADAw==",
  "Num5": "AAAAAQAAAAEAAAAEAw==",
  "Num6": "AAAAAQAAAAEAAAAFAw==",
  "Num7": "AAAAAQAAAAEAAAAGAw==",
  "Num8": "AAAAAQAAAAEAAAAHAw==",
  "Num9": "AAAAAQAAAAEAAAAIAw==",
  "Num0": "AAAAAQAAAAEAAAAJAw==",
  "Num11": "AAAAAQAAAAEAAAAKAw==",
  "Num12": "AAAAAQAAAAEAAAALAw==",
  "Enter": "AAAAAQAAAAEAAAALAw==",
  "GGuide": "AAAAAQAAAAEAAAAOAw==",
  "ChannelUp": "AAAAAQAAAAEAAAAQAw==",
  "ChannelDown": "AAAAAQAAAAEAAAARAw==",
  "VolumeUp": "AAAAAQAAAAEAAAASAw==",
  "VolumeDown": "AAAAAQAAAAEAAAATAw==",
  "Mute": "AAAAAQAAAAEAAAAUAw==",
  "TvPower": "AAAAAQAAAAEAAAAVAw==",
  "Audio": "AAAAAQAAAAEAAAAXAw==",
  "MediaAudioTrack": "AAAAAQAAAAEAAAAXAw==",
  "Tv": "AAAAAQAAAAEAAAAkAw==",
  "Input": "AAAAAQAAAAEAAAAlAw==",
  "TvInput": "AAAAAQAAAAEAAAAlAw==",
  "TvAntennaCable": "AAAAAQAAAAEAAAAqAw==",
  "WakeUp": "AAAAAQAAAAEAAAAuAw==",
  "PowerOff": "AAAAAQAAAAEAAAAvAw==",
  "Sleep": "AAAAAQAAAAEAAAAvAw==",
  "Right": "AAAAAQAAAAEAAAAzAw==",
  "Left": "AAAAAQAAAAEAAAA0Aw==",
  "SleepTimer": "AAAAAQAAAAEAAAA2Aw==",
  "Analog2": "AAAAAQAAAAEAAAA4Aw==",
  "TvAnalog": "AAAAAQAAAAEAAAA4Aw==",
  "Display": "AAAAAQAAAAEAAAA6Aw==",
  "Jump": "AAAAAQAAAAEAAAA7Aw==",
  "PicOff": "AAAAAQAAAAEAAAA+Aw==",
  "PictureOff": "AAAAAQAAAAEAAAA+Aw==",
  "Teletext": "AAAAAQAAAAEAAAA/Aw==",
  "Video1": "AAAAAQAAAAEAAABAAw==",
  "Video2": "AAAAAQAAAAEAAABBAw==",
  "AnalogRgb1": "AAAAAQAAAAEAAABDAw==",
  "Home": "AAAAAQAAAAEAAABgAw==",
  "Exit": "AAAAAQAAAAEAAABjAw==",
  "PictureMode": "AAAAAQAAAAEAAABkAw==",
  "Confirm": "AAAAAQAAAAEAAABlAw==",
  "Up": "AAAAAQAAAAEAAAB0Aw==",
  "Down": "AAAAAQAAAAEAAAB1Aw==",
  "ClosedCaption": "AAAAAgAAAKQAAAAQAw==",
  "Component1": "AAAAAgAAAKQAAAA2Aw==",
  "Component2": "AAAAAgAAAKQAAAA3Aw==",
  "Wide": "AAAAAgAAAKQAAAA9Aw==",
  "EPG": "AAAAAgAAAKQAAABbAw==",
  "PAP": "AAAAAgAAAKQAAAB3Aw==",
  "TenKey": "AAAAAgAAAJcAAAAMAw==",
  "BSCS": "AAAAAgAAAJcAAAAQAw==",
  "Ddata": "AAAAAgAAAJcAAAAVAw==",
  "Stop": "AAAAAgAAAJcAAAAYAw==",
  "Pause": "AAAAAgAAAJcAAAAZAw==",
  "Play": "AAAAAgAAAJcAAAAaAw==",
  "Rewind": "AAAAAgAAAJcAAAAbAw==",
  "Forward": "AAAAAgAAAJcAAAAcAw==",
  "DOT": "AAAAAgAAAJcAAAAdAw==",
  "Rec": "AAAAAgAAAJcAAAAgAw==",
  "Return": "AAAAAgAAAJcAAAAjAw==",
  "Blue": "AAAAAgAAAJcAAAAkAw==",
  "Red": "AAAAAgAAAJcAAAAlAw==",
  "Green": "AAAAAgAAAJcAAAAmAw==",
  "Yellow": "AAAAAgAAAJcAAAAnAw==",
  "SubTitle": "AAAAAgAAAJcAAAAoAw==",
  "CS": "AAAAAgAAAJcAAAArAw==",
  "BS": "AAAAAgAAAJcAAAAsAw==",
  "Digital": "AAAAAgAAAJcAAAAyAw==",
  "Options": "AAAAAgAAAJcAAAA2Aw==",
  "Media": "AAAAAgAAAJcAAAA4Aw==",
  "Prev": "AAAAAgAAAJcAAAA8Aw==",
  "Next": "AAAAAgAAAJcAAAA9Aw==",
  "DpadCenter": "AAAAAgAAAJcAAABKAw==",
  "CursorUp":   "AAAAAgAAAJcAAABPAw==",
  "CursorDown": "AAAAAgAAAJcAAABQAw==",
  "CursorLeft": "AAAAAgAAAJcAAABNAw==",
  "CursorRight": "AAAAAgAAAJcAAABOAw==",
  "ShopRemoteControlForcedDynamic": "AAAAAgAAAJcAAABqAw==",
  "FlashPlus": "AAAAAgAAAJcAAAB4Aw==",
  "FlashMinus": "AAAAAgAAAJcAAAB5Aw==",
  "DemoMode": "AAAAAgAAAJcAAAB8Aw==",
  "Analog": "AAAAAgAAAHcAAAANAw==",
  "Mode3D": "AAAAAgAAAHcAAABNAw==",
  "DigitalToggle": "AAAAAgAAAHcAAABSAw==",
  "DemoSurround": "AAAAAgAAAHcAAAB7Aw==",
  "*AD": "AAAAAgAAABoAAAA7Aw==",
  "AudioMixUp": "AAAAAgAAABoAAAA8Aw==",
  "AudioMixDown": "AAAAAgAAABoAAAA9Aw==",
  "PhotoFrame": "AAAAAgAAABoAAABVAw==",
  "Tv_Radio": "AAAAAgAAABoAAABXAw==",
  "SyncMenu": "AAAAAgAAABoAAABYAw==",
  "Hdmi1": "AAAAAgAAABoAAABaAw==",
  "Hdmi2": "AAAAAgAAABoAAABbAw==",
  "Hdmi3": "AAAAAgAAABoAAABcAw==",
  "Hdmi4": "AAAAAgAAABoAAABdAw==",
  "TopMenu": "AAAAAgAAABoAAABgAw==",
  "PopUpMenu": "AAAAAgAAABoAAABhAw==",
  "OneTouchTimeRec": "AAAAAgAAABoAAABkAw==",
  "OneTouchView": "AAAAAgAAABoAAABlAw==",
  "DUX": "AAAAAgAAABoAAABzAw==",
  "FootballMode": "AAAAAgAAABoAAAB2Aw==",
  "iManual": "AAAAAgAAABoAAAB7Aw==",
  "Netflix": "AAAAAgAAABoAAAB8Aw==",
  "Assists": "AAAAAgAAAMQAAAA7Aw==",
  "FeaturedApp": "AAAAAgAAAMQAAABEAw==",
  "FeaturedAppVOD": "AAAAAgAAAMQAAABFAw==",
  "GooglePlay": "AAAAAgAAAMQAAABGAw==",
  "ActionMenu": "AAAAAgAAAMQAAABLAw==",
  "Help": "AAAAAgAAAMQAAABNAw==",
  "TvSatellite": "AAAAAgAAAMQAAABOAw==",
  "WirelessSubwoofer": "AAAAAgAAAMQAAAB+Aw==",
  "AndroidMenu": "AAAAAgAAAMQAAABPAw==",
  "RecorderMenu": "AAAAAgAAAMQAAABIAw==",
  "STBMenu": "AAAAAgAAAMQAAABJAw==",
  "MuteOn": "AAAAAgAAAMQAAAAsAw==",
  "MuteOff": "AAAAAgAAAMQAAAAtAw==",
  "AudioOutput_AudioSystem": "AAAAAgAAAMQAAAAiAw==",
  "AudioOutput_TVSpeaker": "AAAAAgAAAMQAAAAjAw==",
  "AudioOutput_Toggle": "AAAAAgAAAMQAAAAkAw==",
  "ApplicationLauncher": "AAAAAgAAAMQAAAAqAw==",
  "YouTube": "AAAAAgAAAMQAAABHAw==",
  "PartnerApp1": "AAAAAgAACB8AAAAAAw==",
  "PartnerApp2": "AAAAAgAACB8AAAABAw==",
  "PartnerApp3": "AAAAAgAACB8AAAACAw==",
  "PartnerApp4": "AAAAAgAACB8AAAADAw==",
  "PartnerApp5": "AAAAAgAACB8AAAAEAw==",
  "PartnerApp6": "AAAAAgAACB8AAAAFAw==",
  "PartnerApp7": "AAAAAgAACB8AAAAGAw==",
  "PartnerApp8": "AAAAAgAACB8AAAAHAw==",
  "PartnerApp9": "AAAAAgAACB8AAAAIAw==",
  "PartnerApp10": "AAAAAgAACB8AAAAJAw==",
  "PartnerApp11": "AAAAAgAACB8AAAAKAw==",
  "PartnerApp12": "AAAAAgAACB8AAAALAw==",
  "PartnerApp13": "AAAAAgAACB8AAAAMAw==",
  "PartnerApp14": "AAAAAgAACB8AAAANAw==",
  "PartnerApp15": "AAAAAgAACB8AAAAOAw==",
  "PartnerApp16": "AAAAAgAACB8AAAAPAw==",
  "PartnerApp17": "AAAAAgAACB8AAAAQAw==",
  "PartnerApp18": "AAAAAgAACB8AAAARAw==",
  "PartnerApp19": "AAAAAgAACB8AAAASAw==",
  "PartnerApp20": "AAAAAgAACB8AAAATAw=="
}
```
from os import environ as osEnviron
import platform
import socket
import logging as log
from pathlib import Path
from braviatv import main as braviatv


################
## Executions ##
################

def main():
    # Set the logging level for python
    LOG_LOCATION = str(osEnviron.get("LOG_LOCATION", ""))
    LOG_LEVEL = str(osEnviron.get("LOG_LEVEL", "INFO")).upper()

    log.root.handlers = []
    basicConfigHandler = [log.StreamHandler()]
    if LOG_LOCATION:
        logLocationPath = Path(LOG_LOCATION)
        logLocationPath.parent.absolute().mkdir(
            parents=True, 
            exist_ok=True
        )
        basicConfigHandler.append(
            log.FileHandler(
                filename=logLocationPath.absolute(), 
                mode='w'
            )
        )

    log.basicConfig(
        level=LOG_LEVEL,
        format="[%(levelname)s]\t%(message)s",
        handlers=basicConfigHandler
    )

    system_info()
    log.info('[SCRIPT] Completed Environmental Setup!')

    braviatv()




def system_info():
    try:
        sys_info = {}
        sys_info.update(Platform = platform.system())
        sys_info.update(Platform_release = platform.release())
        sys_info.update(Platform_version = platform.version())
        sys_info.update(Architecture = platform.machine())
        sys_info.update(Hostname = socket.gethostname())
        sys_info.update(Processor = platform.processor())
        log.info(f'[PY_ENV] System Information:')
        for key, value in sys_info.items():
            log.info(f'[PY_ENV] >>\t{key}: {value}')
        return sys_info
    except Exception as e:
        log.error(f'{e}')
        exit(1)


if __name__ == "__main__":
    main()

#! /usr/bin/env sh

#############################
##-------------------------##
##---- Definition Time ----##
##-------------------------##
#############################

    ##############################
    ## Define working directory ##
    ##############################

    INPUT_PATH="${1}"
    PWD="$( pwd )"


    ###########################
    ## Define Android device ##
    ###########################

    # Connect ADB to your headset in debug mode and accept 
    # run 'adb -d devices -l' and find out your device name prior to upload
    MY_HEADSET_HARDCODE=''
    MY_HEADSET="${MY_HEADSET:-${MY_HEADSET_HARDCODE}}"


    ###############################
    ## Define check_exp function ##
    ###############################

    # Check an expression
    # check_exp "[ $foo -lt $bar ]" "foo less than bar" "foo is less than bar!" "foo isnt less than bar"
    check_exp() {
        EXPRESSION="${1}"
        NAME="${2:-$EXPRESSION}"
        PASS="${3}"
        FAIL="${4}"

        # Ensure EXPRESSION is defined
        if [ -z "${EXPRESSION}" ]; then
            printf '[ERROR] Expression is not defined for check: %s \n' "${NAME}"
            exit 1
        fi

        # Print the check being performed
        printf '[CHECK] %s: %s \n' "${NAME}" "${EXPRESSION}"

        # Evaluate the expression using `eval`
        if eval "${EXPRESSION}"; then
            printf '[PASS] %s: ... %s \n' "${NAME}" "${PASS}"
            return 0
        else
            printf '[FAIL] %s: ... %s \n' "${NAME}" "${FAIL}"
            return 1
        fi
    }


############################
##------------------------##
##---- Execution Time ----##
##------------------------##
############################

    ##########################
    ## Check Android device ##
    ##########################

    check_exp "[ -n \"${MY_HEADSET}\" ]" \
        'MY_HEADSET Non-Empty' \
        "Using MY_HEADSET name: ${MY_HEADSET}" \
        '[ERROR] no MY_HEADSET name is set! Connect ADB to your headset in debug mode and accept. Then run "adb -d devices -l" and find out your device name. Then "export MY_HEADSET='\''<YOUR_HEADSET_NAME>'\''". Or you can modify MY_HEADSET_HARDCODE inside this script' || 
    exit 1


    #################################
    ## Check for Required binaries ##
    #################################

    # Make sure the adb binary is present on the system
    check_exp "command -v adb > /dev/null 2>&1" \
        'ADB BinaryExists' \
        'adb exists' \
        'Cant find adb for installation execution' || 
    exit 1

    # Make sure the apktool binary is present on the system
    check_exp "command -v apktool > /dev/null 2>&1" \
        'APKTOOL BinaryExists' \
        'apktool exists' \
        'Cant find apktool for installation execution' ||
    exit 1


    ##############################
    ## Validate input parameter ##
    ##############################

    check_exp "[ -n \"${INPUT_PATH}\" ]" \
        'INPUT_PATH Non-Empty' \
        "Using INPUT_PATH : ${INPUT_PATH}" \
        "no INPUT_PATH name is set! Using %{PWD}" ||
    INPUT_PATH="${PWD}"

    # Just being verbose since this could now be a non-input value (from pwd)
    INSTALLABLE_DIRECTORY="${INPUT_PATH}"

    # Make a temp directory for intermediate junk
    TARGET_FIND_TEMP="$( mktemp -d )"
    printf '[INFO] Created temp directory: "%s" \n' "${TARGET_FIND_TEMP}"

    # Setup temp cleanup
    # shellcheck disable=SC2064
    trap "rm -rf ${TARGET_FIND_TEMP}" EXIT

    # Do the actual APK finding
    printf '[INFO] Searching "%s" for valid APKs for upload \n' "${INSTALLABLE_DIRECTORY}"
    FOUND_APKS_DIRS="${TARGET_FIND_TEMP}/found_apks_dirs.txt"
    find "${INSTALLABLE_DIRECTORY}" -type f -name "*.apk" -exec dirname {} \; > "${FOUND_APKS_DIRS}"

    DIR_COUNT="$(wc -l < "${FOUND_APKS_DIRS}" | xargs)"
    check_exp "[ ${DIR_COUNT} -ge 1 ]" \
        'DIR_COUNT 1orMore' \
        "Counted: ${DIR_COUNT} APKs" \
        'No APKs found for sideload' ||
    exit 1


    { 
        while IFS= read -r CURRENT_DIR || [ -n "$CURRENT_DIR" ]; do
            ########################
            ## Check and announce ##
            ########################

            INSTALLABLE_DIRECTORY="$CURRENT_DIR"
            check_exp "[ -d \"${INSTALLABLE_DIRECTORY}\" ]" \
                'CURRENT_DIR IsDirectory' \
                'Validated input is a directory' \
                "Found INSTALLABLE_DIRECTORY: \"${INSTALLABLE_DIRECTORY}\" is not a directory" ||
            exit 1

            HEAD_FOOT='***************************************'
            printf '%s\n [INSTALLING "%s"] \n%s\n' "${HEAD_FOOT}" "${INSTALLABLE_DIRECTORY}" "${HEAD_FOOT}" 

            ###############
            ## Find APKs ##
            ###############

            # Make a temp directory for intermediate junk
            APK_TEMP_DIR="$( mktemp -d )"
            printf '[INFO] Created temp directory: "%s" \n' "${APK_TEMP_DIR}"

            # Setup temp cleanuptra
            # shellcheck disable=SC2064
            trap "rm -rf ${TARGET_FIND_TEMP} ${APK_TEMP_DIR}" EXIT

            # Do the actual APK finding
            printf '[INFO] Searching "%s" for valid APKs for upload \n' "${INSTALLABLE_DIRECTORY}"
            FOUND_APKS="${APK_TEMP_DIR}/found_apks.txt"
            find "${INSTALLABLE_DIRECTORY}" -type f -name "*.apk" > "${FOUND_APKS}"

            { 
                while IFS= read -r APK || [ -n "$APK" ]; do
                    printf '[INFO] Found: "%s" \n' "${APK}"
                done
            } < "${FOUND_APKS}"

            # Count paths (Whitespace safe)
            APK_COUNT="$( wc -l < "${FOUND_APKS}" | xargs )"

            check_exp "[ \"${APK_COUNT}\" -eq 1 ]" \
                'APK_COUNT Equals1' \
                "Counted ${APK_COUNT} APKs" \
                "Counted ${APK_COUNT} APKs" ||
            exit 1

            FOUND_APK="$( head -n1 "${FOUND_APKS}" )"


            ###################################################
            ## Extract Package name from the APK for install ##
            ###################################################

            # Make a temp directory for intermediate junk
            PACKAGE_TEMP_DIR="$( mktemp -d )"
            printf '[INFO] Created temp directory: "%s" \n' "${PACKAGE_TEMP_DIR}"

            # Setup temp cleanup
            # shellcheck disable=SC2064
            trap "rm -rf ${TARGET_FIND_TEMP} ${APK_TEMP_DIR} ${PACKAGE_TEMP_DIR}" EXIT

            # Decode the APK
            apktool -q decode "${FOUND_APK}" --output "${PACKAGE_TEMP_DIR}/apktool.out"

            # Get manifest path for decoded files
            MANIFEST_PATH="$( find "${PACKAGE_TEMP_DIR}/apktool.out" -type f -name 'AndroidManifest.xml' -maxdepth 1 )"

            # Derive package name from decoded AndroidManifest.xml
            PACKAGE_NAME="$( cat "${MANIFEST_PATH}" | grep -i 'package' | sed -nE 's|.*<manifest [^>]*package="([^"]*)".*|\1|p' )"

            # Validate parse package name
            check_exp "[ -n \"$PACKAGE_NAME\" ]" \
                'PACKAGE_NAME Non-Empty ' \
                "parsed package name: \"${PACKAGE_NAME}\" from: \"${FOUND_APK}\"" \
                "\"${PACKAGE_NAME}\" failed to parse a package name!" ||
            exit 1


            ########################################################
            ## Find OBB dir contents (.obb files or other assets) ##
            ########################################################

            # Make a temp directory for intermediate junk
            OBB_TEMP_DIR="$( mktemp -d )"
            printf '[INFO] Created temp directory: "%s" \n' "${OBB_TEMP_DIR}"

            # Setup temp cleanup
            # shellcheck disable=SC2064
            trap "rm -rf ${TARGET_FIND_TEMP} ${APK_TEMP_DIR} ${PACKAGE_TEMP_DIR} ${OBB_TEMP_DIR}" EXIT

            # Do the actual OBB finding
            printf '[INFO] Searching "%s" for valid OOBs for upload \n' "${INSTALLABLE_DIRECTORY}"
            FOUND_OBBS="${OBB_TEMP_DIR}/found_obbs.txt"

            OBB_DIR="$(find "${INSTALLABLE_DIRECTORY}" -type d -name "${PACKAGE_NAME}")"

            find "${OBB_DIR}" -type f > "${FOUND_OBBS}"

            { 
                while IFS= read -r OBB || [ -n "$OBB" ]; do
                    printf '[INFO] Found: "%s" \n' "${OBB}"
                done
            } < "${FOUND_OBBS}"

            # Count paths (Whitespace safe)
            OBB_COUNT="$( wc -l < "${FOUND_OBBS}" | xargs )"

            # Trigger OBB Skip if there are none
            SKIP_OBB=true
            check_exp \
                "[ \"${OBB_COUNT}\" -ge 1 ]" \
                'OBB_COUNT 1orMore' ||
            SKIP_OBB=false


            #######################################################
            ## Check for connection to target device for install ##
            #######################################################

            # ADB Options
            # -d: Use USB device (error if multiple devices connected).
            # -l: Use long output.
            DEVICE_STATUS=$( adb -d devices -l | grep -i "${MY_HEADSET}" | grep "device ")

            # Check device connection
            check_exp \
                "[ -n \"${DEVICE_STATUS}\" ]" \
                'DEVICE_STATUS Non-Empty for expected device' \
                "\"${MY_HEADSET}\" is connected and authorized" \
                "\"${MY_HEADSET}\" is not connected or not authorized!" ||
            exit 1
            

            ###############################
            ## Perform the APK uninstall ##
            ###############################

            printf '[INFO] Attempting a destructive install of: "%s" \n' "${FOUND_APK}"
            
            # Check for previous installation on the target
            PRE_INSTALL_PACKAGE_CHECK="$(adb shell pm list packages "${PACKAGE_NAME}")"
            SKIP_UNINSTALL='true'
            check_exp \
                "[ -z \"${PRE_INSTALL_PACKAGE_CHECK}\" ]" \
                'PRE_INSTALL_PACKAGE_CHECK Non-Empty' \
                "package \"${PACKAGE_NAME}\" is not installed!" \
                "package \"${PACKAGE_NAME}\" is already installed!" ||
            SKIP_UNINSTALL='false'

            # Perform uninstall if needed
            check_exp \
                "[ \"${SKIP_UNINSTALL}\" = 'false' ]" \
                'SKIP_UNINSTALL IsFalse' \
                "Performing uninstall of \"${PACKAGE_NAME}\"" \
                "Skipping uninstall of \"${PACKAGE_NAME}\"" 
            if [ ${?} -eq 0 ];then
                printf '[PASS] Equals=false: SKIP_UNINSTALL ... Performing uninstall of "%s" \n' "${PACKAGE_NAME}"
                # run the adb uninstall
                # ADB Options
                # -d: Use USB device (error if multiple devices connected).
                adb -d shell cmd package uninstall "${PACKAGE_NAME}"
                UNINSTALL_RESULT="${?}"

                check_exp "[ \"${UNINSTALL_RESULT}\" -eq 0 ]" \
                    'UNINSTALL_RESULT Equals0' \
                    "Got a zero return status from adb uninstall" \
                    "Got a non-zero return status from adb uninstall" ||
                exit 1
            fi


            #############################
            ## Perform the APK install ##
            #############################

            # run the adb install
            # ADB Options
            # -r: Replace existing application
            # -g: Grant all runtime permissions
            # -d: Use USB device (error if multiple devices connected).
            adb -d install -g -r "${FOUND_APK}"
            INSTALL_RESULT="${?}"
            check_exp "[ \"${INSTALL_RESULT}\" -eq 0 ]" \
                'INSTALL_RESULT Equals0' \
                "Got a zero return status from adb install" \
                "Got a non-zero return status from adb install" ||
            exit 1

            # Check installation on the target
            PACKAGE_CHECK="$(adb shell pm list packages "${PACKAGE_NAME}")"
            check_exp "[ -n \"${PACKAGE_CHECK}\" ]" \
                'PACKAGE_CHECK Non-Empty' \
                "indacting a good install for \"${PACKAGE_NAME}\"" \
                "package \"${PACKAGE_NAME}\" does not appear to be installed!" ||
            exit 1

            printf '[DONE] Installed "%s" on "%s" Successfully! \n' "${FOUND_APK}" "${MY_HEADSET}"

            ###################################
            ## Copy the OBB to Target Device ##
            ###################################

            # Skip OBB push if we found no OBBs
            if [ "${SKIP_OBB}" = "true" ];then
                printf '[DONE] Ending without OBB upload \n'
            else
                { 
                    while IFS= read -r OBB || [ -n "$OBB" ]; do
                        printf '[INFO] Pushing: "%s" \n' "${OBB}"
                        # Get the OBB directory path
                        OBB_DIRECTORY_PATH=$( dirname "$OBB ")
                        # Get the OBB directory name
                        OBB_DIRECTORY_NAME=$( basename "$OBB_DIRECTORY_PATH ")

                        # Create the OBB destination on target
                        # ADB Options
                        # -d: Use USB device (error if multiple devices connected).
                        adb -d shell mkdir -p "/sdcard/Android/obb/${OBB_DIRECTORY_NAME}"
                        OBB_MKDIR_RESULT="${?}"

                        check_exp "[ \"${OBB_MKDIR_RESULT}\" -eq 0 ]" \
                            'OBB_MKDIR_RESULT Equals0' \
                            "Got a zero return status from adb mkdir for OBB copy" \
                            "Got a non-zero return status from adb mkdir for OBB copy!" ||
                        exit 1


                        # Copy the OBB to destination on target
                        # ADB Options
                        # -d: Use USB device (error if multiple devices connected).
                        adb -d push "${OBB_DIRECTORY_PATH}" /sdcard/Android/obb/
                        OBB_PUSH_RESULT="${?}"

                        check_exp "[ \"${OBB_PUSH_RESULT}\" -eq 0 ]" \
                            'OBB_PUSH_RESULT Equals0' \
                            "Got a zero return status from adb push for OBB copy" \
                            "Got a non-zero return status from adb push for OBB copy!" ||
                        exit 1

                        printf '[DONE] Copied "%s" to "%s" Successfully! \n' "${OBB_DIRECTORY_PATH}" "${MY_HEADSET}"
                    done
                } < "${FOUND_OBBS}"
            fi
            HEAD_FOOT='***************************************'
            printf '%s\n [COMPLETED "%s"] \n%s\n' "${HEAD_FOOT}" "${INSTALLABLE_DIRECTORY}" "${HEAD_FOOT}" 
        done
    } < "${FOUND_APKS_DIRS}"


    ###################
    ## Call it a day ##
    ###################

    HEAD_FOOT='***************************************\n***************************************\n***************************************\n'
    printf '%s\n****** [INSTALLATION COMPLETED!] ******\n%s\n' "${HEAD_FOOT}" "${HEAD_FOOT}" 

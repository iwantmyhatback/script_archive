# APK Installer and Validator Script

This script automates the process of finding, validating, and installing APK files on an Android device connected via ADB. It ensures that all necessary binaries are available, extracts metadata from APKs, and manages dependencies like OBB files for successful installation.

## Features

- Validates prerequisites such as ADB and apktool.
- Searches for APK files within a specified directory.
- Extracts and validates package names from APK files.
- Installs APKs and corresponding OBB files on a connected Android device.
- Handles device connection validation and installation cleanup.
- Allows parameterized inputs and provides robust logging and error reporting.

## Prerequisites

Ensure the following are installed and available in your `PATH`:

1. **ADB** - Android Debug Bridge.
2. **apktool** - Tool for decoding and rebuilding APKs.

## Usage

```sh
apk_sideload_q2.sh [INPUT_PATH]
```

### Parameters

- `INPUT_PATH`: The directory to search for APK files. If not provided, defaults to the current working directory.

### Environment Variables

- `MY_HEADSET`: (Optional) Name of the Android device as recognized by ADB. This can also be hardcoded within the script by modifying the `MY_HEADSET_HARDCODE` variable.

### Instructions

1. Connect your Android device in debug mode and ensure ADB recognizes it.
   ```sh
   adb -d devices -l
   ```
2. If `MY_HEADSET` is not already set, export it:
   ```sh
   export MY_HEADSET='<YOUR_DEVICE_NAME>'
   ```
3. Run the script with the desired directory as input:
   ```sh
   apk_sideload_q2.sh /path/to/directory
   ```
   If no directory is specified, the script uses the current working directory.

## Script Workflow

1. **Device Validation**: Checks if the connected device matches `MY_HEADSET`.
2. **Prerequisite Validation**: Ensures `adb` and `apktool` are available.
3. **APK Discovery**: Searches the specified directory for `.apk` files.
4. **Package Name Extraction**: Parses the APK's `AndroidManifest.xml` to extract the package name.
5. **Installation**:
   - Uninstalls existing versions of the APK (if any).
   - Installs the new APK with all required permissions.
6. **OBB Handling**: Searches for and uploads OBB files associated with the APK to the device's storage.
7. **Logging**: Provides detailed logs at every step for troubleshooting.

## Logs and Cleanup

- Temporary directories are created for intermediate operations and automatically cleaned up after execution.
- Logs provide detailed information about every step, including success and error states.

## Troubleshooting

- If the script fails due to a missing prerequisite, ensure `adb` and `apktool` are installed and accessible.
- Verify that the Android device is connected and authorized via ADB.
- Check the logs for detailed error messages and resolve any issues.

## Example

```sh
apk_sideload_q2.sh /home/user/apk_directory
```

This will locate APK files in `/home/user/apk_directory`, validate and install them on the connected device, and handle any associated OBB files.


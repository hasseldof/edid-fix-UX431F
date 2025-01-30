# EDID Fix for Asus UX431F

This repository provides a quick fix for black screen issues on Linux when using the Asus UX431F laptop by correcting the embedded display's EDID (Extended Display Identification Data).

## Files

### `edidfix.py`
This Python script contains the EDID data extracted from the Asus UX431F display. It performs the following modifications:
- Corrects the invalid major version number, setting it to `1.4`
- Changes the second occurrence of the monitor name tag identifier (`0xFE`) to `0xFC`
- Recalculates and fixes the checksum to maintain EDID integrity
- Outputs the corrected EDID as `edid.bin`

### `edid.bin`
This file contains the corrected EDID, which can be used directly without running the script.

### `edidfix.sh`
This Bash script automates the process of applying the fixed EDID by:
- Copying `edid.bin` to `/usr/lib/firmware/edid/`
- Configuring `mkinitcpio` or `dracut` to include the EDID in the initramfs
- Updating systemd-boot entries to apply the EDID fix at boot
- Regenerating the initramfs to ensure the fix is applied

## Usage Instructions

### 1. Running the Python Script (Optional)
If you need to regenerate the corrected EDID file, run:
```bash
python3 edidfix.py
```
This will generate `edid.bin` in the current directory.

### 2. Applying the EDID Fix
Run the provided Bash script to set up the corrected EDID:
```bash
sudo ./edidfix.sh
```
This script requires root privileges and will configure the system to load the fixed EDID at boot.

### 3. Reboot
After running the script, reboot your system for the changes to take effect.

## Notes
- Ensure that `mkinitcpio` or `dracut` is installed, as the script relies on one of them to regenerate the initramfs.
- This fix is specifically designed for the Asus UX431F laptop and may not work for other devices.
- If using a different Linux distribution with a non-systemd bootloader, manual configuration may be required.

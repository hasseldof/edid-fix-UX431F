#!/bin/bash

EDID_FILE="edid.bin"
EDID_DIR="/usr/lib/firmware/edid"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
DRACUT_CONF_DIR="/etc/dracut.conf.d"
DRACUT_EDID_CONF="$DRACUT_CONF_DIR/edid.conf"
KERNEL_PARAM="drm.edid_firmware=eDP-1:edid/$EDID_FILE"

# Detect systemd-boot loader entries path
if [[ -d "/boot/loader/entries" ]]; then
    ENTRIES_DIR="/boot/loader/entries"
elif [[ -d "/efi/loader/entries" ]]; then
    ENTRIES_DIR="/efi/loader/entries"
else
    echo "Error: Could not find systemd-boot loader entries!"
    exit 1
fi

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root (use sudo)."
    exit 1
fi

# Ensure the EDID directory exists
echo "Creating EDID firmware directory at $EDID_DIR..."
mkdir -p "$EDID_DIR"

# Copy EDID file
if [[ ! -f "$EDID_FILE" ]]; then
    echo "Error: EDID file '$EDID_FILE' not found in the current directory."
    exit 1
fi
echo "Copying $EDID_FILE to $EDID_DIR..."
cp "$EDID_FILE" "$EDID_DIR"

# Check which initramfs generator is installed
if command -v dracut &>/dev/null; then
    INITRAMFS_TYPE="dracut"
elif command -v mkinitcpio &>/dev/null; then
    INITRAMFS_TYPE="mkinitcpio"
else
    echo "Error: Neither mkinitcpio nor dracut is installed. Exiting."
    exit 1
fi

# Configure EDID file inclusion for initramfs
if [[ "$INITRAMFS_TYPE" == "mkinitcpio" ]]; then
    echo "Using mkinitcpio..."
    if ! grep -q "$EDID_DIR/$EDID_FILE" "$MKINITCPIO_CONF"; then
        echo "Adding EDID file to mkinitcpio.conf..."
        sed -i "/^FILES=/ s|)$| \"$EDID_DIR/$EDID_FILE\" )|" "$MKINITCPIO_CONF"
    else
        echo "EDID file already included in mkinitcpio.conf."
    fi
elif [[ "$INITRAMFS_TYPE" == "dracut" ]]; then
    echo "Using dracut..."
    mkdir -p "$DRACUT_CONF_DIR"
    echo "Adding EDID file to dracut configuration..."
    echo "install_items+=\" /usr/lib/firmware/edid/$EDID_FILE \"" > "$DRACUT_EDID_CONF"
fi

# Append kernel parameter to all systemd-boot entries
echo "Updating systemd-boot entries in $ENTRIES_DIR..."
for entry in "$ENTRIES_DIR"/*.conf; do
    if [[ -f "$entry" ]]; then
        if grep -q "^options" "$entry"; then
            # Append the EDID parameter to the existing options line if not already present
            if ! grep -q "$KERNEL_PARAM" "$entry"; then
                sudo su -c "sed -i '/^options/ s|\$| $KERNEL_PARAM|' '$entry'"
            else
                echo "Kernel parameter already present in: $entry"
            fi
        else
            # Add a new options line if none exists
            sudo su -c "echo -e '\noptions $KERNEL_PARAM' >> '$entry'"
        fi
        echo "Updated: $entry"
    fi
done

echo "Regenerating initramfs using $INITRAMFS_TYPE..."
if [[ "$INITRAMFS_TYPE" == "mkinitcpio" ]]; then
    mkinitcpio -P
elif [[ "$INITRAMFS_TYPE" == "dracut" ]]; then
    dracut --force --regenerate-all
fi

echo "Setup complete! Reboot to apply changes."

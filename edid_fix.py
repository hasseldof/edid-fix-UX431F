#!/usr/bin/env python3

import sys

output_edid = "edid.bin"

def fix_monitor_name_tag(data):
    """
    Change the second occurrence of 0xFE to 0xFC.
    """
    fe_indices = [i for i, byte in enumerate(data) if byte == 0xFE]

    if len(fe_indices) >= 2:
        # Change only the second occurrence
        data[fe_indices[1]] = 0xFC
    else:
        print("Warning: Less than two occurrences of 0xFE found. No changes made.")

    return data

def fix_checksum(data):
    """
    Adjust the last byte (checksum) so that the sum of all 128 bytes == 0 mod 256.
    """
    # compute the sum of all 128 bytes
    total_sum = sum(data) & 0xFF
    # We need the total to be 0 mod 256. So figure out the amount to add:
    adjustment = (-total_sum) & 0xFF
    # Apply that adjustment to the last byte
    data[-1] = (data[-1] + adjustment) & 0xFF
    return data

def fix_version(data):
    """
    Adjust the byte at offset 0x12 to correct major version
    """
    data[0x12] = 0x01  # Major version = 1
    return data

def fix_edid(input_file):
    with open(input_file, 'rb') as f:
        data = bytearray(f.read())

    if len(data) != 128:
        raise ValueError(f"Input file '{input_file}' is not exactly 128 bytes, so it's not a valid single-block EDID.")

    data = fix_version(data)
    data = fix_monitor_name_tag(data)
    data = fix_checksum(data)
    return data
    
if __name__ == "__main__":

    hex_data = """
    00 ff ff ff ff ff ff 00 38 70 35 00 00 00 00 00
    01 1c 02 04 a5 1f 11 78 02 a1 05 a1 56 4f a0 27
    0f 50 54 00 00 00 01 01 01 01 01 01 01 01 01 01
    01 01 01 01 01 01 1a 36 80 a0 70 38 1f 40 30 20
    35 00 35 ae 10 00 00 1a 00 00 00 00 00 00 00 00
    00 00 00 00 00 00 00 00 00 1a 00 00 00 fe 00 43
    45 43 20 50 41 0a 20 20 20 20 20 20 00 00 00 fe
    00 4c 4d 31 34 30 4c 46 2d 33 4c 0a 20 20 00 26
    """.replace("\n", " ").strip()
    
    raw_bytes = bytes.fromhex(hex_data)
    
    with open("prefix_edid.bin", "wb") as f:
        f.write(raw_bytes)
    
    print(f"Initital hex string is:")
    print(' '.join(f'{b:02x}' for b in raw_bytes))
    
    data = fix_edid("prefix_edid.bin")

    with open(output_edid, 'wb') as f:
        f.write(data)

    print(f"Fixed EDID is:")
    print(' '.join(f'{b:02x}' for b in data))
    print(f"EDID fixed and written to '{output_edid}'.")
    print(f" - Version changed to 1.4, Display Product Name set and checksum corrected.")
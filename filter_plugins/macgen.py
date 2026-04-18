#!/usr/bin/env python3
import hashlib
import sys

from ansible._internal._templating._utils import _OmitType

def is_omitted(value):
    """
    Return True if value is ommited
    """
    if isinstance(value, _OmitType):
        return True
    return False

def macgen(ip, prefix="00:0C:30"):
    """
    Generate a MAC address from an IP address and Vendor prefix.

    Args:
        ip (str): IP address, e.g. "192.168.1.10"
        prefix (str): Vendor prefix in "XX:XX:XX" format

    Returns:
        str: MAC address "XX:XX:XX:XX:XX:XX"
    """
    if is_omitted(ip):
        return

    ip_bytes = hashlib.md5(ip.encode()).digest()

    mac_suffix = [f"{b:02X}" for b in ip_bytes[:3]]

    mac = prefix.upper().split(":") + mac_suffix
    return ":".join(mac)

class FilterModule(object):
    def filters(self):
        return {
            "macgen": macgen
        }

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: ./macgen.py <IP_ADDRESS> [VENDOR_PREFIX]")
        sys.exit(1)

    ip = sys.argv[1]
    prefix = sys.argv[2] if len(sys.argv) > 2 else "00:0C:30"

    mac = macgen(ip, prefix)
    print(mac)

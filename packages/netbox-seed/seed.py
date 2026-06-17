from django.contrib.contenttypes.models import ContentType
from django.utils.text import slugify

from dcim.models import (
    Device,
    DeviceRole,
    DeviceType,
    Interface,
    MACAddress,
    Manufacturer,
    Site,
)
from ipam.models import IPAddress, Prefix

# Run from repo root with:
#   ssh nixbox.s 'sudo -u netbox netbox-manage shell' < packages/netbox-seed/seed.py
#
# Idempotent seed for the home infrastructure baseline. NetBox remains inventory/IPAM;
# Nix/OpenWRT remain deployment/config sources of truth.

site, _ = Site.objects.update_or_create(
    slug="home", defaults={"name": "home", "status": "active"}
)

role_specs = {
    "router": "673ab7",
    "access-point": "3f51b5",
    "switch": "607d8b",
    "server": "009688",
    "workstation": "4caf50",
    "laptop": "8bc34a",
    "bmc": "795548",
    "printer": "9e9e9e",
    "iot": "ff9800",
}
roles = {}
for name, color in role_specs.items():
    roles[name], _ = DeviceRole.objects.update_or_create(
        slug=slugify(name), defaults={"name": name, "color": color}
    )

manufacturers = {}
for name in ["Generic", "GL.iNet", "HP", "Framework"]:
    manufacturers[name], _ = Manufacturer.objects.update_or_create(
        slug=slugify(name), defaults={"name": name}
    )


def dtype(manufacturer, model, u_height=0):
    obj, _ = DeviceType.objects.update_or_create(
        manufacturer=manufacturers[manufacturer],
        slug=slugify(f"{manufacturer}-{model}"),
        defaults={"model": model, "u_height": u_height, "is_full_depth": False},
    )
    return obj


types = {
    "flint2": dtype("GL.iNet", "GL-MT6000 Flint 2"),
    "generic-server": dtype("Generic", "NixOS server"),
    "generic-workstation": dtype("Generic", "NixOS workstation"),
    "framework-13": dtype("Framework", "Laptop 13 AMD Ryzen AI 300"),
    "generic-ap": dtype("Generic", "OpenWrt access point"),
    "generic-bmc": dtype("Generic", "BMC"),
    "jetkvm": dtype("Generic", "JetKVM"),
    "hp-printer": dtype("HP", "printer"),
}


def device(name, role, type_key):
    obj, _ = Device.objects.update_or_create(
        name=name,
        defaults={
            "site": site,
            "role": roles[role],
            "device_type": types[type_key],
            "status": "active",
        },
    )
    return obj


def iface(dev, name, mac=None, type="other", mgmt_only=False):
    obj, _ = Interface.objects.update_or_create(
        device=dev,
        name=name,
        defaults={"type": type, "mgmt_only": mgmt_only, "enabled": True},
    )
    if mac:
        ct = ContentType.objects.get_for_model(Interface)
        mac_obj, _ = MACAddress.objects.update_or_create(
            mac_address=mac,
            defaults={"assigned_object_type": ct, "assigned_object_id": obj.pk},
        )
        if obj.primary_mac_address_id != mac_obj.pk:
            obj.primary_mac_address = mac_obj
            obj.save()
    return obj


def ip(address, intf=None, dns_name="", role=""):
    defaults = {"status": "active", "dns_name": dns_name}
    if role:
        defaults["role"] = role
    if intf is not None:
        defaults["assigned_object_type"] = ContentType.objects.get_for_model(Interface)
        defaults["assigned_object_id"] = intf.pk
    obj, _ = IPAddress.objects.update_or_create(address=address, defaults=defaults)
    if intf is not None and address.endswith("/32"):
        dev = intf.device
        if not dev.primary_ip4_id:
            dev.primary_ip4 = obj
            dev.save()
    return obj


for prefix, desc in [
    ("192.168.10.0/24", "lan"),
    ("192.168.20.0/24", "servers"),
    ("192.168.50.0/24", "iot"),
    ("fd8a:2e59:7bfd::/64", "lan ipv6"),
    ("fd8a:2e59:7bfd:20::/64", "servers ipv6"),
]:
    obj, _ = Prefix.objects.update_or_create(
        prefix=prefix, defaults={"status": "active", "description": desc}
    )
    obj.scope = site
    obj.save()

router = device("openwrt", "router", "flint2")
for port in [
    "eth1",
    "lan1",
    "lan2",
    "lan3",
    "lan4",
    "lan5",
    "br-lan",
    "br-servers",
    "br-iot",
    "br-guest",
]:
    iface(router, port, type="bridge" if port.startswith("br-") else "1000base-t")
ip("192.168.10.1/24", iface(router, "br-lan"), "openwrt.lan", "anycast")
ip("192.168.20.1/24", iface(router, "br-servers"), "openwrt.servers.lan", "anycast")
ip("192.168.50.1/24", iface(router, "br-iot"), "openwrt.iot.lan", "anycast")
ip("fd8a:2e59:7bfd::1/64", iface(router, "br-lan"), "openwrt.lan", "anycast")
ip(
    "fd8a:2e59:7bfd:20::1/64",
    iface(router, "br-servers"),
    "openwrt.servers.lan",
    "anycast",
)

ap = device("openwrt-ap", "access-point", "generic-ap")
ip(
    "192.168.10.2/24",
    iface(ap, "lan", "64:DD:68:37:2A:32", "1000base-t"),
    "openwrt-ap.lan",
)

nixbox = device("nixbox", "server", "generic-server")
ip(
    "192.168.20.200/24",
    iface(nixbox, "bond0", "4A:C9:5C:CB:BA:93", "lag"),
    "nixbox.lan",
)
iface(nixbox, "enp36s0f0np0", type="10gbase-t")
iface(nixbox, "enp36s0f1np1", type="10gbase-t")
iface(nixbox, "enp38s0", "9C:6B:00:A9:14:36", "1000base-t")
iface(nixbox, "enp39s0", "9C:6B:00:A9:14:7A", "1000base-t")
bmc = device("nixbox-bmc", "bmc", "generic-bmc")
ip(
    "192.168.20.205/24",
    iface(bmc, "mgmt", "9C:6B:00:A9:15:CC", "1000base-t", True),
    "nixbox-bmc.lan",
)

nixworker = device("nixworker", "server", "generic-server")
ip(
    "192.168.20.210/24",
    iface(nixworker, "bond0", "AE:60:4D:85:25:DD", "lag"),
    "nixworker.lan",
)
iface(nixworker, "enp3s0", type="1000base-t")
iface(nixworker, "enp4s0", type="1000base-t")
iface(nixworker, "enp5s0f0np0", "38:05:25:30:7C:15", "10gbase-t")
iface(nixworker, "enp5s0f1np1", "38:05:25:30:7C:16", "10gbase-t")
iface(nixworker, "wlp6s0", "0C:91:60:9A:87:39", "ieee802.11ax")

simon_desktop = device("simon-desktop", "workstation", "generic-workstation")
ip(
    "192.168.10.100/24",
    iface(simon_desktop, "enp14s0", "D8:43:AE:3E:5F:73", "1000base-t"),
    "simon-desktop.lan",
)
iface(simon_desktop, "wlan0", "4C:82:A9:1C:BB:53", "ieee802.11ax")
Interface.objects.filter(device=simon_desktop, name="lan").delete()

lpt = device("lpt-titan", "laptop", "framework-13")
ip("192.168.10.150/24", iface(lpt, "wlan0", type="ieee802.11ax"), "lpt-titan.lan")

ha = device("homeassistant", "iot", "generic-server")
ip(
    "192.168.10.50/24",
    iface(ha, "lan", "20:F8:3B:01:57:AB", "1000base-t"),
    "homeassistant.lan",
)

jetkvm = device("jetkvm-ha", "iot", "jetkvm")
ip("192.168.10.30/24", iface(jetkvm, "lan", type="1000base-t"), "jetkvm-ha.lan")

printer = device("HPF4DB54", "printer", "hp-printer")
ip(
    "192.168.10.153/24",
    iface(printer, "lan", "E0:73:E7:F4:DB:55", "1000base-t"),
    "HPF4DB54.lan",
)

print(
    "seeded",
    {
        "sites": Site.objects.count(),
        "devices": Device.objects.count(),
        "interfaces": Interface.objects.count(),
        "prefixes": Prefix.objects.count(),
        "ips": IPAddress.objects.count(),
    },
)

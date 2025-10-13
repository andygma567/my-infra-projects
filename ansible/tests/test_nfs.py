import pytest
from testinfra.utils.ansible_runner import AnsibleRunner

inventory = AnsibleRunner("build/inventory.ini")
servers = inventory.get_hosts("nfs_servers")
clients = inventory.get_hosts("nfs_clients")


@pytest.mark.parametrize("host", servers)
def test_nfs_server_service_running(host):
    names = ["nfs-server", "nfs-kernel-server"]
    assert any(host.service(n).is_running for n in names)


@pytest.mark.parametrize("host", clients)
def test_nfs_client_mount_point_exists(host):
    # Adjust to your exported mountpoint
    mnt = host.file("/mnt/nfs")
    assert mnt.exists

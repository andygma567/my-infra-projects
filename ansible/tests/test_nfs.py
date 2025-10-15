import pytest
from testinfra.utils.ansible_runner import AnsibleRunner

# This test expects to be run from the repo root
inventory = AnsibleRunner("build/hosts.yml")
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


@pytest.mark.parametrize(
    "subpath,export_suffix",
    [
        ("home", "/home"),
        ("scratch", "/scratch"),
    ],
)
def test_nfs_client_mounts(host, subpath, export_suffix):
    """
    Validate that NFS mounts are present on client hosts.

    Uses Arrange-Act-Assert and testinfra's host fixture.
    """
    # Arrange
    base_mount = "/mnt/nfs"
    target_mount = f"{base_mount}/{subpath}"

    # Act
    mp = host.mount_point(target_mount)

    # Assert
    assert mp.exists, f"Expected mount point at {target_mount} to exist"

    fstype = getattr(mp, "filesystem", None)
    options = list(getattr(mp, "options", []) or [])
    device = getattr(mp, "device", "") or ""

    assert fstype in ("nfs", "nfs4"), f"Expected NFS fstype, got {fstype}"
    assert "rw" in options, (
        f"Expected 'rw' in options for {target_mount}, got {options}"
    )
    assert device.endswith(export_suffix), (
        f"Expected device to end with {export_suffix}, got {device}"
    )
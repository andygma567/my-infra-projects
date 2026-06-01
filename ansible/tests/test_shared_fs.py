"""Validate the managed shared filesystem.

The shared filesystem is no longer configured by Ansible. In dev it is a
DigitalOcean managed Network File Storage share provisioned by OpenTofu and
mounted on every node via cloud-init; in production it is the cluster's
pre-existing NFS. This test just asserts the mount is present and is NFS.
"""

# Every node mounts the shared filesystem.
testinfra_hosts = ['ansible://all']

# Local mount point (matches tofu var.nfs_mount_point default).
SHARED_MOUNT = "/shared"


def test_shared_mount_point_exists(host):
    assert host.file(SHARED_MOUNT).exists


def test_shared_filesystem_is_nfs(host):
    mp = host.mount_point(SHARED_MOUNT)
    assert mp.exists, f"Expected a mount at {SHARED_MOUNT}"

    fstype = getattr(mp, "filesystem", None)
    assert fstype in ("nfs", "nfs4"), f"Expected NFS fstype, got {fstype}"

# Run these tests only on NFS server hosts
testinfra_hosts = ['ansible://nfs_servers']


def test_nfs_server_service_running(host):
    names = ["nfs-server", "nfs-kernel-server"]
    assert any(host.service(n).is_running for n in names)

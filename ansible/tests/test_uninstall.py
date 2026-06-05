# Run after ./scripts/configure.sh uninstall to verify a full purge.
# Not included in scripts/test.sh (install validation only).
testinfra_hosts = ['ansible://all']

SLURM_PACKAGES = [
    'slurm-wlm',
    'slurm-client',
    'slurmdbd',
    'munge',
]


def test_slurm_services_not_running(host):
    for svc in ('slurmctld', 'slurmd', 'slurmdbd', 'munge'):
        assert not host.service(svc).is_running


def test_slurm_packages_absent(host):
    for pkg in SLURM_PACKAGES:
        pkg_info = host.package(pkg)
        assert not pkg_info.is_installed, f"{pkg} should be purged"


def test_slurm_config_removed(host):
    assert not host.file('/etc/slurm').exists
    assert not host.file('/etc/munge').exists

import pytest
from testinfra.utils.ansible_runner import AnsibleRunner

inventory = AnsibleRunner("build/inventory.ini")
db_hosts = inventory.get_hosts("slurmdbdservers")

@pytest.mark.parametrize("host", db_hosts)
def test_slurmdbd_running(host):
    running = host.service("slurmdbd").is_running or bool(host.process.filter(comm="slurmdbd"))
    assert running

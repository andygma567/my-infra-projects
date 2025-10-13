import pytest
from testinfra.utils.ansible_runner import AnsibleRunner

inventory = AnsibleRunner("build/inventory.ini")
ctrl = inventory.get_hosts("slurmctld")
nodes = inventory.get_hosts("slurmnodes")

@pytest.mark.parametrize("host", ctrl)
def test_slurmctld_running_on_controller(host):
    running = host.service("slurmctld").is_running or bool(host.process.filter(comm="slurmctld"))
    assert running

@pytest.mark.parametrize("host", nodes)
def test_slurmd_running_on_nodes(host):
    running = host.service("slurmd").is_running or bool(host.process.filter(comm="slurmd"))
    assert running

import pytest
from testinfra.utils.ansible_runner import AnsibleRunner

# This test expects to be run from the repo root
inventory = AnsibleRunner("build/hosts.yml")
all_hosts = inventory.get_hosts("all")

@pytest.mark.parametrize("host", all_hosts)
def test_docker_installed_or_running(host):
    cli_present = host.exists("docker")
    svc_running = host.service("docker").is_running if host.system_info.type != "freebsd" else False
    assert cli_present or svc_running

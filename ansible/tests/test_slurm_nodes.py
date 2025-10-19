# Run these tests only on SLURM node hosts
testinfra_hosts = ['ansible://slurmexechosts']


def test_slurmd_running_on_nodes(host):
    running = (
        host.service("slurmd").is_running
        or bool(host.process.filter(comm="slurmd"))
    )
    assert running

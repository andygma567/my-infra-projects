# Run these tests only on SLURM DBD server hosts
testinfra_hosts = ['ansible://slurmdbdservers']


def test_slurmdbd_running(host):
    running = (
        host.service("slurmdbd").is_running
        or bool(host.process.filter(comm="slurmdbd"))
    )
    assert running

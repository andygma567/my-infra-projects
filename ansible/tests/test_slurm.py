# Run controller tests only on SLURM controller hosts
testinfra_hosts = ['ansible://slurmservers']


def test_slurmctld_running_on_controller(host):
    running = (
        host.service("slurmctld").is_running
        or bool(host.process.filter(comm="slurmctld"))
    )
    assert running


# NOTE: For node tests, create a separate file if you want isolated scoping.
# If we keep them together, the module-level hosts apply to all tests.
# Let's split node tests into their own module for clarity.

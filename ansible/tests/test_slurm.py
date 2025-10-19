# Run controller tests only on SLURM controller hosts
testinfra_hosts = ['ansible://slurmservers']


def test_slurmctld_running_on_controller(host):
    """Verify slurmctld service is running on the controller."""
    running = (
        host.service("slurmctld").is_running
        or bool(host.process.filter(comm="slurmctld"))
    )
    assert running


def test_sinfo_command_works(host):
    """Verify sinfo can query cluster state."""
    cmd = host.run("sinfo")
    assert cmd.rc == 0, f"sinfo failed: {cmd.stderr}"
    assert len(cmd.stdout) > 0, "sinfo produced no output"


def test_cluster_has_nodes(host):
    """Verify SLURM controller can see compute nodes."""
    cmd = host.run("scontrol show nodes")
    assert cmd.rc == 0, f"scontrol show nodes failed: {cmd.stderr}"
    assert "NodeName=" in cmd.stdout, "No nodes found in cluster"


def test_simple_job_execution(host):
    """Verify a simple job can execute on the cluster."""
    cmd = host.run("srun -N1 --overlap echo 'test'")
    assert cmd.rc == 0, f"srun failed: {cmd.stderr}"
    assert "test" in cmd.stdout

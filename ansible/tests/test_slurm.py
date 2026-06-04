# Run controller tests only on SLURM controller hosts
testinfra_hosts = ['ansible://slurmservers']

# Minimum percentage of cluster nodes that must be healthy for the
# threshold test to pass. Edit this value to tune strictness.
SLURM_MIN_HEALTHY_PCT = 100.0

# Node states (from `sinfo`) that count as healthy. A trailing '*' on any
# state means the node is unresponsive and is treated as unhealthy.
HEALTHY_STATES = {"idle", "mixed", "allocated", "alloc", "completing", "comp"}


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


def _node_health(host):
    """Return (healthy, total) node counts from the controller's view."""
    # One row per node: "<nodename> <state>"; dedupe nodes that appear in
    # multiple partitions. A trailing '*' means unresponsive => unhealthy.
    cmd = host.run("sinfo -h -N -o '%n %T'")
    assert cmd.rc == 0, f"sinfo failed: {cmd.stderr}"
    nodes = {}
    for line in cmd.stdout.splitlines():
        name, _, state = line.partition(" ")
        if name:
            nodes[name] = state.strip()
    total = len(nodes)
    assert total > 0, "sinfo reported no nodes"
    healthy = sum(
        1 for s in nodes.values()
        if not s.endswith("*") and s.rstrip("*") in HEALTHY_STATES
    )
    return healthy, total


def test_node_health_threshold(host):
    """Verify at least SLURM_MIN_HEALTHY_PCT of nodes are healthy."""
    healthy, total = _node_health(host)
    pct = 100.0 * healthy / total
    assert pct >= SLURM_MIN_HEALTHY_PCT, (
        f"Only {healthy}/{total} nodes healthy ({pct:.0f}%), "
        f"need >= {SLURM_MIN_HEALTHY_PCT:.0f}%"
    )

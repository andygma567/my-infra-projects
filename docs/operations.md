# Operations

## Configure script: install, uninstall, and scale

[`scripts/configure.sh`](../scripts/configure.sh) is the main entrypoint for Slurm
lifecycle on the inventory (bare metal or test VMs). It defaults to `install`.

```bash
# Deploy (same as ./scripts/configure.sh with no subcommand)
./scripts/configure.sh install

# Full purge: Slurm, munge, MariaDB, configs, and /etc/hosts entries
./scripts/configure.sh uninstall          # prompts for confirmation

# Scale up: add hosts to slurmexechosts in inventory, then reconcile
./scripts/configure.sh scale

# Scale down: drain nodes first, then purge Slurm on removed hosts only
./scripts/configure.sh scale --remove slurm-dev-compute-02
# Edit inventory to drop those hosts from slurmexechosts, then:
./scripts/configure.sh scale
```

### Removing a node from the cluster

Follow this end-to-end procedure to decommission one or more compute nodes
cleanly. It avoids stale state on the controller and the nodes that remain.

1. **Drain the node(s) and confirm no running jobs.** On the controller:

   ```bash
   scontrol update NodeName=slurm-dev-compute-02 State=DRAIN Reason="decommission"
   squeue -w slurm-dev-compute-02      # wait until empty
   ```

2. **Purge Slurm on the removed node(s) and clean `/etc/hosts` cluster-wide.**
   The hosts must still be present in the inventory at this point so their IPs
   resolve:

   ```bash
   ./scripts/configure.sh scale --remove slurm-dev-compute-02
   ```

   This purges Slurm on the listed hosts (`uninstall.yml --limit`, keeping the
   accounting DB) and then runs `clean_hosts.yml` across every host to remove
   the decommissioned nodes' `/etc/hosts` entries from the controller and the
   remaining nodes — not just the discarded ones.

3. **Remove the host(s) from `slurmexechosts`** in `build/hosts.ini` (or your
   static inventory). `scale --remove` does not edit the inventory for you.

4. **Reconcile the remaining cluster.** Regenerates `slurm.conf` for the new
   topology and reconfigures the controller:

   ```bash
   ./scripts/configure.sh scale
   ```

5. **Verify the new topology** from the controller:

   ```bash
   sinfo
   scontrol show nodes
   ```

   The removed node(s) should no longer appear, and the remaining nodes should
   report a healthy state (`idle`/`mixed`/`allocated`).

Uninstall removes only Slurm software. It does not destroy DigitalOcean droplets
(use `./scripts/destroy.sh`) or unmount the shared NFS share.

## Running individual Ansible playbooks

Run from the `ansible/` directory so `ansible.cfg` resolves the inventory
(`./inventory` for group vars + `../build/hosts.ini` for hosts):

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml -p collections
ansible-galaxy role install -r requirements.yml -p roles

ansible all -m ping
ansible-playbook playbooks/slurmdbd.yml
ansible-playbook playbooks/slurm.yml
ansible-playbook playbooks/uninstall.yml   # full purge; use -e purge_db=false for partial
```

Slurmdbd host variables live in
[`inventory/group_vars/slurmdbdservers.yml`](../ansible/inventory/group_vars/slurmdbdservers.yml).
If `slurmdbd` fails to parse its config, see
[ansible-slurm.md](ansible-slurm.md#known-issue-slurmctldpidfile-in-slurmdbdconf).

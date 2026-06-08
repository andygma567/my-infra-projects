# galaxyproject.slurm role

Slurm is deployed with the upstream
[galaxyproject/ansible-slurm](https://github.com/galaxyproject/ansible-slurm)
role, pinned in [`ansible/requirements.yml`](../ansible/requirements.yml).
Playbooks pass cluster-specific settings through `slurm_config` and
`slurmdbd_config` in [`ansible/inventory/group_vars/`](../ansible/inventory/group_vars/).

## Known issue: `SlurmctldPidFile` in `slurmdbd.conf`

**Upstream:** [galaxyproject/ansible-slurm#48](https://github.com/galaxyproject/ansible-slurm/issues/48)

The role's default `__slurmdbd_config_default` injects `SlurmctldPidFile` into
`/etc/slurm/slurmdbd.conf`. That parameter belongs in `slurm.conf` (for
`slurmctld`); it is not recognized by `slurmdbd`. The valid slurmdbd setting is
[`PidFile`](https://slurm.schedmd.com/slurmdbd.conf.html#OPT_PidFile).

Without a workaround, `slurmdbd` fails to start:

```
error: _parse_next_key: Parsing error at unrecognized key: SlurmctldPidFile
fatal: Could not open/read/parse slurmdbd.conf file /etc/slurm/slurmdbd.conf
```

### Workaround

In `slurmdbd_config` for slurmdbd hosts:

1. Set `PidFile` to the desired slurmdbd PID path.
2. Set `SlurmctldPidFile: "{{ omit }}"` so Ansible drops the incorrect default
   instead of writing it into `slurmdbd.conf`.

This repository applies the fix in
[`ansible/inventory/group_vars/slurmdbdservers.yml`](../ansible/inventory/group_vars/slurmdbdservers.yml):

```yaml
slurmdbd_config:
  # ...
  PidFile: /run/slurmdbd.pid
  SlurmctldPidFile: "{{ omit }}"  # overrides the incorrect role default
```

Other workarounds discussed on the upstream issue include overriding
`__slurmdbd_config_default` entirely; the `omit` override above is the smallest
change and matches what we use here.

Remove the `SlurmctldPidFile` line once upstream merges a fix and the pinned
role version includes it.

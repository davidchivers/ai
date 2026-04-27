# Hamilton workflow

This note is the practical operating guide for using Durham's Hamilton HPC service for this project.

Last checked against Durham ARC public documentation: 2026-04-27.

## What Hamilton is for

Use Hamilton for long-running or parallel project work, for example:

- large Dewey, Advan, or SafeGraph processing jobs
- repeated exposure-measure construction
- many-city or many-month batch runs
- memory-heavy joins that are too slow or fragile locally
- robustness sweeps and large regression batches

Use a local machine for small smoke tests, editing scripts and notes, quick checks on tiny synthetic examples, and tasks that need local Dropbox or Windows GUI tools.

Hamilton is a shared research system. Do not run demanding computation directly on login nodes. Use the scheduler.

## Login

Hamilton 8 is the default Durham HPC target for this project.

Typical SSH target:

```bash
ssh <durham_username>@hamilton8.dur.ac.uk
```

From the University network, `hamilton8` may also work. Multifactor authentication may be required unless on campus or using the University VPN.

First checks after logging in:

```bash
whoami
hostname
quota
sinfo
sfree
squeue -u "$USER"
```

## Storage locations

Use these locations deliberately:

- `/home/<username>`: small home area, backed up. Durham documentation says new users get 10GB by default.
- `/nobackup/<username>`: larger personal data/work area, not backed up. Durham documentation says new users get 600GB by default.
- `/projects/<project_name>`: shared project directory if requested by the PI, backed up, group-controlled. Durham documentation says the default shared quota is 20GB.
- `$TMPDIR`: node-local temporary storage for a scheduled job. Files here are removed when the job ends.

For this project:

- keep Git repos, scripts, and small configs in `/home/<username>` or a shared project directory
- keep large intermediate outputs in `/nobackup/<username>/exposure_attitudes/`
- use `$TMPDIR` for fast temporary job files
- do not put raw restricted data in Git
- do not assume `/nobackup` is backed up

Check space before large runs:

```bash
quota
df -h /projects/<project_name>
du -sh /nobackup/"$USER"/exposure_attitudes 2>/dev/null
```

## Scheduler basics

Hamilton uses Slurm.

Useful commands:

```bash
sfree                 # available resources
sinfo                 # system/partition status
sbatch job.slurm      # submit a batch job
squeue -u "$USER"     # see your queued/running jobs
scancel <jobid>       # cancel a job
sacct -j <jobid>      # inspect a finished job
srun ...              # start an interactive job
```

Current public Durham documentation lists these queues/partitions:

| Queue | Use | Public time limit |
|---|---|---|
| `shared` | default shared-node jobs | 3 days |
| `multi` | one or more whole nodes | 3 days |
| `long` | jobs needing more than 3 days | 7 days |
| `bigmem` | jobs needing more than 250GB memory | 3 days |
| `test` | short test jobs | 15 minutes |

Before a major run, check live queue state with `sinfo` and `sfree`.

## Naming conventions

Use lowercase names with underscores. Avoid spaces in Hamilton paths, job names, logs, and output folders.

Recommended project slug:

```text
exposure_attitudes
```

Recommended job-name pattern:

```text
expatt_<task>_<geo>_<sample>
```

Examples:

```text
expatt_build_poi_msa_2019
expatt_firststage_county_all
expatt_stantcheva_u19
expatt_smoke_test
```

Recommended file names:

```text
01_build_poi_inputs.slurm
02_build_exposure_measures.slurm
03_first_stage_county.slurm
04_regressions_stantcheva.slurm
```

If Hamilton-specific scripts are added later, put them under `code/hpc/`. Create that folder only when adding the first script.

Recommended ignored output locations:

```text
logs/hpc/
outputs/hpc/
scratch/
local_data/
```

Do not commit those outputs unless Dave explicitly approves a small, non-sensitive aggregate artifact.

## Minimal Slurm template

Use this as a starting point, then adapt resources to the task.

```bash
#!/bin/bash
#SBATCH --job-name=expatt_smoke_test
#SBATCH --partition=test
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --tmp=1G
#SBATCH --output=logs/hpc/%x_%j.out
#SBATCH --error=logs/hpc/%x_%j.err

set -euo pipefail

cd "$SLURM_SUBMIT_DIR"

echo "Job: $SLURM_JOB_NAME"
echo "ID: $SLURM_JOB_ID"
echo "Host: $(hostname)"
echo "Started: $(date)"

# Example only. Replace with the real command.
python --version

echo "Finished: $(date)"
```

Create the log folder before submitting:

```bash
mkdir -p logs/hpc
sbatch code/hpc/01_smoke_test.slurm
```

## Workflow discipline

Before a big job:

1. run a tiny local or `test` queue smoke test
2. confirm input paths are outside Git and allowed by the data policy
3. confirm output paths go to ignored folders
4. check `quota`, `sfree`, and `sinfo`
5. give the job a clear name

After a job:

1. inspect logs
2. run `sacct -j <jobid>` for job resource use
3. summarize only aggregate, non-reconstructable outputs in project notes
4. do not paste raw rows or logs containing raw rows into Codex

## Checkpointing

For long jobs, prefer application-level checkpointing or chunked runs. The `long` queue has limited capacity, so a set of restartable shorter jobs is often better than one fragile long run.

Good patterns:

- split work by year, MSA, county, or POI category
- write intermediate outputs atomically
- keep a manifest of completed chunks
- make scripts restartable

## Sources

- [Hamilton overview](https://www.durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/)
- [Hamilton login](https://durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/usage/login/)
- [Hamilton running jobs](https://www.durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/usage/jobs/)
- [Hamilton file storage](https://www.durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/usage/storage/filestorage/)
- [Hamilton systems](https://www.durham.ac.uk/research/institutes-and-centres/advanced-research-computing/hamilton-supercomputer/systems/)

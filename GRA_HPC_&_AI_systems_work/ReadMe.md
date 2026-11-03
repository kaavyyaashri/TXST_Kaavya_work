# Graduate Research Assistant and Volunteer, HPC & AI Systems
**HiPE Laboratory, Ingram School of Engineering, Texas State University | May 2024 - June 2026**

## Summary
I supported the university's LEAP2 HPC cluster, a SLURM-managed system shared by researchers across engineering department. My work covered three areas: monitoring, enablement, and documentation.

---

## At a Glance
|Work|Details|
|:---|:---|
| **Environment** | LEAP2 cluster: SLURM scheduler, 6 partitions(`parallel`, `shared`, `himem`, `longrun`, `gpu1`, `gpu2`), 100+ compute nodes, GPU and high memory nodes |
| **Users supported** | Researchers and students across 5+ engineering departments |
| **Tools** | Bash, SLURM(`squeue`, `sinfo`, `scontrol`, `sbatch`), `nvidia-smi`, `mpstat`, `ssh`, cron, Python, Linux |
| **Focus** | Resource monitoring, utilization analysis, user training, technical documentation |

---

### 1. Cluster utilization monitoring

**The problem**
Jobs were queuing while some resources sat idle, and there was no single view of how the cluster was being used. Questions like "are the GPUs actually busy?" or "is the high-memory partition worth expanding?" had no data behind them.

**What I built**
A bash monitoring script, scheduled to run every 4 hours, that writes a timestamped plain-text into a per-day folder, so usage can be compared across time of day and across days.

Each report captures:

|**Section** |**Source**|**What it answers**|
|:---|:---|:---|
|**Job summary**|`squeue`|How many jobs are running, pending, and total?|
|**Memory overview**| `scontrol`, `show`, `node`| Total vs. allocated memory per partition (GB)|
|**Core usage**|`sinfo`|Total, allocated and idle cores|
|**Node status**| `sinfo`|Nodes per partition by state (alloc/ Idle/ mix/ drain)|
|**GPU and CPU utilization**| `ssh`, `nvidia-smi`, `mpstat`| Average GPU and CPU utilization per partition and shared compute nodes|

### How it works:

1. Creates a dated output folder at 12 AM and a timestamped report file for every 4hr interval on each run.
2. Pulls scheduler-level data (jobs, nodes, cores, memory) from SLURM.
3. Pools each GPU node with `nvidia-smi` and each compute node with `mpstat`, then averages the results per partition.
4. Skips drained or unreachable nodes and logs them in the report instead of failing the whole run.
5. Stamps the end of each report with the time it finished.


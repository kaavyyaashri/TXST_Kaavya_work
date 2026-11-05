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

Limitation:

1. **Sequential SSH polling is slow.** Checking every node one by one takes minutes. A parallel approach (e.g. `pdsh`/`clush`) or SLURM's own accounting data (`sacct`, `sreport`) would be faster and lighter on the cluster.
2. **Plain-text output is hard to trend.** Writing to CSV/JSON and plotting utilization over time would make patterns visible at a glance.

---

### 2. HPC workshop for new users

**The problem**
Most new users were domain researchers, not systems people. Common early stumbling blocks: running jobs on the login node, requesting the wrong partition, and not knowing how to use more than one core.

**What I did**
I designed and delivered a hands-on workshop on running real workloads on LEAP2, built around one task so the differences between approaches were easy to see.

**Curriculum**
1. **SLURM basics:** what the scheduler does, how to read a batch script (`#SBATCH` directives for partition, time, nodes, tasks, memory)
2. **Getting data onto the cluster:** downloading a public dataset (COCO images) directly on LEAP2
3. **Serial execution:** the baseline: one process, one core, with its SLURM script
4. **Multi-threading:** same workload using threads
5. **Multi-processing:** same workload spread across cores with Python's `multiprocessing`
6. **Comparing results:** how choice of approach and resource request changes run time

**Why this design:** running the same job three ways made the trade-offs concrete and showed *why* resource requests matter, not only how to write them.

---
## 3. User support and documentation

- Acted as the technical contact between the cluster's infrastructure and 5+ research groups, answering job-failure and resource-request questions.
- Used monitoring data to explain *why* a job was slow or stuck (e.g. wrong partition, over-requested wall time, memory requests that blocked scheduling).
- Turned repeated questions into **onboarding documentation** for new lab users, covering partitions, batch scripts, environment modules, and common SLURM commands, so people could self-serve.

---

## Impact

<!-- Only include numbers you can explain if asked. Your resume says 25%. Be ready to say what was measured and how. -->
- Gave the lab its first regular, historical view of cluster utilization (jobs, cores, memory, CPU, GPU) every 4 hours.
- Surfaced underused GPU and compute capacity to inform infrastructure expansion discussions.
- Reduced repeat support requests through workshop and onboarding material.
- [Add: improvement in job scheduling accuracy and how you measured it]

---

## Skills demonstrated

**Technical:** Linux, Bash scripting, SLURM, HPC resource management, GPU/CPU monitoring, cron scheduling, Python (serial, multi-threaded, multi-processing)

**Beyond code:** turning system data into decisions, root-cause analysis, teaching technical topics to non-specialists, writing documentation people actually use

---

## Contents of this folder

| File | Description |
|---|---|
| `monitor_cluster.sh` | Sanitized monitoring script |
| `sample_report.txt` | Example 4-hour report |
| `workshop_slides.pdf` | HPC workshop deck |
| `ReadMe.md` | This file |

*Reference: [LEAP2 Cluster User Guide]([https://itrcstats2.itrc.txstate.edu/wiki/index.php?title=LEAP2_Cluster_User_Guide](https://docs.gato.txst.edu/135641/LEAP_Cluster_brief.pdf), Texas State University ITRC.*

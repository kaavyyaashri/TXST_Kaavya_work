#!/bin/bash
source ~/.bashrc

# Log file for errors
error_log="LEAP2_Utilization/leap2_reports/error_log.txt"

# Ensure SLURM commands are available
export PATH=slurm/current/bin:$PATH

# Base directory
base_dir="LEAP2_Utilization/leap2_reports"

# Create month directory
month_dir="${base_dir}/$(date '+%Y-%m')"
mkdir -p $month_dir 2>> $error_log

# Create date directory inside the month directory
date_dir="${month_dir}/$(date '+%Y-%m-%d')"
mkdir -p $date_dir 2>> $error_log

# Output file
output_file="${date_dir}/cluster_report_at_$(date '+%Y-%m-%d_%I-%M-%S_%p').txt"
touch $output_file 2>> $error_log || { echo "Failed to create output file" >> $error_log; exit 1; }

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting job count" >> ${base_dir}/log_leap.log 2>> $error_log

# Start the report.
echo "LEAP2 Cluster Overview:" >> $output_file 
echo "======================================================================" >> $output_file 

# Jobs summary:
echo "Job Summary:" >> $output_file 
echo "======================================================================" >> $output_file 

# Get the total number of jobs, subtracting 1 for the header
total_jobs=$(squeue | wc -l)
total_jobs=$((total_jobs-1))

# Get counts for each job state
running_jobs=$(squeue -o "%t" | grep -c "R")
pending_jobs=$(squeue -o "%t" | grep -c "PD")

# Print headers with formatted spacing
printf "%-10s %-10s %-10s\n" "RUNNING" "PENDING" "TOTAL" >> $output_file
# Print data with the same formatted spacing
printf "%-10s %-10s %-10s\n" "$running_jobs" "$pending_jobs" "$total_jobs" >> $output_file 
echo "======================================================================" >> $output_file

# Memory Overview Section
echo "Memory Overview:" >> $output_file
echo "======================================================================" >> $output_file
declare -A node_memory total_memory allocated_memory

# Collect memory and node states from all nodes
nodes=$(scontrol show node | grep -E 'NodeName|RealMemory|State' | awk '{print $1}')
IFS=$'\n' read -d '' -r -a lines <<< "$nodes"

# Process nodes data
for (( k=0; k<${#lines[@]}; k+=3 )); do
    name=$(echo "${lines[k]}" | sed 's/NodeName=//g')
    mem=$(echo "${lines[k+1]}" | sed 's/RealMemory=//g')
    state=$(echo "${lines[k+2]}" | sed 's/State=//g')
    mem_gb=$(echo "scale=2; $mem/1024" | bc)  # Convert MB to GB

    node_memory[$name]=$mem_gb

    if [[ "$state" == *"ALLOCATED"* || "$state" == *"MIX"* ]]; then
        allocated_memory[$name]=$mem_gb
    else
        allocated_memory[$name]=0
    fi
done

# Calculate total and allocated memory
for name in "${!node_memory[@]}"; do
    partition="unknown"
    if [[ "$name" =~ gpu1 ]]; then
        partition="gpu1"
    elif [[ "$name" =~ gpu2 ]]; then
        partition="gpu2"
    elif [[ "$name" =~ himem ]]; then
        partition="himem"
    elif [[ "$name" =~ compute ]]; then
        partition="longrun/parallel/shared"
    fi

    if [[ "$partition" != "unknown" ]]; then
        total_memory[$partition]=$(echo "${total_memory[$partition]:-0} + ${node_memory[$name]}" | bc)
        allocated_memory[$partition]=$(echo "${allocated_memory[$partition]:-0} + ${allocated_memory[$name]}" | bc)
    fi
done
echo "Partition                Total Memory (GB)     Allocated Memory (GB)" >> $output_file

# Output memory info
printf "%-30s %-20s %-20s\n" "gpu1" ${total_memory['gpu1']} ${allocated_memory['gpu1']} >> $output_file
printf "%-30s %-20s %-20s\n" "gpu2" ${total_memory['gpu2']} ${allocated_memory['gpu2']} >> $output_file
printf "%-30s %-20s %-20s\n" "himem" ${total_memory['himem']} ${allocated_memory['himem']} >> $output_file
printf "%-30s %-20s %-20s\n" "longrun/parallel/shared" ${total_memory['longrun/parallel/shared']} ${allocated_memory['longrun/parallel/shared']} >> $output_file

echo "======================================================================" >> $output_file

# Core usage
echo "Core Usage:" >> $output_file
echo "======================================================================" >> $output_file
sinfo -o "%C" | awk 'NR == 2 {split($1, cores, "/"); print "Total cores: " cores[4] "\nAllocated cores: " cores[1] "\nIdle cores: " cores[2]}' >> $output_file
echo "======================================================================" >> $output_file

# Cluster Node Status Overview
echo "Cluster Node Status Overview:" >> $output_file
echo "======================================================================" >> $output_file
echo "Partition                   Nodes     Alloc    Idle     Mix     Drain"  >> $output_file

# Gather node status information and process
sinfo -h -o "%P %D %t %N" | awk '
BEGIN {
    # Initialize arrays to store counts for each partition
    partitions["gpu1"] = "gpu1";
    partitions["gpu2"] = "gpu2";
    partitions["himem"] = "himem";
    partitions["shared"] = "shared";
    partitions["longrun/parallel/shared"] = "longrun/parallel/shared";

    # Initialize counters for each partition
    for (p in partitions) {
        nodes[p] = 0;
        alloc[p] = 0;
        idle[p] = 0;
        mix[p] = 0;
        drain[p] = 0;
        plnd[p] = 0;
        drng[p] = 0;
        dwn[p] = 0;
        maint[p] = 0;
        res[p] = 0;
        comp[p] = 0;
        unk[p] = 0;
        fail[p] = 0;
        nor[p] = 0;
    }
}

{
    partition = $1;  # Read partition name
    num_nodes = $2;  # Read the number of nodes
    state = $3;      # Read the state

    # Update the respective counters based on the state
    if (partition in partitions) {
        nodes[partition] += num_nodes;
        if (state == "alloc") {
            alloc[partition] += num_nodes;
        } else if (state == "idle") {
            idle[partition] += num_nodes;
        } else if (state == "mix") {
            mix[partition] += num_nodes;
        } else if (state == "drain") {
            drain[partition] += num_nodes;
        } else if (state == "plnd") {
            plnd[partition] += num_nodes;
        } else if (state == "drng") {
            drng[partition] += num_nodes;
        } else if (state == "down") {
            dwn[partition] += num_nodes;
        } else if (state == "maint") {
            maint[partition] += num_nodes;
        } else if (state == "res") {
            res[partition] += num_nodes;
        } else if (state == "comp") {
            comp[partition] += num_nodes;
        } else if (state == "unk") {
            unk[partition] += num_nodes;
        } else if (state == "nresp") {
            nor[partition] += num_nodes;
        }
    }
}

END {
    # Output the results for each partition separately
    printf "%-30s %-8d %-8d %-8d %-8d %-8d\n", "gpu1", nodes["gpu1"], alloc["gpu1"], idle["gpu1"], mix["gpu1"], drain["gpu1"];
    printf "%-30s %-8d %-8d %-8d %-8d %-8d\n", "gpu2", nodes["gpu2"], alloc["gpu2"], idle["gpu2"], mix["gpu2"], drain["gpu2"];
    printf "%-30s %-8d %-8d %-8d %-8d %-8d\n", "himem", nodes["himem"], alloc["himem"], idle["himem"], mix["himem"], drain["himem"];
    printf "%-30s %-8d %-8d %-8d %-8d %-8d\n", "longrun/shared/parallel", nodes["shared"], alloc["shared"], idle["shared"], mix["shared"], drain["shared"];
}' >> $output_file

echo "==================================================================" >> $output_file

# GPU Utilization by Partition
echo "GPU Utilization by Partition:" >> $output_file
echo "==================================================================" >> $output_file

# Initialize associative arrays to store GPU utilization by partition
declare -A gpu_util_by_partition
declare -A gpu_total_by_partition
declare -A gpu_count_by_partition

# Initialize totals
for partition in gpu1 gpu2; do
    gpu_util_by_partition[$partition]=0
    gpu_total_by_partition[$partition]=0
    gpu_count_by_partition[$partition]=0
done

# Nodes in partitions
gpu1_nodes=("gpu1-001" "gpu1-002" "gpu1-003" "gpu1-004")
gpu2_nodes=("gpu2-001" "gpu2-002" "gpu2-003" "gpu2-004")

# Function to get GPU utilization from a node
get_gpu_utilization() {
    local node=$1
    ssh $node 'nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits' 2>/dev/null
}

# Collect GPU utilization data
for node in "${gpu1_nodes[@]}"; do
    utilization=$(get_gpu_utilization $node)
    for util in $utilization; do
        if [[ ! -z "$util" && "$util" =~ ^[0-9]+$ ]]; then
            gpu_util_by_partition["gpu1"]=$(echo "${gpu_util_by_partition["gpu1"]} + $util" | bc)
            gpu_count_by_partition["gpu1"]=$((${gpu_count_by_partition["gpu1"]} + 1))
        fi
    done
done

for node in "${gpu2_nodes[@]}"; do
    utilization=$(get_gpu_utilization $node)
    for util in $utilization; do
        if [[ ! -z "$util" && "$util" =~ ^[0-9]+$ ]]; then
            gpu_util_by_partition["gpu2"]=$(echo "${gpu_util_by_partition["gpu2"]} + $util" | bc)
            gpu_count_by_partition["gpu2"]=$((${gpu_count_by_partition["gpu2"]} + 1))
        fi
    done
done

# Assume each GPU node has 4 GPUs (adjust this number if different)
total_gpus_per_node=4
for partition in gpu1 gpu2; do
    gpu_total_by_partition[$partition]=$((${#gpu1_nodes[@]} * total_gpus_per_node))
done

# Calculate and output utilization percentages
echo "Partition                GPU Utilization (%)" >> $output_file
for partition in gpu1 gpu2; do
    if [[ ${gpu_total_by_partition[$partition]} -eq 0 ]]; then
        gpu_util="N/A"
    else
        gpu_util=$(echo "scale=2; (${gpu_util_by_partition[$partition]} / (${gpu_total_by_partition[$partition]} * 100)) * 100" | bc)
    fi
    printf "%-30s %-20s\n" "$partition" "$gpu_util" >> $output_file
done

# CPU Utilization by Partition
echo "CPU Utilization by Partition:" >> $output_file
echo "==================================================================" >> $output_file

# Initialize associative arrays to store CPU utilization by partition
declare -A cpu_util_by_partition
declare -A cpu_total_by_partition
declare -A cpu_count_by_partition

# Initialize totals
for partition in gpu1 gpu2 himem "longrun/parallel/shared"; do
    cpu_util_by_partition[$partition]=0
    cpu_total_by_partition[$partition]=0
    cpu_count_by_partition[$partition]=0
done

# Nodes in partitions
gpu1_nodes=("gpu1-001" "gpu1-002" "gpu1-003" "gpu1-004")
gpu2_nodes=("gpu2-001" "gpu2-002" "gpu2-003" "gpu2-004")
himem_nodes=("himem-001" "himem-002")
shared_nodes=("compute-001" "compute-002" "compute-003" "compute-004" "compute-005" "compute-006" "compute-007" "compute-008" "compute-009" "compute-010" "compute-011" "compute-012" "compute-013" "compute-014" "compute-015" "compute-016" "compute-017" "compute-018" "compute-019" "compute-020" "compute-021" "compute-022" "compute-023" "compute-024" "compute-025" "compute-026" "compute-027" "compute-028" "compute-029" "compute-030" "compute-031" "compute-032" "compute-033" "compute-034" "compute-035" "compute-036" "compute-037" "compute-038" "compute-039" "compute-040" "compute-041" "compute-042" "compute-043" "compute-044" "compute-045" "compute-046" "compute-047" "compute-048" "compute-049" "compute-050" "compute-051" "compute-052" "compute-053" "compute-054" "compute-055" "compute-056" "compute-057" "compute-058" "compute-059" "compute-060" "compute-061" "compute-062" "compute-063" "compute-064" "compute-065" "compute-066" "compute-067" "compute-068" "compute-069" "compute-070" "compute-071" "compute-072" "compute-073" "compute-074" "compute-075" "compute-076" "compute-077" "compute-078" "compute-079" "compute-080" "compute-081" "compute-082" "compute-083" "compute-084" "compute-085" "compute-086" "compute-087" "compute-088" "compute-089" "compute-090" "compute-091" "compute-092" "compute-093" "compute-094" "compute-095" "compute-096" "compute-097" "compute-098" "compute-099" "compute-100" "compute-101" "compute-102" "compute-103" "compute-104" "compute-105" "compute-106" "compute-107" "compute-108")

# Function to get CPU utilization from a node
get_cpu_utilization() {
    local node=$1
    ssh -o BatchMode=yes -o ConnectTimeout=5 $node 'mpstat -P ALL 1 1 | awk -v OFS="," '\''$3 ~ /[0-9]/ { print $3, $4 }'\'' ' 2>/dev/null
}

# Function to check if a node is drained
is_node_drained() {
    local node=$1
    sinfo -n $node -o "%t" | grep -q "drain"
}

# Collect CPU utilization data for nodes in a partition
collect_cpu_utilization() {
    local nodes=("$@")
    local partition=$1
    shift

    for node in "${nodes[@]}"; do
        if is_node_drained $node; then
            echo "Node $node is in a drained state, skipping." >> $output_file
            continue
        fi

        utilization=$(get_cpu_utilization $node)
        if [[ -z "$utilization" ]]; then
            echo "Node $node is asking for a password or not reachable, skipping." >> $output_file
            continue
        fi

        while IFS=',' read -r cpu usr; do
            if [[ ! -z "$usr" && "$usr" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                cpu_util_by_partition[$partition]=$(echo "${cpu_util_by_partition[$partition]} + $usr" | bc)
                cpu_count_by_partition[$partition]=$((${cpu_count_by_partition[$partition]} + 1))
            fi
        done <<< "$utilization"
    done
}

# Collect CPU utilization for each partition
collect_cpu_utilization "gpu1" "${gpu1_nodes[@]}"
collect_cpu_utilization "gpu2" "${gpu2_nodes[@]}"
collect_cpu_utilization "himem" "${himem_nodes[@]}"
collect_cpu_utilization "longrun/parallel/shared" "${shared_nodes[@]}"

# Assume each CPU node has 48 cores (adjust this number if different)
total_cpus_per_node=48
for partition in gpu1 gpu2 himem "longrun/parallel/shared"; do
    cpu_total_by_partition[$partition]=$((${#shared_nodes[@]} * total_cpus_per_node))
done

# Calculate and output utilization percentages for each partition
echo "Partition                CPU Utilization (%)" >> $output_file
for partition in gpu1 gpu2 himem "longrun/parallel/shared"; do
    if [[ ${cpu_total_by_partition[$partition]} -eq 0 ]]; then
        cpu_util="N/A"
    else
        cpu_util=$(echo "scale=2; (${cpu_util_by_partition[$partition]} / (${cpu_total_by_partition[$partition]} * 100)) * 100" | bc)
    fi
    printf "%-30s %-20s\n" "$partition" "$cpu_util" >> $output_file
done

# Append sinfo data to the report
echo "==================================================================" >> $output_file
echo "sinfo Data:" >> $output_file
echo "==================================================================" >> $output_file
sinfo >> $output_file
echo "==================================================================" >> $output_file
echo "This is the report at $(date '+%Y-%m-%d %I:%M:%S %p')" >> $output_file
echo "==================================================================" >> $output_file


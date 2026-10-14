# Dia 1: DevOps Culture, Linux Kernel, Filesystem Hierarchy (FHS), Permissions and Process Basics

## 1. Technical Overview and Objective

The objective of Day 1 is to establish the architectural foundations of DevOps engineering, focusing on core operating system principles. Modern infrastructure automation, container runtimes, and CI/CD pipelines run predominantly on Linux kernels. Mastering the Linux Filesystem Hierarchy Standard (FHS), kernel-space vs user-space boundaries, POSIX permission bitmasks, and process execution lifecycles is essential for diagnosing production outages, security vulnerabilities, and deployment failures.

Key goals:
- Understand the DevOps culture: CALMS framework (Culture, Automation, Lean, Measurement, Sharing).
- Demystify the Linux operating system: Kernel, GNU userland, system calls (syscalls).
- Navigate the Filesystem Hierarchy Standard (FHS 3.0) and understand mount points.
- Implement standard and special file permissions (read, write, execute, SUID, SGID, Sticky bit).
- Inspect and manage process lifecycles (PID 1, states, signals, background jobs).

---

## 2. Architecture and Core Concepts

### 2.1 The DevOps Operational Model (CALMS)

```
+--------------------------------------------------------------------------+
|                            CALMS FRAMEWORK                               |
+-------------------+--------------------+---------------------------------+
| Culture           | Automation         | Lean                            |
| Shared ownership, | Repeatable builds, | Small batch sizes,              |
| blameless post-   | infrastructure as  | continuous flow, reduced work   |
| mortems.          | code, pipelines.   | in progress (WIP).               |
+-------------------+--------------------+---------------------------------+
| Measurement                            | Sharing                         |
| Observability, SLOs, DORA metrics:     | Cross-team visibility, internal |
| Lead Time, Deployment Frequency, MTTR. | documentation, open runbooks.   |
+----------------------------------------+---------------------------------+
```

### 2.2 Linux Operating System Architecture

Linux separates operations into Kernel Space and User Space via CPU rings (Ring 0 vs Ring 3):

```
+-------------------------------------------------------------------------+
|                               USER SPACE                                |
|  [Applications: Nginx, Docker]  [CLI Utilities: bash, coreutils]        |
|  [GNU C Library (glibc)]                                                |
+------------------------------------+------------------------------------+
                                     | System Calls (read, write, fork)
+------------------------------------v------------------------------------+
|                              KERNEL SPACE                               |
|  [Process Scheduler]   [Memory Management]   [Virtual Filesystem (VFS)] |
|  [Networking Stack]    [Device Drivers]      [cgroups & Namespaces]     |
+------------------------------------+------------------------------------+
                                     | Hardware Abstraction
+------------------------------------v------------------------------------+
|                                HARDWARE                                 |
|  [CPU]  [Memory (RAM)]  [Block Storage (NVMe/SSD)]  [NIC (Network)]     |
+-------------------------------------------------------------------------+
```

### 2.3 Filesystem Hierarchy Standard (FHS) Overview

| Directory | Purpose and DevOps Relevance |
|---|---|
| `/` | Root filesystem. Must contain all essentials to boot and mount other volumes. |
| `/bin` & `/usr/bin` | Essential user command binaries (symlinked to `/usr/bin` in modern distros). |
| `/sbin` & `/usr/sbin` | System administration binaries (`iptables`, `fdisk`, `ip`). |
| `/etc` | Host-specific configuration files (`/etc/nginx/`, `/etc/ssh/`, `/etc/hosts`). |
| `/var` | Variable data: logs (`/var/log`), caches, databases (`/var/lib/docker`). |
| `/proc` | Pseudo-filesystem representing kernel and process states in memory. |
| `/sys` | Pseudo-filesystem exposing kernel objects, devices, and drivers. |
| `/dev` | Device nodes representing block devices (`/dev/sda`), terminals (`/dev/pts`). |
| `/opt` | Add-on application software packages. |
| `/home` & `/root` | User home directories and superuser home directory. |

---

## 3. Step-by-Step Reproducible Hands-On Commands

### Step 1: Kernel and System Architecture Inspection

```bash
# Print kernel version, architecture, and hostname
uname -a

# Print detailed OS distribution release data
cat /etc/os-release

# Inspect CPU architecture and virtualization capabilities
lscpu | grep -E "Model name|Architecture|Virtualization"

# Check available memory and swap utilization
free -h

# Check filesystem disk utilization and mount point types
df -hT
```

### Step 2: Navigating and Inspecting the Virtual Filesystem (`/proc` and `/sys`)

```bash
# Inspect CPU information directly from kernel memory
cat /proc/cpuinfo | grep -E "processor|model name" | head -n 4

# View memory statistics tracked by the kernel
cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"

# Inspect active kernel parameters
sysctl vm.swappiness
sysctl net.ipv4.ip_forward
```

### Step 3: Permissions and File Security Management

Linux permissions use an octal bitmask: Read (4), Write (2), Execute (1).

```bash
# Create a dedicated testing sandbox
mkdir -p /tmp/linux-sandbox && cd /tmp/linux-sandbox

# Create sample scripts and files
touch app.conf script.sh secret.key

# Set standard permissions:
# - app.conf: rw-r--r-- (644)
chmod 644 app.conf

# - script.sh: rwxr-xr-x (755)
chmod 755 script.sh

# - secret.key: rw------- (600)
chmod 600 secret.key

# Verify permissions
ls -la

# Demonstrate Special Permissions (SUID = 4000, SGID = 2000, Sticky Bit = 1000)
mkdir shared-team-dir
# SGID ensures files created inside inherit the parent group
chmod 2775 shared-team-dir

# Sticky Bit ensures only file owners or root can delete files within
mkdir shared-uploads
chmod 1777 shared-uploads
ls -ld shared-team-dir shared-uploads
```

### Step 4: Process Lifecycle and Signal Handling

```bash
# Inspect top processes sorted by memory consumption
ps aux --sort=-%mem | head -n 10

# Inspect process tree to observe PID 1 (systemd or init) hierarchy
pstree -p | head -n 15

# Launch a background long-running mock process
sleep 3600 &
MOCK_PID=$!
echo "Spawned background process with PID: ${MOCK_PID}"

# Inspect process status in /proc
cat /proc/${MOCK_PID}/status | grep -E "Name|State|Pid|PPid|Threads"

# Send signals to manage process lifecycle:
# SIGSTOP (19): Pause execution
kill -STOP ${MOCK_PID}
ps -o pid,stat,cmd -p ${MOCK_PID}

# SIGCONT (18): Resume execution
kill -CONT ${MOCK_PID}
ps -o pid,stat,cmd -p ${MOCK_PID}

# SIGTERM (15): Graceful termination request
kill -TERM ${MOCK_PID}

# Verify termination
ps -p ${MOCK_PID} || echo "Process ${MOCK_PID} terminated cleanly"
```

---

## 4. Real-World Verification Methods

Execute these commands to validate system behavior and state:

```bash
# Verify sticky bit enforcement
touch /tmp/linux-sandbox/shared-uploads/testfile.txt
ls -l /tmp/linux-sandbox/shared-uploads/testfile.txt

# Verify kernel limits and open file descriptors
ulimit -n
cat /proc/sys/fs/file-max

# Inspect systemd journal for recent authentication or service issues
journalctl -n 20 --no-pager
```

---

## 5. Troubleshooting Takeaways and Lessons Learned

1. **Permission Denied in Scripts vs Sudo**:
   - `sudo echo "text" > /etc/privileged.conf` fails because the shell redirection (`>`) is executed in user-space before `sudo` executes.
   - Solution: Use `echo "text" | sudo tee /etc/privileged.conf > /dev/null`.

2. **Understanding Orphan vs Zombie Processes**:
   - An *orphan process* has its parent process terminated; it is reparented to PID 1 (`systemd`).
   - A *zombie process* (`Z` state in `ps`) has terminated execution, but its exit code has not been read by its parent via `wait()`. Zombies consume process table entries, not RAM. If zombies accumulate, the parent process must be patched or restarted.

3. **Disk Space Exhaustion via Deleted Open Files**:
   - Running `rm /var/log/large_app.log` frees disk space only after the holding process closes the file handle. If the process is still running, `df -h` will show 100% full, but `du -sh` will not find the file.
   - Diagnosis: `lsof +L1` to find unlinked files held open by running PIDs.
   - Resolution: Truncate instead of delete: `> /var/log/large_app.log`, or restart the daemon.

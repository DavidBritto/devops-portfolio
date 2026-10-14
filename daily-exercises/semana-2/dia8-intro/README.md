# Dia 8: Docker Fundamentals - Kernel Namespaces, Control Groups (cgroups), and the Docker Daemon

## 1. Technical Overview and Objective

The objective of Day 8 is to dissect containerization at the Linux operating system level. Containers are not mini-virtual machines; they are standard Linux processes running with isolated views of the system and bounded resource consumption. Understanding how the Docker Engine leverages Linux kernel features (Namespaces, Control Groups, and OverlayFS) provides engineers with the foundational mental model required for container debugging, resource sizing, and security isolation.

Key goals:
- Understand the architectural contrast: Virtual Machines (Type-1/Type-2 Hypervisors) vs Containers (OS-level virtualization).
- Explore the core Linux Kernel primitives powering containers: Namespaces (PID, NET, MNT, IPC, UTS, USER) and Control Groups (cgroups v1/v2).
- Understand the Docker Engine architecture: Docker CLI, REST API, dockerd, containerd, and runc (OCI runtime).
- Inspect container isolation mechanisms directly on the host using native Linux tools.
- Set up and verify the local Docker runtime environment.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Virtual Machines vs Containers Comparison

```
+-----------------------------------+     +-----------------------------------+
|         VIRTUAL MACHINE           |     |             CONTAINER             |
+-----------------------------------+     +-----------------------------------+
| App A           | App B           |     | App A           | App B           |
| Libs / Bins     | Libs / Bins     |     | Libs / Bins     | Libs / Bins     |
+-----------------+-----------------+     +-----------------+-----------------+
| Guest OS        | Guest OS        |     | Container Engine (Docker/containerd)
| (Kernel + User) | (Kernel + User) |     +-----------------------------------+
+-----------------+-----------------+     | Host Linux Kernel                 |
| Hypervisor (KVM / VirtualBox)     |     | (Shared: cgroups, namespaces)     |
+-----------------------------------+     +-----------------------------------+
| Host Operating System             |     | Host Hardware                     |
| Host Hardware (Bare Metal)        |     | (CPU, Memory, Disk, Network)      |
+-----------------------------------+     +-----------------------------------+
```

### 2.2 Docker Engine Architecture (Client-Server and OCI Stack)

```
[ Docker Client CLI ]
         |
         | UNIX Domain Socket (/var/run/docker.sock) or HTTP REST API
         v
[ Docker Daemon (dockerd) ]
         |  - Image management, network orchestration, volume attachment
         v
[ containerd ]
         |  - Container lifecycle supervisor, image distribution
         v
[ containerd-shim ]
         |  - Detaches runc process from containerd daemon
         v
[ runc (OCI Runtime) ]
         |  - Interacts directly with Linux Kernel
         +---> Creates Namespaces (Isolation)
         +---> Configures cgroups (Resource Constraints)
         +---> Mounts OverlayFS (Layered Storage)
         v
[ Containerized Process (PID) ]
```

### 2.3 Kernel Primitives Under the Hood

| Primitive | Mechanism | Purpose |
|---|---|---|
| **PID Namespace** | Process ID virtualization | Isolates process tree; container main process runs as PID 1 inside, distinct PID on host. |
| **NET Namespace** | Network stack virtualization | Independent network devices, IP routing tables, port bindings, firewall rules. |
| **MNT Namespace** | Mount points virtualization | Independent root filesystem view (`/`), decoupled from host filesystem mounts. |
| **IPC Namespace** | Inter-Process Communication | Isolates System V IPC and POSIX message queues. |
| **UTS Namespace** | Hostname & Domain name | Enables dedicated hostname resolution per container. |
| **USER Namespace** | User and Group ID mapping | Maps container `root` (UID 0) to unprivileged UID on the host for defense-in-depth. |
| **cgroups (v1/v2)** | Resource accounting & limits | Enforces hard/soft limits on CPU cores, RAM consumption, block I/O bandwidth. |

---

## 3. Step-by-Step Hands-On Inspection Commands

### Step 1: Docker Runtime Environment Verification

```bash
# Verify Docker Client and Server engine information
docker version

# Inspect Docker daemon subsystem configuration, storage driver, and cgroup version
docker info | grep -E "Server Version|Storage Driver|Cgroup Driver|Cgroup Version"

# Confirm Docker daemon systemd service status
systemctl status docker --no-pager
```

### Step 2: Uncovering Namespaces on the Host

```bash
# Run a long-lived interactive Alpine container in detached mode
docker run -d --name isolation-lab alpine sleep 3600

# Obtain the host PID of the container's process
CONTAINER_PID=$(docker inspect --format '{{.State.Pid}}' isolation-lab)
echo "Container internal PID 1 corresponds to Host PID: ${CONTAINER_PID}"

# Inspect namespaces assigned to this process on the Linux host
ls -l /proc/${CONTAINER_PID}/ns/

# Execute a command inside the container's namespace directly via host 'nsenter'
sudo nsenter --target ${CONTAINER_PID} --mount --uts --ipc --net --pid ps aux
```

### Step 3: Inspecting Control Group Limits (cgroups)

```bash
# Launch a container with strict memory (256MB) and CPU (0.5 cores) constraints
docker run -d --name resource-lab -m 256m --cpus 0.5 alpine sleep 3600

# Inspect cgroup memory limits applied at the kernel level
# For cgroups v2:
cat /sys/fs/cgroup/system.slice/docker-$(docker inspect --format '{{.Id}}' resource-lab).scope/memory.max 2>/dev/null || \
cat /sys/fs/cgroup/memory/docker/$(docker inspect --format '{{.Id}}' resource-lab)/memory.limit_in_bytes 2>/dev/null

# Monitor real-time container resource streams
docker stats --no-stream resource-lab
```

---

## 4. Real-World Verification Methods

```bash
# Verify process tree hierarchy: see dockerd -> containerd -> containerd-shim -> sleep
pstree -p -s $(docker inspect --format '{{.State.Pid}}' isolation-lab)

# Verify network namespace isolation: check veth pair bound to docker0 bridge
ip link show type veth
brctl show docker0 || ip link show docker0

# Clean up temporary test containers
docker rm -f isolation-lab resource-lab
```

---

## 5. Troubleshooting Takeaways and Lessons Learned

1. **Docker Socket Permission Errors**:
   - Error: `permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock`
   - Cause: The current user is not a member of the `docker` UNIX group.
   - Resolution: `sudo usermod -aG docker $USER && newgrp docker`. Avoid running all docker commands as `root`.

2. **OOM Killer (Out Of Memory) in Resource-Constrained Containers**:
   - Symptoms: Container exits silently with exit code `137` (128 + 9 / SIGKILL).
   - Diagnosis: Run `docker inspect <container-name> --format '{{.State.OOMKilled}}'` which returns `true`.
   - Resolution: Profile application memory footprint using `docker stats` and adjust `-m` memory allocations or configure swap buffers (`--memory-swap`).

3. **PID 1 Signal Forwarding**:
   - Issue: When a custom script runs as PID 1 without an init system (like `tini` or `dumb-init`), it fails to trap `SIGTERM`, resulting in 10-second timeouts during `docker stop` followed by a hard `SIGKILL`.
   - Resolution: Ensure containers use `exec` in entrypoints to replace the shell process with the application binary: `exec "$@"`.

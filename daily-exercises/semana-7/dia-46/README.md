# Dia 46: Docker Runtime Hardening - Non-Root Users, Read-Only Filesystems, and Capability Dropping

## 1. Technical Overview and Objective

The objective of Day 46 is to eliminate common container security misconfigurations through defense-in-depth hardening. By default, processes inside Docker containers run as the superuser `root` (UID 0). While isolated by kernel namespaces, running as root significantly lowers the bar for container breakout exploits, kernel privilege escalation, and host filesystem tampering. Container hardening enforces the Principle of Least Privilege at build and runtime.

Key goals:
- Configure non-root execution via Dockerfile `USER` directives with explicit UIDs.
- Implement multi-stage builds and minimal base images (Distroless / Alpine) to minimize attack surfaces.
- Enforce immutable, read-only root filesystems (`--read-only`) with isolated `tmpfs` mounts.
- Strip unnecessary Linux kernel capabilities (`--cap-drop=ALL` with explicit minimal additions).
- Prevent privilege escalation flags (`no-new-privileges:true`).

---

## 2. Architecture and Container Hardening Matrix

### 2.1 Container Privilege Boundary

```
+-------------------------------------------------------------------------+
| HOST LINUX KERNEL (UID 0 - Host Root)                                   |
+-------------------------------------------------------------------------+
                                 ^
                                 |  Kernel System Calls
+--------------------------------+----------------------------------------+
| UNHARDENED CONTAINER (DEFAULT) | HARDENED CONTAINER (LEAST PRIVILEGE)   |
|                                |                                        |
| - Runs as: UID 0 (root)        | - Runs as: UID 10001 (appuser)         |
| - Filesystem: Read-Write       | - Filesystem: Read-Only Root           |
| - Capabilities: Full default   | - Capabilities: Dropped ALL            |
|   (CHOWN, DAC_OVERRIDE, FOWNER)|   (Retains only specific needed caps)  |
| - New Privileges: Allowed      | - no-new-privileges: true              |
|                                | - Writable directories: ephemeral tmpfs|
| * Risk: High exploit blast     | * Risk: Minimal exploit blast radius,  |
|   radius, host tampering risk. |   container breakout effectively barred|
+--------------------------------+----------------------------------------+
```

---

## 3. Configuration Breakdown

### 3.1 Hardened Multi-Stage Dockerfile (`Dockerfile.hardened`)

```dockerfile
# Stage 1: Build & Dependencies
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Minimal Hardened Runtime
FROM node:18-alpine
WORKDIR /app

# Create unprivileged system user and group
RUN addgroup -g 10001 -S appgroup && \
    adduser -u 10001 -S appuser -G appgroup

# Copy dependencies with correct ownership
COPY --chown=appuser:appgroup --from=builder /app/node_modules ./node_modules
COPY --chown=appuser:appgroup . .

# Switch to unprivileged runtime user
USER 10001:10001

# Expose unprivileged application port (>1024)
EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "main.js"]
```

### 3.2 Hardened Docker Compose Definition (`docker-compose.security.yml`)

```yaml
services:
  hardened-app:
    build:
      context: .
      dockerfile: Dockerfile.hardened
    ports:
      - "3000:3000"
    user: "10001:10001"
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp:rw,noexec,nosuid,size=64m
      - /app/run:rw,noexec,nosuid,size=32m
    restart: unless-stopped
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# 1. Build the hardened container image
docker build -f Dockerfile.hardened -t app-hardened:v1 .

# 2. Run the hardened container with strict runtime flags
docker run -d \
  --name hardened-runtime-test \
  --user 10001:10001 \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --tmpfs /tmp:rw,noexec,nosuid,size=32m \
  -p 3000:3000 \
  app-hardened:v1

# 3. Verify container is executing as expected
docker ps -f name=hardened-runtime-test
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify runtime process UID/GID
docker exec hardened-runtime-test id
# Expected output: uid=10001(appuser) gid=10001(appgroup)

# 2. Verify root filesystem is strictly immutable (Read-Only)
docker exec hardened-runtime-test touch /root/malicious.txt 2>&1 | grep "Read-only file system"

# 3. Verify tmpfs allows bounded temporary file writing
docker exec hardened-runtime-test touch /tmp/healthcheck.tmp
docker exec hardened-runtime-test ls -l /tmp/healthcheck.tmp

# 4. Clean up test container
docker rm -f hardened-runtime-test
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Port Binding Failures Below Port 1024**:
   - Issue: Application fails with `bind: permission denied` when configured to listen on port 80 or 443.
   - Cause: Linux reserves ports 1-1023 for privileged users (root) unless granted `CAP_NET_BIND_SERVICE`.
   - Solution: Configure container applications to listen on unprivileged ports (e.g. 3000, 5000, 8080) or explicitly add `cap_add: [NET_BIND_SERVICE]`.

2. **Package Manager Operations Inside Read-Only Containers**:
   - Issue: Running `apt-get install` or `pip install` at container startup fails immediately.
   - Solution: Never install packages or compile code at container startup. All dependencies must be baked in during multi-stage image builds.

3. **`no-new-privileges` Protection**:
   - Lesson: The `no-new-privileges` security flag prevents processes from acquiring additional privileges via `setuid` or `setgid` binaries (like `sudo` or `ping`), effectively neutering common container privilege escalation exploits.

# Dia 7: Final Challenge Week 1 - Automated Multi-Tier Stack with Vagrant and Ansible

## 1. Technical Overview and Objective

The objective of Day 7 is the consolidation of Week 1 skills into a fully automated, multi-tier web application deployment. This challenge bridges declarative hypervisor provisioning (Vagrant) with idempotent configuration management and role-based automation (Ansible). The system deploys the Roxs Voting App stack (Python/Flask, Node.js, Redis, and PostgreSQL) onto a provisioned Linux virtual machine.

Key goals:
- Provision a clean Ubuntu 22.04 LTS guest machine via Vagrant with host-only private networking and port forwarding.
- Configure Ansible inventory and playbooks to enforce idempotent system provisioning without external agent dependencies.
- Modularize configuration into reusable roles: Nginx reverse proxy, PostgreSQL database, Redis caching, runtime dependencies (Python/Pip, Node.js/NPM), and dedicated system users.
- Deploy and orchestrate multi-tier microservices with process execution controls and environment variable injection.
- Validate end-to-end data persistence from client voting frontend to backend relational storage.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Multi-Tier Architecture Diagram

```
+-------------------------------------------------------------------------+
| HOST SYSTEM BROWSER & CLIENT                                            |
|  - Vote UI:   http://localhost:8080                                     |
|  - Result UI: http://localhost:3000                                     |
+-------------------+---------------------------------+-------------------+
                    | Port Forward 8080               | Port Forward 3000
                    v                                 v
+-------------------------------------------------------------------------+
| VAGRANT GUEST VM (Ubuntu 22.04 LTS - 192.168.56.10)                     |
|                                                                         |
|  [Tier 1: Frontend - Vote App]                                          |
|   Python 3 / Flask listening on 0.0.0.0:8080                            |
|        |                                                                |
|        | (Writes votes via redis-py)                                    |
|        v                                                                |
|  [Tier 2: Message Queue / In-Memory Cache]                              |
|   Redis Server listening on 127.0.0.1:6379                              |
|        ^                                                                |
|        | (Polls queue via ioredis / redis client)                       |
|  [Tier 3: Background Worker Processor]                                  |
|   Node.js background process                                            |
|        |                                                                |
|        | (Commits vote tallies via pg driver)                           |
|        v                                                                |
|  [Tier 4: Relational Persistence]                                       |
|   PostgreSQL Database listening on 127.0.0.1:5432 (Database: votes)     |
|        ^                                                                |
|        | (Queries vote counts for realtime charts)                      |
|  [Tier 5: Presentation - Result App]                                    |
|   Node.js / Express + Socket.io listening on 0.0.0.0:3000               |
+-------------------------------------------------------------------------+
```

### 2.2 Orchestration Lifecycle Flow

```
[vagrant up]
     |
     v
[VirtualBox VM Spawned] -> Allocates 2 vCPUs, 2048 MB RAM, IP 192.168.56.10
     |
     v
[Ansible Provisioner Triggered]
     |
     +---> [Role: devops_user] -> Enforces dedicated user with sudoers privileges
     +---> [Role: base_deps]   -> Installs python3, pip, nodejs, npm, git, curl
     +---> [Role: redis]       -> Installs and starts Redis daemon
     +---> [Role: postgresql]  -> Installs PostgreSQL, initializes 'votes' DB
     +---> [Role: app_deploy]  -> Pulls app repos, installs npm/pip packages
     |
     v
[Application Startup (start_all.sh)]
     |
     +---> Background spawn of vote (Python), worker (Node), result (Node)
     |
     v
[Verification Phase] -> HTTP health checks on 8080 and 3000; DB schema checks
```

---

## 3. Configuration Breakdown

### 3.1 Hypervisor Specification (`Vagrantfile`)

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "votingapp-node1"

  # Private host-only network
  config.vm.network "private_network", ip: "192.168.56.10"

  # Host port forwarding for browser access
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # Shared codebase mount
  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = "2"
    vb.name = "roxs-voting-app-vm"
  end

  # Ansible Provisioner execution
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.inventory_path = "inventory.ini"
    ansible.install = true
  end
end
```

### 3.2 Ansible Playbook Structure (`playbook.yml`)

```yaml
---
- name: Deploy Roxs Voting App Infrastructure
  hosts: all
  become: true
  vars:
    db_name: votes
    db_user: postgres
    db_pass: postgres
  tasks:
    - name: Update apt package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install required runtime engines and tools
      apt:
        name:
          - python3
          - python3-pip
          - nodejs
          - npm
          - redis-server
          - postgresql
          - postgresql-contrib
          - libpq-dev
        state: present

    - name: Ensure Redis daemon is running and enabled
      systemd:
        name: redis-server
        state: started
        enabled: yes

    - name: Ensure PostgreSQL daemon is running and enabled
      systemd:
        name: postgresql
        state: started
        enabled: yes
```

### 3.3 Microservice Startup Script (`start_all.sh`)

```bash
#!/bin/bash
set -e

echo "[STARTUP] Cleaning prior background processes..."
pkill -f 'python3 app.py' || true
pkill -f 'node main.js' || true

echo "[STARTUP] Launching Vote frontend service..."
cd /vagrant/roxs-voting-app/vote
pip3 install -r requirements.txt > /dev/null 2>&1
REDIS_HOST=127.0.0.1 python3 app.py &

echo "[STARTUP] Launching Background Worker..."
cd /vagrant/roxs-voting-app/worker
npm install > /dev/null 2>&1
REDIS_HOST=127.0.0.1 DB_HOST=127.0.0.1 DB_USER=postgres DB_PASSWORD=postgres node main.js &

echo "[STARTUP] Launching Result dashboard service..."
cd /vagrant/roxs-voting-app/result
npm install > /dev/null 2>&1
DB_HOST=127.0.0.1 DB_USER=postgres DB_PASSWORD=postgres PORT=3000 node main.js &

echo "[STARTUP] All microservices spawned successfully."
```

---

## 4. Step-by-Step Reproducible Commands

```bash
# Navigate to challenge root directory
cd /home/david/git/devops-porfolio/voting-app

# Validate configuration and spin up VM with automated Ansible provisioning
vagrant up

# Access VM console via SSH
vagrant ssh

# Verify service listening ports
ss -tuln | grep -E "8080|3000|6379|5432"

# Execute startup script
cd /vagrant
chmod +x start_all.sh
./start_all.sh
```

---

## 5. Real-World Verification Methods

```bash
# 1. Verify HTTP status on Vote UI
curl -sI http://localhost:8080 | head -n 5

# 2. Verify HTTP status on Result UI
curl -sI http://localhost:3000 | head -n 5

# 3. Submit a test vote via POST request
curl -s -X POST -d "vote=a" http://localhost:8080/

# 4. Query PostgreSQL database directly to confirm worker processed and persisted the record
sudo -u postgres psql -d votes -c "SELECT vote, count(vote) FROM votes GROUP BY vote;"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Ansible `become_user` Escalation on Minimal Cloud Images**:
   - Issue: Using Ansible's `postgresql_db` module fails when `python3-psycopg2` is missing in the target environment or when unprivileged SSH users fail PAM auth switching to the `postgres` system account.
   - Fix: Decouple database engine deployment from schema migration. Install database packages via Ansible, and trigger schema migrations via idempotent entrypoint SQL scripts executed as `sudo -u postgres`.

2. **Hardcoded Hostnames Across Multi-Tier Codebases**:
   - Issue: The voting app microservices were originally designed with container DNS aliases (`redis`, `db`). In a bare-metal or single-VM setup, these hostnames fail to resolve without `/etc/hosts` modifications.
   - Fix: Refactor connection drivers to respect standard environment variables (`REDIS_HOST`, `DB_HOST`) with fallback defaults to `127.0.0.1`.

3. **Node.js Process Port Collision (`EADDRINUSE`)**:
   - Issue: Both `result` and `worker` services attempting to bind to port 80 or sharing HTTP listener definitions.
   - Fix: Configure explicit port bindings: Result app listens on `3000`, Vote app on `8080`, and Worker runs purely as a non-listening event loop processing queue items.

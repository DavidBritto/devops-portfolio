# Dia 3: Automated Virtual Machine Provisioning with Vagrant and VirtualBox

## 1. Technical Overview and Objective

The objective of Day 3 is to automate local infrastructure provisioning using Vagrant and Oracle VirtualBox. Manual virtual machine setup introduces configuration drift, high onboarding times, and reproducibility issues across development teams. Vagrant enables Infrastructure as Code (IaC) principles at the hypervisor level, allowing engineers to define VM hardware allocations, network topology, synced folders, and shell provisioning scripts declaratively.

Key goals:
- Configure declarative virtual machine specs using `Vagrantfile`.
- Configure dedicated private networking (`192.168.33.10`) isolated from the host.
- Establish two-way host-to-guest synced folders (`./html` mapped to `/var/www/html`).
- Automate non-interactive web server installation and service enablement via `provision.sh`.
- Validate web server accessibility from the host machine browser and curl.

---

## 2. Architecture and Workflow Breakdown

### 2.1 Virtual Machine Topology

```
+-------------------------------------------------------------------------+
| HOST SYSTEM (Linux / Ubuntu 24.04 LTS)                                  |
|                                                                         |
|  [Repository: daily-exercises/semana-1/dia3-vagrant]                   |
|  ├── Vagrantfile                                                        |
|  ├── provision.sh                                                       |
|  └── html/index.html <------------------------------------+             |
|                                                           |             |
|  Host-only Adapter: vboxnet0 (192.168.33.1)               |             |
+-----------------------------+-----------------------------+-------------+
                              | Private Virtual Network (192.168.33.0/24)
+-----------------------------v-------------------------------------------+
| GUEST VIRTUAL MACHINE (Oracle VirtualBox)                               |
| Hostname: servidor-web-dev                                              |
| Box: ubuntu/jammy64 (Ubuntu 22.04 LTS)                                  |
| IP Address: 192.168.33.10                                               |
| Resources: 2 vCPUs, 2048 MB RAM                                         |
|                                                                         |
|  [Nginx Daemon (systemd)] listening on 0.0.0.0:80                       |
|  DocumentRoot: /var/www/html <----------------------------+ Synced      |
|                                                             Folder      |
+-------------------------------------------------------------------------+
```

### 2.2 Provisioning Workflow Lifecycle

```
[vagrant up]
     |
     v
[Check VirtualBox Provider] ---> [Download / Verify ubuntu/jammy64 Box]
     |
     v
[Configure VM Resources] ------> [2 vCPUs, 2048 MB RAM, Hostname: servidor-web-dev]
     |
     v
[Setup Networking] ------------> [Attach Private Network: 192.168.33.10]
     |
     v
[Mount Synced Folders] --------> [Mount ./html to /var/www/html (owner: www-data)]
     |
     v
[Execute Provisioner] ---------> [Run provision.sh: apt-get update && apt-get install nginx]
     |
     v
[Status: READY] ---------------> [Guest reachable at http://192.168.33.10]
```

---

## 3. Configuration Breakdown

### 3.1 Declarative Specification (`vagrantfile` / `Vagrantfile`)

```ruby
Vagrant.configure("2") do |config|
  # Base Ubuntu 22.04 cloud image
  config.vm.box = "ubuntu/jammy64"

  # Guest hostname definition
  config.vm.hostname = "servidor-web-dev"

  # Static private network configuration
  config.vm.network "private_network", ip: "192.168.33.10"

  # Host-to-guest synced directory mapping for rapid web development
  config.vm.synced_folder "./html", "/var/www/html", owner: "www-data", group: "www-data"

  # VirtualBox hardware sizing
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = "2"
  end

  # Shell provisioning execution
  config.vm.provision "shell", path: "provision.sh"
end
```

### 3.2 Shell Provisioner (`provision.sh`)

```bash
#!/bin/bash
# Shell provisioner script executed inside the VM during initialization

echo "==> [SCRIPT] Actualizando la lista de paquetes..."
apt-get update > /dev/null 2>&1

echo "==> [SCRIPT] Instalando el servidor web Nginx..."
apt-get install -y nginx > /dev/null 2>&1

echo "==> [SCRIPT] El provisionamiento ha finalizado."
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to project folder
cd /home/david/git/devops-porfolio/daily-exercises/semana-1/dia3-vagrant

# Validate Vagrant syntax
vagrant validate

# Provision and start the virtual machine
vagrant up

# Check status of the running instance
vagrant status

# Verify SSH connectivity into the guest VM
vagrant ssh -c "hostname && ip addr show eth1"

# Verify Nginx status inside the guest
vagrant ssh -c "systemctl status nginx --no-pager"
```

---

## 5. Real-World Verification Methods

```bash
# Test HTTP connectivity from host machine to guest private IP
curl -sI http://192.168.33.10

# Validate HTML body content served from synced folder
curl -s http://192.168.33.10 | grep -i "<title>"

# Verify synced folder mount options inside the VM
vagrant ssh -c "mount | grep /var/www/html"
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **Mount Failure on Guest Additions Mismatch**:
   - Error: `Vagrant was unable to mount VirtualBox shared folders.`
   - Root Cause: Guest kernel updates often break out-of-date VirtualBox Guest Additions inside the guest image.
   - Solution: Install `vagrant-vbguest` plugin (`vagrant plugin install vagrant-vbguest`) or ensure base image matches host VirtualBox versions.

2. **Network Collision with Host Subnets**:
   - Error: Host route conflict when binding `192.168.33.10`.
   - Solution: Verify `/etc/vbox/networks.conf` permissions and ensure no overlapping CIDR ranges exist across active Docker bridges (`docker0` / custom bridge subnets).

3. **Synced Folder File Permissions**:
   - Web servers require appropriate read permissions for the runtime user (`www-data`). Specifying `owner: "www-data", group: "www-data"` in `config.vm.synced_folder` prevents HTTP 403 Forbidden responses.

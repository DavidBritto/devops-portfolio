# Dia 22: Terraform Fundamentals - Declarative Infrastructure as Code (IaC), State Management, Providers, and the Core Workflow

## 1. Technical Overview and Objective

The objective of Day 22 is to establish the core principles of Infrastructure as Code (IaC) using HashiCorp Terraform. Traditional infrastructure management relies on manual configuration changes in web consoles or imperative shell scripts, leading to configuration drift, human error, and undocumented environments. Terraform introduces a declarative paradigm where engineers define the target desired state of infrastructure in HashiCorp Configuration Language (HCL). The Terraform engine computes the directed acyclic graph (DAG) of dependencies and determines the exact delta required to reconcile real-world infrastructure with the code.

Key goals:
- Understand Declarative vs Imperative infrastructure paradigms.
- Explore the Terraform Architecture: Core engine, Provider plugins, and State file (`terraform.tfstate`).
- Master the fundamental Terraform workflow: `init`, `plan`, `apply`, `destroy`, `fmt`, `validate`.
- Configure the HashiCorp `local` and `random` providers to manage local resources without cloud costs.
- Inspect and understand state locking, resource addressing, and drift detection.

---

## 2. Architecture and Workflow Breakdown

### 2.1 The Declarative IaC Engine Architecture

```
+-------------------------------------------------------------------------+
| USER CONFIGURATION (HCL)                                                |
|  - main.tf                                                              |
|  - variables.tf                                                         |
|  - outputs.tf                                                           |
+-----------------------------------+-------------------------------------+
                                    |
                                    v
+-------------------------------------------------------------------------+
| TERRAFORM CORE ENGINE                                                   |
|                                                                         |
|  1. HCL Parser & Validator                                              |
|  2. Dependency Graph Builder (Directed Acyclic Graph - DAG)             |
|  3. State Comparison Engine (Compares Desired vs Real vs Recorded State)
+-------------------+---------------------------------+-------------------+
                    |                                 |
                    | RPC (gRPC)                      | Read / Write
                    v                                 v
+-----------------------------------+   +---------------------------------+
| PROVIDER PLUGINS                  |   | TERRAFORM STATE                 |
|  - local (files, directories)     |   |  - terraform.tfstate            |
|  - docker (images, containers)    |   |  - Maps real resources to IDs   |
|  - aws / kubernetes (cloud APIs)  |   |  - Resource metadata & hashes   |
+-------------------+---------------+   +---------------------------------+
                    | API Calls
                    v
+-------------------------------------------------------------------------+
| TARGET INFRASTRUCTURE (Local Filesystem, Docker Engine, Cloud Fabric)  |
+-------------------------------------------------------------------------+
```

### 2.2 The Terraform Core Lifecycle Workflow

```
[terraform fmt] ------> Canonical formatting of HCL code
     |
     v
[terraform init] -----> Downloads provider binaries (.terraform/) and locks versions (.terraform.lock.hcl)
     |
     v
[terraform validate] -> Validates syntax, attribute names, and internal consistency
     |
     v
[terraform plan] -----> Refreshes state against reality, generates execution delta graph
     |
     v
[terraform apply] ----> Requests confirmation, invokes provider APIs, commits state changes to disk
     |
     v
[terraform destroy] --> Computes inverse graph, removes all tracked infrastructure
```

---

## 3. Configuration Breakdown

### 3.1 Required Providers and Versions (`versions.tf`)

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}
```

### 3.2 Input Variables (`variables.tf`)

```hcl
variable "project_name" {
  type        = string
  description = "Identifier of the DevOps project"
  default     = "90days-iac-starter"
}

variable "environment" {
  type        = string
  description = "Target deployment tier"
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

### 3.3 Main Resources (`main.tf`)

```hcl
# Generate pseudo-random resource suffix
resource "random_id" "server_id" {
  byte_length = 4
}

# Create managed configuration file
resource "local_file" "environment_manifest" {
  filename = "${path.module}/${var.project_name}-${var.environment}-manifest.json"
  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    server_id   = random_id.server_id.hex
    created_by  = "terraform"
    managed     = true
  })
  file_permission = "0644"
}
```

### 3.4 Output Values (`outputs.tf`)

```hcl
output "manifest_filepath" {
  description = "Path to the created manifest file"
  value       = local_file.environment_manifest.filename
}

output "generated_server_id" {
  description = "Unique random identifier generated for this instance"
  value       = random_id.server_id.hex
}
```

---

## 4. Step-by-Step Reproducible Execution Commands

```bash
# Navigate to dia-22 workspace
cd /home/david/git/devops-porfolio/daily-exercises/semana-4/dia-22

# 1. Format code to HashiCorp standard
terraform fmt

# 2. Initialize working directory, download provider plugins
terraform init

# 3. Validate syntax and configuration integrity
terraform validate

# 4. Generate and inspect execution plan
terraform plan -out=tfplan

# 5. Apply the execution plan
terraform apply tfplan

# 6. Inspect tracked state file
terraform show
terraform state list
```

---

## 5. Real-World Verification Methods

```bash
# Verify file generated by Terraform on disk
cat 90days-iac-starter-dev-manifest.json

# Test Drift Detection:
# Modify file manually outside of Terraform
echo "drifted content" > 90days-iac-starter-dev-manifest.json

# Run plan: Terraform detects that reality diverged from state
terraform plan

# Re-apply to automatically reconcile drift back to desired state
terraform apply -auto-approve

# Clean up resources
terraform destroy -auto-approve
```

---

## 6. Troubleshooting Takeaways and Lessons Learned

1. **State File Sensitivity and Concurrency**:
   - Issue: Committing `terraform.tfstate` to Git exposes plain-text secrets and causes state corruption when multiple engineers run concurrent applies.
   - Solution: Never commit `.tfstate` files to version control. Add `*.tfstate*` to `.gitignore` and use remote backends (such as AWS S3 with DynamoDB state locking).

2. **Understanding `.terraform.lock.hcl`**:
   - Issue: Teammates getting different provider versions, leading to inconsistent plan outputs.
   - Solution: Commit `.terraform.lock.hcl` into Git. This file contains cryptographically verified dependency checksums ensuring all engineers and CI runners execute identical provider binaries.

3. **Imperative Scripts vs Declarative IaC**:
   - Lesson: Imperative scripts (`bash`, `python`) focus on *how* to achieve an action (run `mkdir`, `apt install`). If run twice without safeguards, they fail. Declarative Terraform focuses on *what* the final state must look like. Terraform automatically handles creation, updates in-place, or destructive replacements.

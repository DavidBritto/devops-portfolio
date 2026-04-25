# 90 Days of DevOps with Roxs — Portfolio

Documentación de mi recorrido por el desafío **#90DaysOfDevOps**, una iniciativa de [Rossana Suarez](https://90daysdevops.295devops.com/) diseñada para aplicar conceptos de DevOps de forma práctica y progresiva.

Cada semana aborda una disciplina distinta del ecosistema DevOps. Este repositorio reúne ejercicios diarios, proyectos prácticos y los aprendizajes concretos obtenidos en el camino.

---

## Entorno de trabajo

| Componente | Detalle |
|---|---|
| Sistema Operativo | Ubuntu 24.04 LTS |
| Editor | VS Code |
| Terminal | Zsh |
| Virtualización | VirtualBox + Vagrant |
| Contenedores | Docker + Docker Compose |
| IaC | Terraform |
| CI/CD | GitHub Actions |

---

## Estructura del repositorio

```
devops-portfolio/
├── daily-exercises/
│   ├── semana-1/      # Linux, Vagrant, Git, Bash, Ansible
│   ├── semana-2/      # Docker y contenedores
│   ├── semana-3/      # CI/CD con GitHub Actions
│   ├── semana-4/      # Infraestructura como Código con Terraform
│   └── semana-5/      # Kubernetes y orquestación de contenedores
├── voting-app/        # Proyecto transversal: Roxs Voting App
├── mi-app/            # Aplicación propia containerizada
└── .github/workflows/ # Pipelines de CI/CD activos
```

---

## Semana 1 — Fundamentos: Linux, Vagrant, Git, Bash y Ansible

| Tema | Contenido |
|---|---|
| Linux | Comandos esenciales, sistema de archivos, permisos, gestión de procesos |
| Vagrant | Provisioning de VMs con scripts Bash, servidor web embebido |
| Git | Flujo de trabajo con ramas, resolución de conflictos, buenas prácticas |
| Bash Scripting | Scripts de monitoreo de disco, servicios, backups y automatización |
| Ansible | Playbooks y roles: `nginx`, `devops_user`, `firewall` |

**Proyecto de semana:** Roxs Voting App desplegada con Vagrant + Ansible en VM local.
Arquitectura de microservicios (Python/Flask · Node.js · Redis · PostgreSQL).

---

## Semana 2 — Contenedores con Docker

| Tema | Contenido |
|---|---|
| Docker Basics | Primer contenedor, imágenes, ciclo de vida de contenedores, NGINX en contenedor |
| Imágenes | Dockerfiles multi-stage, construcción de imágenes propias |
| Redes Docker | Redes bridge y overlay, comunicación entre contenedores |
| Volúmenes | Persistencia de datos, bind mounts vs volumes |
| Docker Compose | Definición y orquestación de servicios multi-contenedor |

---

## Semana 3 — CI/CD con GitHub Actions

| Tema | Contenido |
|---|---|
| GitHub Actions | Primeros workflows: variables de entorno, condicionales por rama |
| Runner Self-Hosted | VM dedicada con Vagrant como runner propio |
| Despliegue Automatizado | Pipeline completo: push → build → deploy en runner self-hosted |
| Monitoreo y Logging | Health check endpoint, logging en Docker, workflows con cron |

**Workflows activos en este repositorio:**

| Workflow | Descripción |
|---|---|
| `ci.yml` | Pipeline de integración continua |
| `deploy-staging.yml` | Despliegue automático al entorno de staging |
| `deploy-production.yml` | Despliegue automático al entorno de producción |
| `health-check.yml` | Verificación periódica del estado de la aplicación |
| `terraform-ci.yml` | Validación y plan de infraestructura con Terraform |

---

## Semana 4 — Infraestructura como Código con Terraform

| Tema | Contenido |
|---|---|
| Introducción a Terraform | Provider `local`, variables, outputs, primer recurso de infraestructura |
| Variables y Locals | Variables complejas (`object`, `map`, `list`) con validaciones usando `regex`, `can()`, `contains()` |
| Funciones built-in | `merge()`, `concat()`, `formatdate()`, `cidrsubnet()`, `lookup()` |
| Multi-entorno | Configuración dinámica para dev / staging / prod via `.tfvars` |
| Módulos | Estructura modular para reusabilidad — módulo `docker-webapp` |
| Workspaces | Gestión de estados separados por entorno con Terraform Workspaces |
| Backend remoto | Estado en S3 (LocalStack) con locking |

**Estructura Terraform (multi-entorno):**

```
terraform/
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── modules/
    └── docker-webapp/    # Gestiona los 5 servicios de la Voting App + nginx
```

---

## Semana 5 — Kubernetes y Orquestación de Contenedores

| Tema | Contenido |
|---|---|
| Arquitectura Kubernetes | Componentes del clúster: control plane, nodos, pods |
| Objetos core | Pods, Deployments, Services, ConfigMaps, Secrets |
| Networking | Ingress controllers, DNS interno del clúster |
| Almacenamiento | PersistentVolumes y PersistentVolumeClaims |
| Despliegue de apps | Roxs Voting App orquestada en Kubernetes |

---

## Proyecto transversal — Roxs Voting App

Sistema de votación distribuido con cinco microservicios que sirvió como hilo conductor del desafío. Fue desplegado de distintas formas a lo largo de las semanas:

| Servicio | Tecnología | Función |
|---|---|---|
| `vote` | Python (Flask) | Interfaz de votación (puerto 8080) |
| `worker` | Node.js | Procesa votos desde Redis hacia PostgreSQL |
| `result` | Node.js | Visualiza resultados en tiempo real (puerto 3000) |
| `redis` | Redis | Cola de mensajes entre `vote` y `worker` |
| `db` | PostgreSQL | Almacenamiento persistente de votos |

| Semana | Método de despliegue |
|---|---|
| S1 | Vagrant + Ansible (VM local) |
| S2/S3 | Docker Compose + CI/CD automatizado |
| S4 | Infraestructura gestionada con Terraform |
| S5 | Orquestación con Kubernetes |

---

## Roadmap completo del desafío

El desafío #90DaysOfDevOps cubre las disciplinas principales del ecosistema DevOps moderno:

| Bloque | Disciplinas |
|---|---|
| Fundamentos | Linux · Bash Scripting · Git · Redes · Seguridad básica |
| Contenedores | Docker · Docker Compose · Registro de imágenes |
| Orquestación | Kubernetes · Helm · ArgoCD |
| CI/CD | GitHub Actions · Pipelines · Despliegue automatizado |
| IaC | Terraform · Ansible · Gestión de configuración |
| Cloud | AWS · GCP · Conceptos de arquitectura cloud |
| Observabilidad | Prometheus · Grafana · Logging centralizado |

---

## Recursos

- Desafío oficial: [90daysdevops.295devops.com](https://90daysdevops.295devops.com/)
- Rossana Suarez: [@roxsross](https://github.com/roxsross)
- Mi GitHub: [DavidBritto](https://github.com/DavidBritto)

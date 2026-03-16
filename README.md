# 90 Days of DevOps with Roxs — Portfolio

Repositorio de mi progreso en el desafío **#90DaysOfDevOps**, una iniciativa de [Rossana Suarez](https://90daysdevops.295devops.com/) diseñada para aplicar conceptos de DevOps de forma práctica durante 90 días consecutivos.

Cada semana cubre una disciplina diferente del ecosistema DevOps. Aquí documento ejercicios diarios, proyectos prácticos y los aprendizajes obtenidos a lo largo del camino.

---

## Entorno de trabajo

| Componente | Detalle |
|---|---|
| Sistema Operativo | Ubuntu 24.04 LTS |
| Editor | VS Code |
| Terminal | Zsh (nativa Linux) |
| Virtualización | VirtualBox + Vagrant |
| Contenedores | Docker + Docker Compose |
| IaC | Terraform |
| CI/CD | GitHub Actions |

---

## Estructura del repositorio

```
devops-portfolio/
├── daily-exercises/
│   ├── semana-1/          # Linux, Vagrant, Git, Bash, Ansible
│   ├── semana-2/          # Docker y contenedores
│   ├── semana-3/          # CI/CD con GitHub Actions
│   └── semana-4/          # Infraestructura como Código con Terraform
├── voting-app/            # Proyecto transversal: Roxs Voting App
└── .github/workflows/     # Pipelines de CI/CD activos
```

---

## Indice de semanas

### Semana 1 — Fundamentos: Linux, Git, Scripting y Ansible

| Dia | Tema | Contenido |
|---|---|---|
| Dia 2 | Linux | Comandos esenciales, sistema de archivos, permisos |
| Dia 3 | Vagrant | VM con Ubuntu, provisioning con scripts Bash, servidor web embebido |
| Dia 4 | Git | Flujo de trabajo, ramas, resolución de conflictos |
| Dia 5 | Bash Scripting | Scripts de monitoreo de disco, servicios, backups y automatización |
| Dia 6 | Ansible | Playbooks y roles: `nginx`, `devops_user`, `firewall` |

**Proyecto final S1:** [Roxs Voting App — Despliegue con Vagrant + Ansible](./voting-app/)
Arquitectura de microservicios (Python/Flask, Node.js, Redis, PostgreSQL) orquestada en una VM.

---

### Semana 2 — Contenedores con Docker

| Dia | Tema | Contenido |
|---|---|---|
| Dia 9 | Docker Basics | Primer contenedor, imagenes, ciclo de vida, NGINX en contenedor |
| Dia 10 | Imagenes | Dockerfiles, build de imagenes propias |
| Dia 11 | Redes | Redes Docker, comunicacion entre contenedores |
| Dia 12 | Volumenes | Persistencia de datos con volumenes |
| Dia 13 | Docker Compose | Definicion y orquestacion de servicios multi-contenedor |

---

### Semana 3 — CI/CD con GitHub Actions

| Dia | Tema | Contenido |
|---|---|---|
| Dia 15 | GitHub Actions | Primeros workflows: `hola-mundo.yml`, variables de entorno, condicionales por rama |
| Dia 18 | Runner Self-Hosted | VM dedicada con Vagrant como runner propio de GitHub Actions |
| Dia 19 | Despliegue Automatizado | Pipeline completo: push → build → `docker-compose up` en runner self-hosted |
| Dia 20 | Monitoreo y Logging | Health check endpoint, logging en Docker, workflow de monitoreo con `cron` |

**Workflows activos en este repositorio:**

| Workflow | Descripcion |
|---|---|
| `ci.yml` | Pipeline de integracion continua |
| `deploy-staging.yml` | Despliegue automatico al entorno de staging |
| `deploy-production.yml` | Despliegue automatico al entorno de produccion |
| `health-check.yml` | Verificacion periodica del estado de la aplicacion |
| `terraform-ci.yml` | Validacion y plan de infraestructura con Terraform |

---

### Semana 4 — Infraestructura como Codigo (IaC) con Terraform

| Dia | Tema | Contenido |
|---|---|---|
| Dia 22 | Introduccion a Terraform | Provider `local`, variables, outputs, primer recurso de infra |
| Dia 23 | Variables, Locals y tfvars | Variables avanzadas con validaciones, locals inteligentes, funciones built-in, configuracion multi-entorno |

**Estructura Terraform del proyecto (Dia 23):**

```
day-23/
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── templates/
    ├── config.tmpl
    ├── component.yaml.tpl
    └── service.yaml.tpl
```

**Conceptos trabajados en Dia 23:**
- Variables complejas: `object`, `map`, `list` con validaciones robustas usando `regex`, `can()`, `contains()`
- Locals inteligentes: naming conventions, tags estandarizados, configuraciones dinámicas por entorno
- Funciones built-in: `merge()`, `concat()`, `formatdate()`, `cidrsubnet()`, `lookup()`
- Variables sensibles para manejo seguro de secrets
- Configuración dinámica para microservicios con auto-sizing y estimación de costos
- Debugging con `terraform console` y `TF_LOG=DEBUG`

**Ejercicios prácticos:**
1. Sistema de configuración multi-ambiente con auto-sizing y estimación de costos
2. Validador de configuración avanzado con coherencia entre variables
3. Generador dinámico de configuración para microservicios con health checks y dependencias

---

## Proyecto transversal — Roxs Voting App

La **Roxs Voting App** es la aplicacion de referencia del desafio. Es un sistema de votacion distribuido con cinco microservicios:

| Servicio | Tecnologia | Funcion |
|---|---|---|
| `vote` | Python (Flask) | Interfaz de votacion (puerto 8080) |
| `worker` | Node.js | Procesa votos desde Redis hacia PostgreSQL |
| `result` | Node.js | Visualiza resultados en tiempo real (puerto 3000) |
| `redis` | Redis | Cola de mensajes entre `vote` y `worker` |
| `db` | PostgreSQL | Almacenamiento persistente de votos |

La aplicacion se ha desplegado de diferentes formas a lo largo del desafio:

- **S1:** Vagrant + Ansible (VM local)
- **S2/S3:** Docker Compose + CI/CD automatizado
- **S4:** Infraestructura gestionada con Terraform

---

## Recursos

- Desafio oficial: [90daysdevops.295devops.com](https://90daysdevops.295devops.com/)
- Creadora del desafio: [Rossana Suarez](https://github.com/roxsross)

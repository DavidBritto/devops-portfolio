# 🚀 90 Days of DevOps — Senior Engineering Portfolio Showcase

[![DevOps Roadmap](https://img.shields.io/badge/Roadmap-90%20Days%20DevOps-blueviolet?style=for-the-badge&logo=target)](https://90daysdevops.295devops.com/)
[![AWS Cloud](https://img.shields.io/badge/AWS-EKS%20%7C%20VPC%20%7C%20IRSA-232F3E?style=for-the-badge&logo=amazon-aws)](https://aws.amazon.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Kind%20%7C%20EKS%20v1.30-326CE5?style=for-the-badge&logo=kubernetes)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/IaC-HashiCorp%20Terraform-7B42BC?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD%20%26%20Rollouts-F46938?style=for-the-badge&logo=argo)](https://argoproj.github.io/)
[![Observability](https://img.shields.io/badge/Observability-Prometheus%20%7C%20Grafana%20%7C%20Jaeger-F46800?style=for-the-badge&logo=prometheus)](https://prometheus.io/)
[![DevSecOps](https://img.shields.io/badge/Security-Trivy%20%7C%20GitLeaks%20%7C%20Cosign%20%7C%20Kyverno-4EBAE4?style=for-the-badge&logo=vault)](https://aquasecurity.github.io/trivy/)

Repositorio de ingeniería y portafolio profesional de nivel de producción que documenta el cumplimiento íntegro del desafío de **90 Días de DevOps** de [Rossana Suárez (Roxs)](https://90daysdevops.295devops.com/). 

Este portafolio demuestra el dominio práctico y la aplicación de estándares de la industria sobre administración de sistemas Linux, containerización, integración y entrega continua (CI/CD), infraestructura como código (IaC), orquestación distribuida en Kubernetes, DevSecOps Shift-Left, observabilidad integral, emulación y despliegue real en AWS, GitOps y resiliencia SRE.

> 📘 **¿Buscás los fundamentos y prácticas guiadas paso a paso?**  
> Consultá la [**Guía de Supuestos de Arquitectura y Laboratorio Práctico de Seguridad y Observabilidad**](GUIA-DE-SUPUESTOS-Y-PRACTICA.md) para ejecutar todos los laboratorios en tu máquina local sin costos de nube.

---

## 🛠️ Stack Tecnológico y Arquitectura de la Plataforma

| Área Técnica | Herramientas Principales | Alcance de Implementación |
|---|---|---|
| **Sistemas Operativos & Virtualización** | Linux (Ubuntu LTS), Vagrant, VirtualBox | POSIX, FHS 3.0, cgroups v2, namespaces de Linux, systemd, redes privadas host-only. |
| **Automatización & Configuración** | Bash, Ansible | Scripts idempotentes de backup/mantenimiento, roles modulares, inventarios dinámicos. |
| **Containerización & Runtime** | Docker CE, Docker Compose | Multi-stage Dockerfiles, caching de capas, imágenes distroless/non-root, redes bridge. |
| **Infraestructura como Código (IaC)** | HashiCorp Terraform | HCL declarativo, arquitectura modular reutilizable, workspaces, remote backend S3 y locking. |
| **Orquestación en Contenedores** | Kubernetes (Kind y Amazon EKS) | Pods, Deployments, StatefulSets con EBS gp3, ConfigMaps, Secrets, RBAC, NetworkPolicies. |
| **CI/CD & Runners Escalables** | GitHub Actions, Actions Runner Controller (ARC) | Workflows automatizados con self-hosted runners en VMs y pods efímeros auto-escalados en K8s. |
| **GitOps & Progressive Delivery** | ArgoCD, Argo Rollouts | Patrón App of Apps, ApplicationSet multi-ambiente, Canary deployments y auto-rollback. |
| **Service Mesh & Tracing Distribuido** | Istio, Envoy, OpenTelemetry, Jaeger | Data Plane (Envoy sidecars), mTLS estricto Zero-Trust, Traffic Splitting L7, W3C TraceContext. |
| **DevSecOps & Supply Chain Security** | GitLeaks, Semgrep, Trivy, Cosign, Syft, Kyverno | Detección de secretos, SAST, escaneo de CVEs, firma de imágenes, SBOMs y Policy as Code. |
| **Observabilidad & Métricas** | Prometheus, Grafana, Alertmanager, Node/DB Exporters | TSDB, PromQL avanzado, metodologías USE y RED, Dashboards as Code, enrutamiento de alertas. |
| **Cloud Computing (Emulada y Real)** | LocalStack, Amazon Web Services (AWS) | VPC Multi-AZ, EKS, OIDC IRSA, EBS CSI, S3, DynamoDB, SQS, Lambda, ALB Controller. |
| **Performance & Resiliencia SRE** | Grafana k6, Chaos Mesh, Kubecost | Pruebas de estrés y soak testing, ingeniería del caos, optimización FinOps, Postmortems. |

---

## 📐 Arquitectura del Proyecto Central: Roxs Voting App

El hilo conductor del portafolio es un sistema distribuido políglota de 5 niveles que evolucionó a lo largo de las 13 semanas desde una máquina virtual hasta un clúster EKS de alta disponibilidad con Service Mesh y GitOps:

```
+---------------------------------------------------------------------------------------------------+
| ARQUITECTURA DE PRODUCCIÓN DE LA ROXS VOTING APP                                                  |
|                                                                                                   |
|  [CLIENTES & USUARIOS EXTERNOS]                                                                   |
|         |                                                                                         |
|         +---> https://vote.devopsroxs.click    (Route 53 -> AWS Application Load Balancer)        |
|         +---> https://result.devopsroxs.click  (Route 53 -> AWS Application Load Balancer)        |
|                                                                                                   |
|  [AMAZON EKS / KUBERNETES CLUSTER (Namespace: voting-app)]                                        |
|  +---------------------------------------------------------------------------------------------+  |
|  | ISTIO SERVICE MESH (Zero-Trust mTLS Estricto + Envoy Sidecars)                              |  |
|  |                                                                                             |  |
|  |  [Vote Frontend (Python / Flask)]              [Result Frontend (Node.js / Express)]        |  |
|  |  - Replicas: 3 (Auto-escaladas por HPA)        - Replicas: 2 (Dashboard en tiempo real)     |  |
|  |  - Hardened: non-root (UID 10001), drop ALL    - Hardened: non-root, read-only rootfs       |  |
|  |         |                                              |                                |  |
|  |         | 1. HTTP POST (Escribe en cola)               | 4. Consulta votos persistidos  |  |
|  |         v                                              v                                |  |
|  |  [Redis In-Memory Cache (Port 6379)]           [PostgreSQL Database 15 (Port 5432)]         |  |
|  |  - ClusterIP Service interno                   - StatefulSet con 1 réplica                  |  |
|  |  - AOF Persistence activo                      - PersistentVolumeClaim: ebs-gp3-sc (20 GiB) |  |
|  |         ^                                              ^                                |  |
|  |         | 2. Poll asíncrono                            | 3. Inserta y consolida votos   |  |
|  |         +-------- [Worker Processor (Node.js)] --------+                                |  |
|  |                   - Replicas: 2 (Escaladas por KEDA basado en tamaño de cola de Redis)      |  |
|  |                   - Sin puerto expuesto (Consumidor puro en segundo plano)                  |  |
|  +---------------------------------------------------------------------------------------------+  |
|                                                  |                                                |
|  [TELEMETRÍA, OBSERVABILIDAD & SEGURIDAD]        |                                                |
|  - Métricas: Prometheus TSDB raspando /metrics   - Tracing: OpenTelemetry -> Jaeger UI (Port 4317)|
|  - Alertas: Alertmanager notificando a Slack     - Seguridad: Kyverno bloqueando Pods no-root     |
|  - Dashboards: Grafana as Code (Port 3003)       - GitOps: ArgoCD reconciliando contra Git        |
+---------------------------------------------------------------------------------------------------+
```

---

## 🗺️ Programa Completo: Reto de 10 Semanas (Días 1 al 70)

### Semanas 1 a 3: Fundamentos de Sistemas, Contenedores y CI/CD
- **Semana 1 (Días 1 a 7)**: Kernel de Linux, jerarquía FHS 3.0, permisos POSIX, gestión de procesos, scripting Bash automatizado, virtualización declarativa con Vagrant y gestión de configuración con Ansible. *Desafío Final: Despliegue automatizado de servidor web con Ansible y Vagrant.*
- **Semana 2 (Días 8 a 14)**: Arquitectura de Docker (namespaces, cgroups, daemon vs runc), ciclo de vida de contenedores, Dockerfiles multi-stage, redes bridge personalizadas, volúmenes persistentes y orquestación con Docker Compose. *Desafío Final: Primer despliegue multi-contenedor de la Roxs Voting App.*
- **Semana 3 (Días 15 a 21)**: Pipelines de CI/CD en GitHub Actions, automatización de pruebas unitarias (`pytest`, `npm test`), build y push de imágenes a registros, runners auto-hospedados (Self-hosted) sobre Vagrant y despliegues automáticos a Staging. *Desafío Final: Pipeline CI/CD end-to-end con auto-runner y health-checks.*

### Semanas 4 a 6: Automatización, Infraestructura como Código y Kubernetes
- **Semana 4 (Días 22 a 28)**: Infraestructura como Código (IaC) con HashiCorp Terraform, variables y validaciones avanzadas, refactorización a módulos reutilizables por responsabilidad (`network`, `database`, `cache`, `services`), workspaces y remote backend S3 con LocalStack. *Desafío Final: Arquitectura modular completa de la Voting App con Terraform.*
- **Semana 5 (Días 29 a 35)**: Arquitectura distribuida de Kubernetes (Control Plane vs Worker Nodes), clústeres locales multi-nodo con Kind, Pods, Deployments con rolling updates, Services (`ClusterIP`, `NodePort`), ConfigMaps, Secrets y volúmenes PVC. *Desafío Final: Despliegue completo de la Voting App en Kubernetes.*
- **Semana 6 (Días 36 a 42)**: Actions Runner Controller (ARC) ejecutando runners efímeros en Kubernetes, Kustomize overlays para multi-ambiente (dev, staging, prod), sondas de salud (Liveness/Readiness/Startup probes), empaquetado con Helm y Helm Umbrella Chart. *Desafío Final: Umbrella Helm Chart gobernando toda la aplicación.*

### Semanas 7 a 9: DevSecOps, Observabilidad y Cloud Engineering
- **Semana 7 (Días 43 a 49)**: Cultura DevSecOps y paradigma Shift-Left, detección de secretos con GitLeaks, análisis SAST con Semgrep, escaneo de CVEs con Trivy, hardening de contenedores (no-root, read-only rootfs), RBAC de mínimo privilegio y Pod Security Standards (PSS Restricted). *Desafío Final: Pipeline de CI/CD con security gates automatizados.*
- **Semana 8 (Días 50 a 56)**: Observabilidad integral (métricas, logs estructurados, trazas), metodologías USE y RED, arquitectura pull de Prometheus TSDB, exporters en vivo (Node, Postgres, Redis), consultas PromQL analíticas, Grafana Dashboards as Code y enrutamiento en Alertmanager. *Desafío Final: Stack de observabilidad completo integrado a la Voting App.*
- **Semana 9 (Días 57 a 63)**: Cloud Engineering con LocalStack: simulación de AWS S3 con reglas de ciclo de vida y URLs prefirmadas, DynamoDB NoSQL, colas SQS y computación serverless con AWS Lambda aprovisionado vía Terraform. *Desafío Final: Pipeline serverless de auditoría de votos aprovisionado con Terraform sobre LocalStack.*

### Semana 10: Performance Testing, Disaster Recovery y Capstone Final (Días 64 a 70)
- **Semana 10 (Días 64 a 70)**: Pruebas de rendimiento con Grafana k6 (Load, Stress, Spike y Soak testing), automatización de releases semánticos, simulacros de Disaster Recovery con backups de PostgreSQL (RTO/RPO), Documentation as Code y pruebas integrales de resiliencia y caos. *Día 70: Capstone Final, Verificación End-to-End y Cierre del Reto.*

---

## ⚡ Inicio Rápido: Ejecutar el Proyecto Localmente

Podés ejecutar todo el entorno local con microservicios y observabilidad en menos de 2 minutos:

```bash
# 1. Clonar el repositorio
git clone https://github.com/DavidBritto/devops-portfolio.git
cd devops-portfolio

# 2. Levantar la aplicación de votos y el stack de observabilidad
cd voting-app/roxs-voting-app
docker compose up -d

# 3. Comprobar que los servicios estén saludables
docker compose ps

# 4. Acceder a los servicios:
# - Aplicación de Votos (Vote UI):       http://localhost:8080
# - Panel de Resultados (Result UI):    http://localhost:3000
# - Servidor de Métricas Prometheus:     http://localhost:9091
# - Dashboards de Monitoreo Grafana:     http://localhost:3003 (Credenciales: admin / admin)

# 5. Ejecutar la prueba de carga con Grafana k6
k6 run ../../daily-exercises/semana-10/dia-64/load-test.js
```

Para desplegar los manifiestos de Kubernetes en tu clúster local (Kind o Minikube):

```bash
# Ejecutar el script automatizado de despliegue en K8s
./deploy-k8s.sh
```

---

## 🗂️ Estructura del Repositorio

```
devops-portfolio/
├── GUIA-DE-SUPUESTOS-Y-PRACTICA.md # 📘 Guía maestra de supuestos y laboratorio práctico
├── README.md                       # Documento principal del portafolio
├── REPO_TREE.md                    # Árbol completo del repositorio
├── daily-exercises/                # Reto de 10 Semanas (Días 1 al 70) con código y documentación
│   ├── semana-1/  a  semana-3/     # Fundamentos (Linux, Vagrant, Ansible, Docker, CI/CD)
│   ├── semana-4/  a  semana-6/     # Automatización (Terraform, K8s Core, ARC, Helm)
│   ├── semana-7/  a  semana-9/     # DevSecOps, Observabilidad y Cloud Emulada (Trivy, Prometheus, LocalStack)
│   └── semana-10/                  # Performance k6, Disaster Recovery, Resiliencia y Capstone Día 70
├── voting-app/                     # Proyecto Central: Roxs Voting App
│   ├── roxs-voting-app/            # Código fuente, manifiestos K8s, Dockerfiles y monitoreo
│   ├── terraform/                  # Infraestructura modular en Terraform (dev, staging, prod)
│   └── monitoring/                 # Configuraciones de Prometheus, Grafana y Alertmanager
└── .github/workflows/              # Pipelines automatizados de CI/CD, seguridad y despliegue
```

---

## 👤 Autor y Reconocimientos

- **Ingeniero:** David Britto ([GitHub @DavidBritto](https://github.com/DavidBritto))
- **Currículum de Referencia:** Reto #90DaysOfDevOps por [Rossana Suárez (Roxs)](https://github.com/roxsross) — [90daysdevops.295devops.com](https://90daysdevops.295devops.com/)

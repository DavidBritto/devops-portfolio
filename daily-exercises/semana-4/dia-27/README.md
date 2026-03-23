# Día 27 — CI/CD con Terraform + LocalStack + S3 Backend

## 📋 Descripción

Implementación de un pipeline completo de **CI/CD para Infrastructure as Code** usando:

- **LocalStack** para simular servicios AWS localmente
- **Amazon S3** (vía LocalStack) como backend remoto para el estado de Terraform
- **GitHub Actions** para automatizar validación y despliegue
- **Terraform Workspaces** para gestionar múltiples ambientes (dev, staging, prod)

---

## 🧠 Conceptos Clave

### LocalStack
Plataforma que simula servicios de AWS en tu máquina local. Permite desarrollar y testear aplicaciones cloud **sin costos, sin credenciales reales y sin latencia de red**.

Servicios utilizados en este proyecto:
```
s3, ec2, iam, lambda, cloudformation, logs, events
```

### S3 como Terraform Backend
En lugar de guardar `terraform.tfstate` localmente, se almacena en un bucket S3. Esto permite:
- Estado compartido entre el equipo
- Versionado automático del archivo de estado
- Acceso desde cualquier pipeline de CI/CD
- Recuperación ante fallos

### La combinación perfecta para desarrollo
```
LocalStack simula S3 → Terraform usa ese S3 como backend → CI/CD consume el backend → sin costos reales
```

---

## 🗂️ Estructura del Proyecto

```
terraform-cicd-localstack/
├── .github/
│   └── workflows/
│       ├── terraform-ci.yml        # Pipeline de validación (PR)
│       ├── terraform-cd.yml        # Pipeline de despliegue (merge a main)
│       └── terraform-destroy.yml   # Pipeline de limpieza (manual)
├── docker-compose.localstack.yml   # Configuración de LocalStack
├── scripts/
│   ├── setup-localstack.sh         # Crea y configura el bucket S3
│   └── wait-for-localstack.sh      # Espera hasta que LocalStack esté listo
├── environments/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/
│   ├── docker-webapp/
│   └── s3-backend/
├── backend.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

---

## ⚙️ Configuración de LocalStack

LocalStack corre como un servicio Docker, exponiendo todos los endpoints de AWS en el puerto `4566`.

```yaml
# docker-compose.localstack.yml
services:
  localstack:
    image: localstack/localstack:3.0
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,ec2,iam,lambda,cloudformation,logs,events
      - PERSISTENCE=1        # Los datos sobreviven reinicios
      - DEBUG=1
```

### Scripts de soporte

**`setup-localstack.sh`** — Espera a LocalStack y crea el bucket S3 para el estado:
```bash
aws --endpoint-url=http://localhost:4566 s3 mb s3://terraform-state-roxs
aws --endpoint-url=http://localhost:4566 s3api put-bucket-versioning \
  --bucket terraform-state-roxs \
  --versioning-configuration Status=Enabled
```

**`wait-for-localstack.sh`** — Polling hasta que LocalStack responda (máx. 30 intentos):
```bash
curl -s "http://localhost:4566/_localstack/health"
```

---

## 🔄 Pipelines de GitHub Actions

### Pipeline CI — Validación en Pull Requests

**Trigger:** Pull Request hacia `main` con cambios en archivos `.tf`, `.tfvars` o workflows.

| Job | Descripción |
|-----|-------------|
| `validate` | Verifica formato (`fmt`), inicializa con backend S3 y valida sintaxis |
| `plan` | Genera plan para `dev` y `staging` en paralelo usando LocalStack |
| `comment-plan` | Publica el plan como comentario en el PR |

```yaml
on:
  pull_request:
    branches: [main]
    paths:
      - '**.tf'
      - '**.tfvars'
```

**Punto clave:** LocalStack corre como un *service container* dentro del runner de GitHub Actions:
```yaml
services:
  localstack:
    image: localstack/localstack:3.0
    ports:
      - 4566:4566
    options: >-
      --health-cmd "curl -f http://localhost:4566/_localstack/health || exit 1"
```

---

### Pipeline CD — Despliegue Automático

**Trigger:** Push a `main` con cambios en `.tf` / `.tfvars`, o ejecución manual.

| Job | Ambiente | Trigger |
|-----|----------|---------|
| `deploy-dev` | development | Automático al mergear |
| `deploy-staging` | staging | Automático, después de dev |
| `deploy-prod` | production | Solo manual (`workflow_dispatch`) |

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment: { type: choice, options: [dev, staging, prod] }
      action:      { type: choice, options: [plan, apply, destroy] }
```

Cada ambiente usa su propio **Terraform Workspace**:
```bash
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

---

### Pipeline Destroy — Limpieza Controlada

**Trigger:** Solo manual con confirmación explícita.

```yaml
on:
  workflow_dispatch:
    inputs:
      environment: { type: choice, options: [dev, staging, prod] }
      confirm:     { description: 'Escriba "DESTROY" para confirmar' }
```

El pipeline valida la confirmación antes de ejecutar cualquier acción:
```bash
if [ "${{ github.event.inputs.confirm }}" != "DESTROY" ]; then
  echo "Confirmación incorrecta"
  exit 1
fi
```

---

## 🌍 Variables por Ambiente

| Variable | dev | staging | prod |
|----------|-----|---------|------|
| `replica_count` | 1 | 2 | 3 |
| `memory_limit` | 256 MB | 512 MB | 1024 MB |
| `enable_monitoring` | false | true | true |
| `backup_enabled` | false | true | true |
| Puerto vote | 8080 | 8081 | 80 |

---

## 🔐 Secrets de GitHub Actions

Configurados en **Settings → Secrets and variables → Actions**:

| Secret | Descripción |
|--------|-------------|
| `DEV_DB_PASSWORD` | Password de base de datos para desarrollo |
| `STAGING_DB_PASSWORD` | Password de base de datos para staging |
| `PROD_DB_PASSWORD` | Password de base de datos para producción |

> Las credenciales de LocalStack (`test` / `test`) no necesitan secret ya que no son sensibles.

---

## 🚀 Flujo de Trabajo Completo

```
1. Iniciar LocalStack localmente
   └── docker-compose -f docker-compose.localstack.yml up -d

2. Configurar S3 backend
   └── ./scripts/setup-localstack.sh

3. Crear feature branch y hacer cambios
   └── git checkout -b feature/nueva-funcionalidad

4. Abrir Pull Request
   └── GitHub Actions CI ejecuta automáticamente:
       ├── Validación de formato y sintaxis
       ├── Plan para dev y staging
       └── Comentario con el plan en el PR

5. Merge a main
   └── GitHub Actions CD ejecuta automáticamente:
       ├── Despliega a development
       └── Despliega a staging

6. Despliegue a producción (manual)
   └── gh workflow run terraform-cd.yml -f environment=prod -f action=apply
```

---

## 🛠️ Comandos Útiles

```bash
# Iniciar / parar LocalStack
docker-compose -f docker-compose.localstack.yml up -d
docker-compose -f docker-compose.localstack.yml down

# Verificar estado de LocalStack
curl http://localhost:4566/_localstack/health

# Ver buckets S3 en LocalStack
aws --endpoint-url=http://localhost:4566 s3 ls

# Ver contenido del bucket de estado
aws --endpoint-url=http://localhost:4566 s3 ls s3://terraform-state-roxs/ --recursive

# Inicializar Terraform con backend S3 local
terraform init \
  -backend-config="endpoint=http://localhost:4566" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=test"

# Gestión de workflows con GitHub CLI
gh workflow list
gh run list --workflow=terraform-cd.yml
gh workflow run terraform-destroy.yml -f environment=dev -f confirm=DESTROY
```

---

## 🔍 Troubleshooting

| Error | Causa | Solución |
|-------|-------|----------|
| `LocalStack not ready` | Container no arrancó | Verificar `docker ps` y health endpoint |
| `S3 bucket not found` | Bucket no creado | Ejecutar `setup-localstack.sh` manualmente |
| `Backend initialization failed` | Endpoint incorrecto | Verificar `-backend-config="endpoint=http://localhost:4566"` |
| `Workspace doesn't exist` | Workspace no creado | Usar `terraform workspace select $ENV \|\| terraform workspace new $ENV` |
| `Port already in use` | Puerto 4566 ocupado | `docker stop $(docker ps -q --filter "publish=4566")` |

---

## 💡 Buenas Prácticas

- **Protección de ramas:** Requerir PR reviews y status checks antes de mergear a `main`
- **Ambientes:** `dev` sin restricciones → `staging` con reviewers opcionales → `prod` solo manual
- **Persistencia:** Habilitar `PERSISTENCE=1` en LocalStack para no perder datos entre reinicios
- **Secrets:** Nunca hardcodear credenciales reales; usar `test`/`test` solo para LocalStack
- **LocalStack es solo para desarrollo:** Para producción real, usar AWS con credenciales reales

---

## 📚 Lo Aprendido

- Integración de **LocalStack** como simulador de AWS en pipelines de CI/CD
- Configuración de **S3 como backend remoto** para el estado de Terraform
- Uso de **GitHub Actions service containers** para correr dependencias en los runners
- **Terraform Workspaces** para gestionar múltiples ambientes desde un mismo código
- Estrategia de **promotion entre ambientes**: dev → staging → prod con distintos niveles de aprobación
- **Secrets management** y separación de configuración por ambiente
- Pipelines de **destroy controlado** con confirmación explícita
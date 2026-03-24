# Día 27 — CI/CD con Terraform + LocalStack + S3 Backend

## Descripción

Implementación de un pipeline completo de **CI/CD para Infrastructure as Code** usando:

- **LocalStack** para simular servicios AWS dentro del runner de GitHub Actions
- **Amazon S3** (vía LocalStack) como backend remoto para el estado de Terraform
- **GitHub Actions** para automatizar validación y despliegue
- **Terraform Workspaces** para gestionar múltiples ambientes (dev, staging, prod)

---

## Conceptos Clave

### LocalStack como service container en CI

En lugar de mockear las llamadas a AWS, LocalStack corre como un contenedor real dentro del runner de GitHub Actions:

```yaml
services:
  localstack:
    image: localstack/localstack:3.0
    ports:
      - 4566:4566
    options: >-
      --health-cmd "curl -f http://localhost:4566/_localstack/health || exit 1"
      --health-interval 10s
      --health-retries 5
```

Esto permite que `terraform init`, `plan` y `apply` funcionen igual que contra AWS real, pero sin costos ni credenciales reales.

### S3 como Terraform Backend

```
LocalStack simula S3 → Terraform guarda estado ahí → CI/CD lee/escribe ese estado → sin costos reales
```

Beneficios: estado compartido entre jobs, versionado automático, recuperación ante fallos.

### Terraform Workspaces por ambiente

Cada ambiente (`dev`, `staging`, `prod`) vive en su propio workspace con su propio archivo de estado aislado:

```bash
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file="environments/dev.tfvars"
```

---

## Estructura de Workflows

| Workflow | Trigger | Qué hace |
|----------|---------|----------|
| `terraform-ci.yml` | PR hacia `main` (cambios en `.tf`/`.tfvars`) | validate + fmt-check + plan (dev y staging en paralelo) |
| `terraform-cd.yml` | Push a `main` o manual | deploy dev → staging automático, prod solo manual |
| `terraform-destroy.yml` | Solo manual, requiere escribir "DESTROY" | teardown controlado por ambiente |

### Protección de producción en el pipeline CD

```yaml
deploy-prod:
  needs: deploy-staging
  if: github.event_name == 'workflow_dispatch'
```

`prod` nunca se despliega automáticamente — requiere trigger manual explícito.

---

## Configuración del Backend S3 con LocalStack

El `terraform init` en CI requiere varios flags específicos para LocalStack:

```bash
terraform init \
  -backend-config="endpoints={s3=\"http://localhost:4566\",sts=\"http://localhost:4566\",iam=\"http://localhost:4566\"}" \
  -backend-config="access_key=test" \
  -backend-config="secret_key=test" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="skip_requesting_account_id=true" \
  -backend-config="use_path_style=true" \
  -reconfigure
```

---

## Errores Reales Encontrados y Debuggeados

Estos son los errores que aparecieron durante la implementación, documentados tal como ocurrieron.

---

### 1. `skip_requesting_account_id` no es un argumento válido del backend

**Error:**
```
Error: Invalid backend configuration argument
The backend configuration argument "skip_requesting_account_id" given on
the command line is not expected for the selected backend type.
```

**Causa:** Este flag fue introducido en Terraform 1.6.1. El proyecto usaba `TF_VERSION: 1.6.0`.

**Solución:** Actualizar a `TF_VERSION: 1.9.8` en los tres workflows.

---

### 2. `force_path_style` deprecated

**Warning:**
```
Warning: Deprecated Parameter
The parameter "force_path_style" is deprecated. Use parameter "use_path_style" instead.
```

**Causa:** El parámetro fue renombrado en versiones recientes del provider AWS de Terraform.

**Solución:** Reemplazar `force_path_style=true` por `use_path_style=true` en todos los `terraform init` y en `backend.tf`.

---

### 3. Error de AWS account ID al inicializar (STS/IAM 403)

**Error:**
```
Error: Retrieving AWS account details: AWS account ID not previously found
* retrieving caller identity from STS: operation error STS: GetCallerIdentity,
  StatusCode: 403, api error InvalidClientTokenId
* retrieving account information via iam:ListRoles,
  StatusCode: 403, api error InvalidClientTokenId
```

**Causa:** Terraform intenta resolver el account ID consultando STS e IAM. Los endpoints por defecto apuntan a AWS real, que rechaza las credenciales `test`/`test` de LocalStack.

**Solución:** Agregar los endpoints de STS e IAM al flag `-backend-config` de `terraform init`:

```bash
-backend-config="endpoints={s3=\"http://localhost:4566\",sts=\"http://localhost:4566\",iam=\"http://localhost:4566\"}"
```

Y en `backend.tf`:
```hcl
endpoints = {
  s3  = "http://localhost:4566"
  sts = "http://localhost:4566"
  iam = "http://localhost:4566"
}
```

---

### 4. Secretos detectados por GitGuardian en el historial de git

**Error en el PR:**
```
Detected hardcoded secrets in your pull request
Generic Password → terraform.tfvars
Generic Terraform Variable Secret → examples/simple-webapp/variables.tf
Generic Password → terraform.tfstate.backup
```

**Causa:** Tres archivos con información sensible fueron commiteados al repo:
- `terraform.tfvars` contenía `database_password = "postgres123"`
- `examples/simple-webapp/variables.tf` tenía `default = "dev_password_123"`
- `terraform.tfstate.backup` almacena el estado real de la infraestructura (incluye outputs sensibles)

**Solución:**
- Eliminar el `default` del `database_password` en variables de ejemplo (usar `sensitive = true` sin valor hardcodeado)
- Agregar a `.gitignore`: `*.tfstate`, `*.tfstate.*`, `*.tfvars`, `tfplan`
- Limpiar el historial de git con `git filter-branch` para eliminar esos archivos de todos los commits

---

### 5. Definiciones duplicadas en Terraform

**Error:**
```
Error: Duplicate output definition
output "application_urls" was already defined at outputs-docker.tf:2

Error: Duplicate resource "time_static" configuration
resource "time_static" "generated_at" already declared at main.tf:5
```

**Causa:** Al agregar el módulo `docker-webapp`, quedaron archivos `.tf` legacy en el directorio raíz que ya habían sido reemplazados:

| Archivo legacy | Reemplazado por |
|---|---|
| `outputs-docker.tf` | `outputs.tf` (usa `module.docker_webapp.*`) |
| `time.tf` | El recurso ya estaba en `main.tf` |
| `docker_stack.tf` | `modules/docker-webapp/main.tf` (además usaba atributo `image_id` inválido para el provider `calxus/docker`) |

**Solución:** Mover los tres archivos a `archive/` con extensión `.legacy.tf` (Terraform ignora archivos que no terminan en `.tf`).

---

### 6. PR sin historial común con `main`

**Error en GitHub:**
```
There isn't anything to compare.
main and feature/day27-cicd-localstack are entirely different commit histories.
```

**Causa:** Al usar `git filter-branch --all` para limpiar secretos del historial, se reescribieron **todos** los branches locales incluyendo `main`. Pero solo se hizo force-push del feature branch, no de `main`. El remote `main` mantuvo el historial original, creando dos historiales incompatibles.

**Solución:** Crear un branch nuevo desde `origin/main` y copiar los archivos del feature branch:

```bash
git fetch origin
git checkout -b feature/day27-clean origin/main
git checkout feature/day27-cicd-localstack -- .
# remover archivos que no deben ir en git
git rm --cached terraform.tfstate terraform.tfstate.backup terraform.tfvars tfplan
git commit && git push origin feature/day27-clean
```

---

## Comandos Útiles

```bash
# Levantar LocalStack localmente
docker-compose -f voting-app/roxs-voting-app/terraform/docker-compose.localstack.yml up -d

# Crear bucket de estado
./scripts/setup-localstack.sh

# Verificar estado de LocalStack
curl http://localhost:4566/_localstack/health | jq .

# Ver estado almacenado en S3
aws --endpoint-url=http://localhost:4566 s3 ls s3://terraform-state-roxs/ --recursive

# Gestionar workflows con GitHub CLI
gh workflow list
gh run list --workflow=terraform-ci.yml
gh workflow run terraform-destroy.yml -f environment=dev -f confirm=DESTROY
```

---

## Lo Aprendido

- **LocalStack como service container** en GitHub Actions: permite CI/CD real contra AWS simulado sin costos
- **S3 backend** para estado compartido entre jobs del pipeline
- **Endpoints explícitos para STS e IAM** son necesarios cuando LocalStack maneja la autenticación
- **`use_path_style`** reemplaza a `force_path_style` en versiones recientes de Terraform
- **`skip_requesting_account_id`** requiere Terraform >= 1.6.1
- **`git filter-branch --all` reescribe todos los branches** — solo hacer force-push de lo que se reescribió
- Los archivos `.tfstate`, `.tfvars` y binarios de providers **nunca deben commitearse**
- Los archivos `.tf` legacy deben ir a una carpeta `archive/` con extensión `.legacy.tf` para que Terraform los ignore

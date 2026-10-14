# Dia 36 - CI/CD a Kubernetes con GitHub Actions y Runners escalables (ARC)

## 1) Objetivo del dia

Montar un pipeline de despliegue automatico a Kubernetes usando:

- **Kind** como cluster local de desarrollo/CI.
- **Actions Runner Controller (ARC)** con runners que escalan bajo demanda en el cluster.
- **GitHub Actions** como orquestador del pipeline (push -> workflow -> `kubectl apply`).

Tiempo estimado del lab: ~60 minutos.

## 2) Que problema resuelve CI/CD a Kubernetes

Sin automatizacion, cada despliegue depende de un humano con acceso al cluster (`kubectl`, kubeconfig, contexto correcto). Eso escala mal y aumenta errores.

Con CI/CD:

1. El desarrollador hace **push** a una rama protegida (p. ej. `main`).
2. GitHub dispara un **workflow**.
3. Un **runner** ejecuta los pasos (build, test, deploy).
4. El runner aplica manifiestos o actualiza imagenes en el cluster.

**Entrevista:** CI (integracion continua) valida que el codigo compila y pasa tests en cada cambio; CD (entrega/despliegue continuo) publica esos cambios en un entorno. En este dia el foco es el tramo **CD a K8s** con runners auto-escalables.

## 3) Kind (Kubernetes IN Docker)

Kind crea nodos de Kubernetes como **contenedores Docker**. Ideal para labs, pruebas y pipelines sin VMs ni cloud.

| Ventaja     | Detalle |
|-------------|---------|
| Rapido      | Crear/destruir cluster en segundos |
| Ligero      | Menos recursos que un cluster "real" |
| Multi-nodo  | Simula control-plane + workers en local |
| CI-friendly | Mismo patron que muchos pipelines de integracion |

Config tipica del dia:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: arc-cluster
nodes:
- role: control-plane
- role: worker
```

Documentacion: https://kind.sigs.k8s.io/

**Entrevista:** Kind no es para produccion; es para **desarrollo, tests e integracion**. En produccion usas EKS, GKE, AKS o clusters bare-metal gestionados.

## 4) GitHub Actions en 30 segundos

Componentes clave:

| Pieza        | Rol                                                          |
|--------------|--------------------------------------------------------------|
| **Workflow** | YAML en `.github/workflows/`; define eventos (`on:`) y jobs  |
| **Job**      | Conjunto de steps que corren en el mismo runner              |
| **Step**     | Comando `run:` o accion `uses:`                              |
| **Runner**   | Maquina donde se ejecuta el job (hosted o self-hosted)       |

Eventos comunes del dia:

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:   # ejecucion manual desde la UI
```

**Entrevista:** `runs-on: ubuntu-latest` usa runners de GitHub (minutos facturables). `runs-on: mi-runners` apunta a un **runner scale set** gestionado por ARC en tu cluster.

## 5) Runners: hosted vs self-hosted

| Tipo | Pros | Contras |
|------|------|---------|
| **GitHub-hosted** | Cero mantenimiento, imagenes preinstaladas | Costo por minuto, sin acceso directo a red interna/K8s |
| **Self-hosted** | Acceso a VPC, registry privado, cluster local | Tu mantienes OS, parches, seguridad |
| **ARC (self-hosted en K8s)** | Escala pods bajo demanda, `minRunners=0` ahorra recursos | Requiere GitHub App, Helm, cluster operativo |

**Entrevista:** por que self-hosted en K8s para desplegar **en el mismo cluster**? El runner ya esta en la red del cluster; puede montar kubeconfig o usar in-cluster config sin exponer credenciales fuera del entorno.

## 6) Actions Runner Controller (ARC)

ARC es el operador que sincroniza la demanda de jobs de GitHub con **pods de runner** en Kubernetes.

Arquitectura simplificada:

```
GitHub (workflow en cola)
    -> GitHub App (auth)
    -> ARC Controller (namespace arc-systems)
    -> Runner Scale Set (namespace arc-runners)
    -> Pod runner (se crea al llegar un job, se destruye al terminar)
    -> kubectl apply / deploy
```

Piezas del dia:

| Recurso Helm | Namespace | Funcion |
|--------------|-----------|---------|
| `gha-runner-scale-set-controller` | `arc-systems` | Controller que observa GitHub y reconcilia runners |
| `gha-runner-scale-set` | `arc-runners` | Conjunto de runners ligado a un repo/org (`githubConfigUrl`) |

Parametros importantes del scale set:

- `minRunners: 0` -- sin jobs, cero pods (ahorro).
- `maxRunners: 3` -- tope de concurrencia en el lab.
- `githubConfigSecret` -- Secret con credenciales de GitHub App.

**Entrevista:** diferencia entre el **controller** (un deployment estable en `arc-systems`) y el **scale set** (pods efimeros de runner en `arc-runners`). El controller no ejecuta tus workflows; solo provisiona runners.

## 7) Autenticacion: GitHub App (no PAT en produccion)

El material del dia usa una **GitHub App** instalada en el repositorio:

| Dato | Uso |
|------|-----|
| App ID | Identifica la app |
| Installation ID | Instalacion en org/repo concreto |
| Private key (.pem) | JWT para autenticar contra la API de GitHub |

Permisos minimos del lab:

- Repository: **Actions Read**, **Metadata Read**
- Organization: **Self-hosted runners Write**

Se guardan en un Secret de Kubernetes:

```bash
kubectl create secret generic github-auth \
  --namespace=arc-runners \
  --from-literal=github_app_id="..." \
  --from-literal=github_app_installation_id="..." \
  --from-file=github_app_private_key=private-key.pem
```

**Entrevista:** GitHub App vs Personal Access Token (PAT) -- la App tiene permisos granulares, rotacion de claves y mejor auditoria; el PAT suele ser de un usuario y es mas amplio. En empresas prefieren App u OIDC.

## 8) Helm en el flujo

Helm instala charts OCI del proyecto oficial:

```bash
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller

helm install arc \
  --namespace arc-systems --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

helm install mi-runners \
  --namespace arc-runners \
  --set githubConfigUrl="https://github.com/USUARIO/REPO" \
  --set githubConfigSecret=github-auth \
  --set maxRunners=3 --set minRunners=0 \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

**Entrevista:** Helm separa **plantilla + valores** (`--set`); facilita versionar la misma chart con distintos repos (`githubConfigUrl`) o limites de escala.

## 9) Proyecto de despliegue (arc-demo)

Stack minima del dia:

| Artefacto | Contenido |
|-----------|-----------|
| `Dockerfile` + `index.html` | App nginx estatica (demo) |
| `k8s/deployment.yaml` | 2 replicas, limits CPU/mem |
| `k8s/service.yaml` | NodePort 30080 -> puerto 80 |
| `.github/workflows/deploy.yml` | Job en `runs-on: mi-runners` |

El workflow del material aplica manifiestos con la imagen `nginx:alpine` (sin build/push de imagen propia en la version basica). Es valido para aprender el **cableado CI -> K8s**; en produccion anadirias build de imagen, scan y push a un registry.

## 10) Flujo completo del dia

```
1. kind create cluster
2. helm install ARC controller + runner scale set
3. push a main en el repo del demo
4. GitHub encola job "Deploy con ARC"
5. ARC crea pod runner (visible en arc-runners)
6. Runner: checkout -> kubectl get nodes -> kubectl apply -f k8s/
7. rollout status deployment/arc-demo-app
8. App accesible via NodePort o port-forward
```

**Entrevista:** el runner necesita **kubectl** y **kubeconfig** (o ServiceAccount in-cluster). En Kind local, el runner suele compartir acceso al API server del host/cluster; si falla, el material sugiere instalar kubectl en el step del workflow.

## 11) Recursos y limites en el Deployment

El deployment de demo define `requests` y `limits`:

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

**Entrevista:** `requests` afectan scheduling (kube-scheduler); `limits` cortan uso excesivo (OOMKill si supera memoria). Sin requests, un pod "ruidoso" puede degradar el nodo.

## 12) Service NodePort

```yaml
type: NodePort
ports:
- port: 80
  targetPort: 80
  nodePort: 30080
```

Acceso en Kind: `kubectl port-forward service/arc-demo-service 8080:80` (Kind no expone NodePort al host igual que Minikube sin config extra).

**Entrevista:** NodePort abre un puerto en **todos los nodos** (rango 30000-32767). En cloud suele ir detras de LoadBalancer o Ingress.

## 13) Comandos de observabilidad

```bash
kubectl get pods -n arc-systems    # controller
kubectl get pods -n arc-runners    # runners efimeros
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller
kubectl rollout status deployment/arc-demo-app
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 14) Errores comunes

| Sintoma | Causa probable |
|---------|----------------|
| No se crean runners | Secret `github-auth` mal, Installation ID incorrecto, permisos de la App |
| Workflow no encuentra runner | `runs-on` no coincide con nombre del helm release / scale set |
| `kubectl` no encontrado en runner | Imagen del runner sin kubectl; instalar en un step |
| `kubectl` sin acceso al cluster | Falta kubeconfig montado en el runner (avanzado; ver nota en ejecucion) |
| App no responde en :30080 | En Kind usar port-forward; NodePort no siempre mapea al host |

## 15) Preguntas tipicas de entrevista

1. **Que es ARC y que problema resuelve?** Auto-provisiona runners de GitHub Actions como pods en K8s, escalando segun cola de jobs.
2. **Por que `minRunners=0`?** No pagar CPU/memoria cuando no hay builds; trade-off es cold start al primer job.
3. **GitHub-hosted vs ARC en el mismo cluster donde despliegas?** ARC evita salir a internet para tocar el API de Kubernetes y permite politicas de red internas.
4. **Que es Kind y cuando NO lo usarias?** Cluster local en Docker; no para cargas de produccion ni SLAs empresariales.
5. **Diferencia controller vs runner scale set?** Controller reconcilia estado global; scale set es la plantilla de pods runner para un `githubConfigUrl`.
6. **Como se autentica ARC con GitHub?** GitHub App (App ID + Installation ID + private key) almacenada en Secret de K8s.
7. **Que hace `workflow_dispatch`?** Permite disparar el pipeline manualmente desde Actions (util en labs y hotfix).
8. **CI vs CD en este ejercicio?** El workflow asume codigo ya en repo; el paso critico es CD (`kubectl apply`, `rollout status`).
9. **Por que Helm OCI (`oci://ghcr.io/...`)?** Charts empaquetados como artefactos OCI en GHCR; patron moderno frente a solo `helm repo` HTTP.
10. **Como verificarias un despliegue exitoso?** `rollout status`, pods Ready, Service con endpoints, curl al puerto expuesto.

## 16) Metricas de exito

- Cluster Kind con 2 nodos Ready
- Pods del controller Running en `arc-systems`
- Al disparar workflow, aparece pod runner en `arc-runners` y desaparece al terminar
- Workflow verde en GitHub Actions
- `deployment/arc-demo-app` con 2/2 replicas Ready
- `curl` via port-forward responde HTML de la demo

## 17) Diagrama mental

```
Host (Docker)
└── Kind cluster: arc-cluster
    ├── arc-systems/
    │   └── gha-runner-scale-set-controller
    ├── arc-runners/
    │   └── runner pods (efimeros, runs-on: mi-runners)
    └── default (o namespace app)/
        ├── Deployment arc-demo-app (x2)
        └── Service arc-demo-service (NodePort 30080)

GitHub repo
└── .github/workflows/deploy.yml
    └── push main -> job en mi-runners -> kubectl apply
```

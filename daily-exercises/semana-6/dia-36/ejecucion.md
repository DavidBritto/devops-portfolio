# Dia 36 - Ejecucion hands-on (CI/CD a Kubernetes con ARC y Kind)

## Objetivo

Crear un cluster **Kind**, instalar **Actions Runner Controller (ARC)** con runners auto-escalables, montar un repo demo con workflow de GitHub Actions y desplegar una app nginx en Kubernetes desde el pipeline.

Material teorico: `teoria.md` (mismo directorio) y `daily-exercises/teoria diaria/dia-36.md`.

Directorio de trabajo del dia:

```text
/home/david/git/devops-porfolio/daily-exercises/semana-6/dia-36/
```

Los manifiestos de Kind/ARC y el mini-proyecto `k8s-arc-demo` **los creas tu** siguiendo cada paso (o en un repo GitHub dedicado para el workflow).

## Requisitos

Herramientas (Ubuntu/Debian de referencia):

```bash
sudo apt update


# Kind v0.29.0
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Helm 3
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Ademas:

- Cuenta GitHub con permiso para crear **GitHub Apps** e instalarlas en un repo.
- Repo vacio en GitHub para el demo (p. ej. `k8s-arc-demo`).
- Docker en ejecucion (`docker ps` sin error).

```bash
cd /home/david/git/devops-porfolio/daily-exercises/semana-6/dia-36
docker ps
kind version
kubectl version --client
helm version
```

**Captura #1:** salida de `docker ps`, `kind version` y `kubectl version --client` (entorno listo).

---

## Paso 1 - Cluster Kind

Crea `kind-config.yaml` en este directorio:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: arc-cluster
nodes:
- role: control-plane
- role: worker
```

```bash
kind create cluster --config kind-config.yaml
kubectl get nodes
```

Esperado: `arc-cluster-control-plane` y `arc-cluster-worker` en estado **Ready**.

**Captura #2:** salida de `kubectl get nodes` con los dos nodos Ready.

---

## Paso 2 - GitHub App para ARC

En GitHub (interfaz web):

1. **Settings** -> **Developer settings** -> **GitHub Apps** -> **New GitHub App**
2. Nombre unico: `mi-arc-app-<random>`
3. Homepage URL: `https://github.com`
4. Webhook URL: `https://example.com` (no afecta este lab)
5. Permisos:
   - Repository: **Actions** Read, **Metadata** Read
   - Organization: **Self-hosted runners** Write
6. Crear app -> generar **Private key** (.pem) -> **Install app** en tu usuario/org y en el repo del demo
7. Anotar:
   - **App ID** (pagina principal de la app)
   - **Installation ID** (URL tras instalar: `.../installations/NUMERO`)
   - Archivo `private-key.pem`

En tu maquina (NO subir estos archivos al repo publico):

```bash
cd /home/david/git/devops-porfolio/daily-exercises/semana-6/dia-36

cat > arc-secrets.env << 'EOF'
GITHUB_APP_ID=TU_APP_ID
GITHUB_APP_INSTALLATION_ID=TU_INSTALLATION_ID
EOF
# Copia private-key.pem al mismo directorio (descargado de GitHub)
chmod 600 private-key.pem arc-secrets.env
```

**Captura #3:** pantalla de GitHub App mostrando App ID y permisos configurados (oculta datos sensibles en la captura).

---

## Paso 3 - Instalar ARC Controller

```bash
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

helm install arc \
  --namespace arc-systems \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller

kubectl get pods -n arc-systems -w
```

Espera pod del controller en **Running** (Ctrl+C al salir del watch).

```bash
kubectl get pods -n arc-systems
```

**Captura #4:** pod `arc-gha-rs-controller` (o similar) en estado Running en `arc-systems`.

---

## Paso 4 - Secret y Runner Scale Set

```bash
source arc-secrets.env

kubectl create namespace arc-runners

kubectl create secret generic github-auth \
  --namespace=arc-runners \
  --from-literal=github_app_id="$GITHUB_APP_ID" \
  --from-literal=github_app_installation_id="$GITHUB_APP_INSTALLATION_ID" \
  --from-file=github_app_private_key=private-key.pem

kubectl get secret github-auth -n arc-runners
```

Instalar scale set (ajusta URL a tu repo):

```bash
export GITHUB_CONFIG_URL="https://github.com/TU-USUARIO/TU-REPO"

helm install mi-runners \
  --namespace arc-runners \
  --set githubConfigUrl="$GITHUB_CONFIG_URL" \
  --set githubConfigSecret=github-auth \
  --set maxRunners=3 \
  --set minRunners=0 \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set

kubectl get pods -n arc-runners
```

Con `minRunners=0` puede no haber pods hasta el primer workflow; es normal.

**Captura #5:** `kubectl get secret github-auth -n arc-runners` y salida de `helm list -n arc-runners`.

---

## Paso 5 - Proyecto demo (repo GitHub)

Crea el proyecto (puede vivir fuera del portfolio o clonarse en un repo nuevo):

```bash
mkdir -p k8s-arc-demo/.github/workflows k8s-arc-demo/k8s
cd k8s-arc-demo
```

### 5.1 Dockerfile e index.html

`Dockerfile`:

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
```

`index.html` (pagina estatica de demo; el timestamp del material original es solo ilustrativo):

```html
<!DOCTYPE html>
<html>
<head>
    <title>ARC Demo</title>
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        h1 { color: #326CE5; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Desplegado con ARC</h1>
        <p>Esta aplicacion se desplego usando GitHub Actions Runners en Kubernetes.</p>
    </div>
</body>
</html>
```

### 5.2 Manifiestos Kubernetes

`k8s/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: arc-demo-app
  labels:
    app: arc-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: arc-demo
  template:
    metadata:
      labels:
        app: arc-demo
    spec:
      containers:
      - name: app
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
```

`k8s/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: arc-demo-service
spec:
  selector:
    app: arc-demo
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
```

### 5.3 Workflow

`.github/workflows/deploy.yml`:

```yaml
name: Deploy con ARC

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: mi-runners

    steps:
    - name: Checkout codigo
      uses: actions/checkout@v4

    - name: Ver info del runner
      run: |
        echo "Ejecutandose en runner ARC"
        echo "Hostname: $(hostname)"
        echo "Usuario: $(whoami)"
        kubectl version --client || true

    - name: Setup kubectl si falta
      run: |
        if ! command -v kubectl >/dev/null 2>&1; then
          curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
          chmod +x kubectl
          sudo mv kubectl /usr/local/bin/
        fi
        kubectl version --client

    - name: Verificar cluster
      run: |
        echo "Verificando conexion a Kubernetes..."
        kubectl get nodes
        kubectl get namespaces

    - name: Aplicar manifiestos
      run: |
        echo "Desplegando aplicacion..."
        kubectl apply -f k8s/deployment.yaml
        kubectl apply -f k8s/service.yaml

    - name: Esperar despliegue
      run: |
        kubectl rollout status deployment/arc-demo-app --timeout=300s

    - name: Verificar resultado
      run: |
        kubectl get pods -l app=arc-demo
        kubectl get service arc-demo-service
```

**Nota importante:** el runner en K8s debe tener acceso al API server de Kind (kubeconfig del host o configuracion in-cluster avanzada). Si `kubectl get nodes` falla en el workflow, revisa la seccion Debug mas abajo.

### 5.4 Subir a GitHub <-- quede aca >

```bash
git init
git add .
git commit -m "Proyecto inicial con ARC"
git remote add origin https://github.com/TU-USUARIO/TU-REPO.git
git branch -M main
git push -u origin main
```

**Captura #6:** estructura del repo en GitHub con `.github/workflows/deploy.yml` y carpeta `k8s/`.

---

## Paso 6 - Disparar workflow y observar runners

Terminal 1 (monitoreo runners):

```bash
watch -n 2 kubectl get pods -n arc-runners
```

Terminal 2 o navegador:

1. Repo en GitHub -> pestana **Actions**
2. Workflow **Deploy con ARC** -> **Run workflow** (o esperar el push a `main`)

Al encolar el job deberia aparecer un pod runner en `arc-runners` y desaparecer al finalizar.

**Captura #7:** terminal con `kubectl get pods -n arc-runners` mostrando un runner **Running** mientras el job ejecuta.

**Captura #8:** GitHub Actions con el workflow en verde y logs de `kubectl get nodes` / `kubectl apply`.

---

## Paso 7 - Verificar aplicacion en el cluster

```bash
kubectl get pods -l app=arc-demo
kubectl get svc arc-demo-service
kubectl rollout status deployment/arc-demo-app
```

Acceso (Kind: port-forward es lo mas fiable):

```bash
kubectl port-forward service/arc-demo-service 8080:80
```

Otra terminal:

```bash
curl -s http://localhost:8080 | head -20
```

**Captura #9:** salida de `kubectl get pods -l app=arc-demo` (2/2 Ready) y respuesta de `curl` con el titulo "Desplegado con ARC".

---

## Debug rapido

```bash
# Secretos ARC
kubectl get secrets -n arc-runners
kubectl describe secret github-auth -n arc-runners

# Logs controller
kubectl logs -n arc-systems -l app.kubernetes.io/name=gha-runner-scale-set-controller --tail=50

# Logs runners
kubectl logs -n arc-runners -l actions.github.com/scale-set-name=mi-runners --tail=50

# Eventos
kubectl get events -n arc-runners --sort-by=.metadata.creationTimestamp | tail -15
kubectl get events --sort-by=.metadata.creationTimestamp | tail -15
```

| Sintoma | Que revisar |
|---------|-------------|
| No se crean runners | App ID, Installation ID, private key, permiso Self-hosted runners Write |
| Job en cola eterna | `runs-on: mi-runners` debe coincidir con el release Helm `mi-runners` |
| kubectl falla en runner | Step Setup kubectl; kubeconfig no montado en el pod runner |
| deployment no actualiza | Logs del step "Aplicar manifiestos"; contexto kubectl incorrecto |
| curl falla | port-forward activo; pods Ready |

Si el runner no alcanza el cluster Kind del host, opciones avanzadas (fuera del YAML minimo):

- Montar kubeconfig del host en el runner via Helm values / volumen.
- Ejecutar Kind **dentro** del mismo entorno que los runners (patron CI mas reproducible).

---

## Comandos utiles de referencia

```bash
kubectl get pods --all-namespaces
kubectl describe runners -n arc-runners 2>/dev/null || true
helm list -A
kind get clusters
```

---

## Limpieza (opcional)

```bash
helm uninstall mi-runners -n arc-runners
helm uninstall arc -n arc-systems
kubectl delete namespace arc-runners
kubectl delete namespace arc-systems
kubectl delete deployment arc-demo-app 2>/dev/null || true
kubectl delete service arc-demo-service 2>/dev/null || true
kind delete cluster --name arc-cluster
```

Borra `private-key.pem` y `arc-secrets.env` del disco si ya no los necesitas.

---

## Resenas importantes (reforzar al cerrar el dia)

1. **Flujo completo DevOps:** push -> GitHub Actions -> ARC crea runner -> kubectl despliega en K8s -> verificacion con rollout y curl.
2. **Kind** es el cluster de laboratorio; mismo concepto aplica en EKS/GKE cambiando solo el destino del kubeconfig.
3. **ARC escala a cero** (`minRunners=0`): ahorra recursos; el primer job puede tardar mas en arrancar el pod runner.
4. **Controller vs scale set:** no confundir el pod estable del controller con los runners efimeros que ejecutan tus jobs.
5. **GitHub App** es el patron correcto de auth para ARC; guardar la private key en Secret de K8s, nunca en el repo.
6. **`runs-on`** en el workflow debe alinear con el nombre del Helm release del scale set (`mi-runners` en este lab).
7. **Helm OCI** (`oci://ghcr.io/...`) instala charts oficiales sin clonar repos manualmente.
8. **CD vs build de imagen:** este dia despliega `nginx:alpine` directo; el siguiente paso natural es pipeline con `docker build`, push a registry e `image:` con tag versionado.
9. **NodePort en Kind** no siempre equivale a `localhost:30080`; **port-forward** es la verificacion fiable en local.
10. **Entrevista:** explicar por que self-hosted runners en el cluster reducen friccion para desplegar en K8s privado y como `maxRunners` limita concurrencia y costo.

## Documentacion para compartir (#DevOpsConRoxs)

Screenshots minimos del dia: **#2** (nodos Kind), **#7** (runner apareciendo en `arc-runners`), **#8** (workflow verde en Actions), **#9** (pods Ready + curl). Anota si el cuello de botella fue la GitHub App, el kubeconfig del runner o el primer cold start de ARC.

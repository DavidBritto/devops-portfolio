# Dia 34 - Ejecucion hands-on (Namespaces)

## Objetivo

Crear namespaces para dev y prod, desplegar la misma aplicacion con distinto numero de replicas, practicar filtros por namespace (`-n`, `-A`, contexto) y completar el ejercicio **tienda online** en dos ambientes.

Los manifiestos YAML **no estan en el repo**: los creas tu en este directorio siguiendo cada paso (contenido basado en `daily-exercises/teoria diaria/dia-34-namespaces.md`).

> **Nota:** el `tienda-desarrollo.yaml` del material fuente original tiene YAML incompleto; aqui va la version corregida. MySQL en Minikube necesita al menos **512Mi request / 1Gi limit** (leccion del dia 33).

## Requisitos

- Cluster local (Minikube) y `kubectl` funcionando.
- Directorio del dia: `daily-exercises/semana-5/dia-34/`

```bash
cd /home/david/git/devops-porfolio/daily-exercises/semana-5/dia-34
minikube status
kubectl get nodes
kubectl get ns
```

**Captura #1:** salida de `kubectl get ns` (namespaces por defecto visibles).

---

## Paso 1 - Namespaces basicos (YAML)

Crea `mis-namespaces.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mi-app-dev
  labels:
    ambiente: desarrollo
    proyecto: mi-aplicacion
---
apiVersion: v1
kind: Namespace
metadata:
  name: mi-app-prod
  labels:
    ambiente: produccion
    proyecto: mi-aplicacion
```

Aplicar:

```bash
kubectl apply -f mis-namespaces.yaml
kubectl get ns --show-labels | grep mi-app
```

**Captura #2:** `mi-app-dev` y `mi-app-prod` con sus labels.

---

## Paso 2 - Aplicacion en desarrollo (1 replica)

Crea `app-desarrollo.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: mi-app-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        ambiente: desarrollo
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: mi-app-dev
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    nodePort: 30100
  type: NodePort
```

```bash
kubectl apply -f app-desarrollo.yaml
kubectl get all -n mi-app-dev
```

**Captura #3:** 1 pod `web-app` en estado `Running` dentro de `mi-app-dev`.

---

## Paso 3 - Aplicacion en produccion (3 replicas, mismo nombre)

Crea `app-produccion.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: mi-app-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
        ambiente: produccion
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: mi-app-prod
spec:
  selector:
    app: web-app
  ports:
  - port: 80
    nodePort: 30200
  type: NodePort
```

```bash
kubectl apply -f app-produccion.yaml
kubectl get deployments -n mi-app-dev
kubectl get deployments -n mi-app-prod
kubectl get pods -A | grep web-app
```

**Captura #4:** dev con **1** replica y prod con **3**; mismo nombre `web-app`, namespaces distintos.

Acceso rapido (opcional):

```bash
echo "Dev:  http://$(minikube ip):30100"
echo "Prod: http://$(minikube ip):30200"
```

---

## Paso 4 - Cambiar namespace por defecto del contexto

```bash
kubectl config set-context --current --namespace=mi-app-dev
kubectl get pods
kubectl config view --minify | grep namespace:
kubectl config set-context --current --namespace=default
```

**Captura #5:** `kubectl get pods` mostrando solo pods de `mi-app-dev` (sin flag `-n`) mientras el contexto apunta a ese namespace.

---

## Paso 5 - Ejercicio tienda online: namespaces

Crea `tienda-namespaces.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tienda-dev
  labels:
    proyecto: tienda-online
    ambiente: desarrollo
---
apiVersion: v1
kind: Namespace
metadata:
  name: tienda-prod
  labels:
    proyecto: tienda-online
    ambiente: produccion
```

```bash
kubectl apply -f tienda-namespaces.yaml
kubectl get ns tienda-dev tienda-prod --show-labels
```

**Captura #6:** namespaces `tienda-dev` y `tienda-prod` con labels `proyecto` y `ambiente`.

---

## Paso 6 - Tienda en desarrollo

Crea `tienda-desarrollo.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tienda-dev
  labels

    proyecto: tienda-online
    ambiente: desarrollo
---
apiVersion: v1
kind: Namespace
metadata:
  name: tienda-prod
  labels:
    proyecto: tienda-online
    ambiente: produccion
```

```bash
kubectl apply -f tienda-desarrollo.yaml
kubectl rollout status deployment/frontend -n tienda-dev --timeout=120s
kubectl rollout status deployment/database -n tienda-dev --timeout=180s
kubectl get all -n tienda-dev
```

**Captura #7:** Deployments `frontend` y `database` en `Running` en `tienda-dev`.

Acceso web desarrollo:

```bash
echo "http://$(minikube ip):30110"
minikube service frontend-service -n tienda-dev --url
curl -s "$(minikube service frontend-service -n tienda-dev --url)" | head -5
```

**Captura #8:** pagina nginx en navegador o salida de `curl` en el NodePort **30110**.

---

## Paso 7 - Tienda en produccion ···quede aca <--*****

Crea `tienda-produccion.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: tienda-prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
        tipo: web
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: tienda-prod
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
        tipo: db
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "supersecret789"
        - name: MYSQL_DATABASE
          value: "tienda_prod"
        ports:
        - containerPort: 3306
        resources:
          requests:
            memory: "512Mi"
          limits:
            memory: "1Gi"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
  namespace: tienda-prod
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    nodePort: 30210
  type: NodePort
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
  namespace: tienda-prod
spec:
  selector:
    app: database
  ports:
  - port: 3306
  type: ClusterIP
```

```bash
kubectl apply -f tienda-produccion.yaml
kubectl rollout status deployment/frontend -n tienda-prod --timeout=120s
kubectl rollout status deployment/database -n tienda-prod --timeout=180s
kubectl get all -n tienda-prod
kubectl get deployments frontend -n tienda-dev -o jsonpath='Dev replicas: {.spec.replicas}{"\n"}'
kubectl get deployments frontend -n tienda-prod -o jsonpath='Prod replicas: {.spec.replicas}{"\n"}'
```

**Captura #9:** prod con **3** pods frontend vs **1** en dev.

Acceso web produccion:

```bash
echo "http://$(minikube ip):30210"
curl -s "$(minikube service frontend-service -n tienda-prod --url)" | head -5
```

**Captura #10:** nginx accesible en NodePort **30210**.

---

## Paso 8 - Comparar ambientes

```bash
echo "=== DESARROLLO (tienda-dev) ==="
kubectl get pods,svc -n tienda-dev

echo "=== PRODUCCION (tienda-prod) ==="
kubectl get pods,svc -n tienda-prod
```

Script opcional de comparacion (guardar como `comparar-ambientes.sh` si quieres):

```bash
#!/bin/bash
echo "COMPARACION DE AMBIENTES"
echo "========================"

for env in tienda-dev tienda-prod; do
  echo ""
  echo "Ambiente: $env"
  echo "-------------------"
  echo "Pods:"
  kubectl get pods -n "$env" --no-headers | wc -l | xargs echo "  Total:"
  echo "Replicas frontend:"
  kubectl get deployment frontend -n "$env" -o jsonpath='{.spec.replicas}{"\n"}' | xargs echo "  "
  if [ "$env" = "tienda-dev" ]; then
    echo "  http://$(minikube ip):30110"
  else
    echo "  http://$(minikube ip):30210"
  fi
done
```

```bash
chmod +x comparar-ambientes.sh
./comparar-ambientes.sh
```

**Captura #11:** comparacion dev vs prod (replicas, pods, URLs).

---

## Paso 9 - Namespace personal (experimentar)

```bash
kubectl create namespace david-lab
kubectl run demo --image=nginx -n david-lab --port=80
kubectl get pods -n david-lab
kubectl describe namespace david-lab | head -20
kubectl delete namespace david-lab
```

**Captura #12 (opcional):** pod `demo` en tu namespace personal antes de `kubectl delete namespace`.

---

## Paso 10 - Ver recursos en todos los namespaces

```bash
kubectl get pods -A | grep -E 'tienda|mi-app|NAMESPACE'
kubectl get svc -A | grep NodePort
```

Refuerzo: mismos nombres (`frontend`, `database-service`) en NS distintos sin conflicto.

---

## Limpieza (opcional)

```bash
kubectl delete -f tienda-produccion.yaml --ignore-not-found
kubectl delete -f tienda-desarrollo.yaml --ignore-not-found
kubectl delete namespace tienda-dev tienda-prod --ignore-not-found
kubectl delete -f app-produccion.yaml --ignore-not-found
kubectl delete -f app-desarrollo.yaml --ignore-not-found
kubectl delete namespace mi-app-dev mi-app-prod --ignore-not-found
kubectl config set-context --current --namespace=default
```

---

## Resenas importantes (reforzar al cerrar el dia)

1. **Namespace = organizacion logica**; no separa nodos ni red por defecto.
2. **Mismo nombre de recurso en NS distintos** es valido (`web-app` en dev y prod).
3. **Especifica siempre `-n` o `metadata.namespace`** para no desplegar en `default` por error.
4. **`kubectl delete namespace` borra todo** lo namespaced dentro (Pods, Services, PVCs del NS).
5. **DNS entre namespaces:** `<service>.<namespace>.svc.cluster.local`.
6. **Contexto por defecto** (`set-context --namespace`) afecta comandos sin `-n`.
7. **NodePort distinto por ambiente** (30100/30200 mi-app; 30110/30210 tienda) evita colisiones.
8. **Entrevista:** RBAC y ResourceQuota se acotan por namespace; es el patron multi-tenant ligero en Kubernetes.

# Dia 32 - Ejecucion hands-on (ConfigMaps y Secrets)

## Objetivo

Crear ConfigMap y Secret, consumirlos como **variables de entorno** y como **archivos montados**, desplegar una app de ejemplo y comprobar actualizacion con **rollout restart**.

## Requisitos

- Cluster local (Minikube) y `kubectl` funcionando.

```bash
kubectl get nodes
```

**Captura #1:** salida de `kubectl get nodes` (cluster listo).

---

## Paso 1 - ConfigMap imperativo

```bash
kubectl create configmap app-config \
  --from-literal=database_url=mysql://db:3306/myapp \
  --from-literal=debug_mode=true \
  --from-literal=max_connections=100

kubectl get configmap app-config -o yaml
```

**Captura #2:** fragmento de `kubectl get configmap app-config` o del YAML mostrando las claves creadas.

---

## Paso 2 - ConfigMap desde archivo

```bash
printf '%s\n' 'log_level=info' 'cache_size=512MB' 'timeout=30s' > app.properties
kubectl create configmap app-config-file --from-file=app.properties
kubectl describe configmap app-config-file
```

**Captura #3:** salida de `describe` donde se vea el contenido de `app.properties`.

---

## Paso 3 - Secret imperativo (credenciales de ejemplo)

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=ejemplo-dev-no-prod

kubectl describe secret db-credentials
```

**Captura #4:** `kubectl describe secret db-credentials` (solo nombres de claves visibles, sin valores en claro en describe).

---

## Paso 4 - Declarativo: ConfigMap + Secret + Deployment

Crea `config-stack.yaml` con un stack coherente (nginx lee env y monta un archivo del ConfigMap y archivos del Secret):

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
data:
  environment: "development"
  log_level: "debug"
  default.conf: |
    server {
      listen 80;
      server_name localhost;
      location / {
        return 200 "ok from nginx with configmap volume\n";
        add_header Content-Type text/plain;
      }
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: webapp-secrets
type: Opaque
stringData:
  api_key: "demo-api-key-no-produccion"
  db_password: "demo-password-no-produccion"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
        - name: web
          image: nginx:latest
          ports:
            - containerPort: 80
          env:
            - name: ENVIRONMENT
              valueFrom:
                configMapKeyRef:
                  name: webapp-config
                  key: environment
            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: webapp-config
                  key: log_level
            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: webapp-secrets
                  key: api_key
          volumeMounts:
            - name: nginx-snippet
              mountPath: /etc/nginx/conf.d
              readOnly: true
            - name: secret-files
              mountPath: /etc/app-secrets
              readOnly: true
      volumes:
        - name: nginx-snippet
          configMap:
            name: webapp-config
            items:
              - key: default.conf
                path: default.conf
        - name: secret-files
          secret:
            secretName: webapp-secrets
            defaultMode: 0400
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: NodePort
  selector:
    app: webapp
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30200
```

Aplicar y verificar:

```bash
kubectl apply -f config-stack.yaml
kubectl get pods -l app=webapp
kubectl get svc webapp-service
```

**Captura #5:** `kubectl get pods` y `kubectl get svc` con `webapp` en `Running` y el Service con `NodePort`.

---

## Paso 5 - Verificar env y archivos dentro del Pod

```bash
POD=$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD" -- printenv | grep -E '^(ENVIRONMENT|LOG_LEVEL|API_KEY)='
kubectl exec -it "$POD" -- ls -la /etc/app-secrets
kubectl exec -it "$POD" -- cat /etc/nginx/conf.d/default.conf
```

**Captura #6:** salida de `printenv` mostrando `ENVIRONMENT` y `LOG_LEVEL` (puedes tapar o recortar `API_KEY` en la captura si la compartes).

---

## Paso 6 - Actualizar ConfigMap y reiniciar

```bash
kubectl patch configmap webapp-config --type merge -p '{"data":{"log_level":"info"}}'
kubectl rollout restart deployment/webapp
kubectl rollout status deployment/webapp
kubectl exec -it "$(kubectl get pods -l app=webapp -o jsonpath='{.items[0].metadata.name}')" -- printenv LOG_LEVEL
```

**Captura #7:** `printenv LOG_LEVEL` mostrando `info` tras el rollout.

---

## Paso 7 - Probar acceso externo (opcional)

```bash
minikube service webapp-service --url
```

Abre la URL en el navegador o `curl` la URL.

**Captura #8 (opcional):** respuesta HTTP del endpoint o pantalla del navegador.

---

## Limpieza (opcional)

```bash
kubectl delete -f config-stack.yaml --ignore-not-found
kubectl delete configmap app-config app-config-file --ignore-not-found
kubectl delete secret db-credentials --ignore-not-found
```

---

## Resenas importantes (reforzar al cerrar el dia)

1. **ConfigMap** para todo lo que pueda vivir en repo/plantillas; **Secret** solo para datos sensibles, y aun asi no subir valores reales a Git.
2. **Base64 no es seguridad:** quien pueda leer el objeto `Secret` obtiene el valor; por eso RBAC + encryption at rest + herramientas externas.
3. **Cambiar CM/Secret no siempre basta:** muchas apps leen env al inicio; tras cambios suele hacer falta **reinicio del Pod** (`rollout restart`).
4. **`envFrom` vs claves sueltas:** `envFrom` inyecta todas las claves como variables; puede chocar con nombres o exponer mas de lo deseado; combinar con criterio.
5. **Volumentes:** montar Secret con `readOnly: true` y `defaultMode` restrictivo reduce superficie de error en el contenedor.
6. **Produccion:** evaluar **Sealed Secrets**, **External Secrets Operator**, vaults y politicas de rotacion; el ejercicio local es didactico, no patron de seguridad final.

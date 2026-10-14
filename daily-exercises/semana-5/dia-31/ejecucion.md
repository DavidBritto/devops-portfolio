# Dia 31 - Ejecucion Hands-on (Services y Networking)

## Objetivo
Desplegar servicios internos y externos en Kubernetes, validar conectividad entre Pods y practicar debug de Services.

## Requisitos
- Minikube funcionando
- `kubectl` configurado contra el cluster local

Comprobacion inicial:

```bash
kubectl get nodes
kubectl get pods -A
```

---

## Paso 1 - Crear deployment base con replicas

```bash
kubectl create deployment web-app --image=nginx:latest --replicas=3
kubectl get pods -l app=web-app
```

**Captura #1 (progreso inicial):** tomar screenshot al resultado de `kubectl get pods -l app=web-app` mostrando las 3 replicas en `Running`.

---

## Paso 2 - Crear Service tipo ClusterIP (interno)

Crear `clusterip-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

Aplicar y verificar:

```bash
kubectl apply -f clusterip-service.yaml
kubectl get svc web-app-service
kubectl get endpoints web-app-service
```

**Captura #2 (service interno listo):** screenshot de `kubectl get svc web-app-service` y `kubectl get endpoints web-app-service`.

---

## Paso 3 - Crear Service tipo NodePort (acceso externo)

Crear `nodeport-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
  type: NodePort
```

Aplicar y abrir:

```bash
kubectl apply -f nodeport-service.yaml
kubectl get svc web-app-nodeport
minikube service web-app-nodeport --url
```

**Captura #3 (exposicion externa):** screenshot de la URL entregada por `minikube service web-app-nodeport --url`.

---

## Paso 4 - Desplegar escenario Frontend + Backend

Crear `backend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: httpd:2.4
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

Crear `frontend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: nginx:latest
          ports:
            - containerPort: 80
          env:
            - name: BACKEND_URL
              value: "http://backend-service"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30090
  type: NodePort
```

Aplicar y verificar:

```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
kubectl get pods
kubectl get svc
```

**Captura #4 (arquitectura completa):** screenshot de `kubectl get pods` y `kubectl get svc` donde se vean frontend y backend.

---

## Paso 5 - Probar DNS interno y conectividad entre servicios

```bash
kubectl run test-pod --image=busybox -it --rm --restart=Never -- sh
```

Dentro del Pod:

```sh
nslookup backend-service
wget -qO- http://backend-service
exit
```

**Captura #5 (evidencia de comunicacion interna):** screenshot dentro del `test-pod` mostrando `nslookup backend-service` exitoso.

---

## Paso 6 - Probar port-forward para testing local

```bash
kubectl port-forward service/backend-service 8080:80
```

Abrir en navegador:
- `http://localhost:8080`

**Captura #6 (testing local):** screenshot del navegador accediendo por `localhost:8080`.

---

## Paso 7 - Debug guiado si algo falla

Ejecutar checklist:

```bash
kubectl get svc
kubectl get endpoints backend-service
kubectl get pods --show-labels
kubectl describe svc backend-service
```

Si no hay endpoints:
- Revisar que labels de Pods coincidan con el `selector` del Service.
- Verificar que Pods esten `Running` y `Ready`.

**Captura #7 (solo si hubo error):** screenshot del comando que muestre la causa raiz (por ejemplo, `endpoints` vacio o labels incorrectos).

---

## Cierre del ejercicio

Checklist final:
- [x] Deployment con replicas funcionando
- [x] Service ClusterIP creado y con endpoints
- [x] Service NodePort accesible externamente
- [x] Frontend y backend desplegados
- [x] DNS interno validado desde Pod
- [x] Prueba con `port-forward` completada
- [x] Evidencias de captura guardadas

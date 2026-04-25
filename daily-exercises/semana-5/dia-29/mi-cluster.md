# Mi Primer Clúster con Kubernetes — Día 29

## 🚀 Cree mi Primer Clúster Local

```bash
minikube start
minikube status
```

## ✅ Verificando que todo funcione

```bash
kubectl version --client
kubectl cluster-info
kubectl get nodes
```

---

## 📦 Desplegar tu Primera App

### Ejemplo rápido: Hola Mundo con `kubectl run`

```bash
kubectl run hola-mundo --image=nginx --port=80
kubectl get pods
```

Esto crea un Pod llamado `hola-mundo` usando la imagen oficial de Nginx. Podés ver el pod corriendo con `kubectl get pods`.

> 📝 **Nota:** `kubectl run` es útil para pruebas rápidas, pero en producción se recomienda usar `kubectl create deployment`.

### Despliegue recomendado (Deployment + Service)

```bash
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080
kubectl get services hello-minikube
minikube service hello-minikube
```

---

## 📋 Comandos Básicos

```bash
kubectl get all
kubectl describe pod <nombre-pod>
kubectl logs <nombre-pod>
kubectl delete deployment <nombre-deployment>
kubectl <comando> --help
```

---

## 🧪 BONUS: Explorar el Dashboard

```bash
minikube dashboard
```

> 🎯 **Tip:** Explorá visualmente tus Pods, Deployments, Services y mucho más.

---

## 📝 Tareas del Día

- ✅ Instalar kubectl y minikube
- ✅ Iniciar tu primer clúster con `minikube start`
- ✅ Verificar que kubectl se conecta correctamente
- ✅ Desplegar y acceder a `hello-minikube`
- ✅ Abrir y explorar el minikube dashboard
- ✅ Tomar un screenshot de tu clúster funcionando

---

## 🆕 Mi Resumen del Día

### ¿Qué es un Pod, Node y Deployment? (en mis palabras)

- **Pod:** Es como una cajita donde vive mi contenedor. Puede tener uno o más contenedores adentro que comparten el mismo entorno.

- **Node:** Es la máquina donde Kubernetes corre esas cajitas. Con minikube es una sola máquina que hace todo.

- **Deployment:** Es decirle a Kubernetes cuántas cajitas quiero corriendo. Si una se rompe, él solo la vuelve a levantar.

### Comandos que usé hoy

```bash
minikube start
minikube status
minikube dashboard
kubectl version --client
kubectl cluster-info
kubectl get nodes
kubectl get pods
kubectl get all
kubectl run hola-mundo --image=nginx --port=80
kubectl create deployment hello-minikube --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment hello-minikube --type=NodePort --port=8080
kubectl get services hello-minikube
minikube service hello-minikube
```

### ¿Qué fue lo que más me sorprendió?

Lo que más me sorprendió fue lo fácil que es implementarlo para orquestar contenedores. La verdad esperaba algo más complejo — me pareció incluso más fácil que Terraform. Con pocos comandos ya tenía un clúster corriendo, una app desplegada y el dashboard funcionando.

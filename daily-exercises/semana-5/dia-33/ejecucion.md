# Dia 33 - Ejecucion hands-on (Volumenes y almacenamiento)

## Objetivo

Practicar **emptyDir**, **PV/PVC**, MySQL con disco persistente, comprobar que los datos sobreviven al borrar Pods y desplegar un stack web + base de datos.

Los manifiestos YAML **no estan en el repo**: los creas tu en este directorio siguiendo cada paso (contenido basado en `daily-exercises/teoria diaria/dia-33.md`).

## Requisitos

- Cluster local (Minikube) y `kubectl` funcionando.
- Directorio del dia: `daily-exercises/semana-5/dia-33/`

```bash
cd /home/david/git/devops-porfolio/daily-exercises/semana-5/dia-33
kubectl get nodes
```

**Captura #1:** salida de `kubectl get nodes` (cluster listo).

---

## Paso 1 - emptyDir compartido entre dos contenedores

Crea `emptydir-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-volume-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - while true; do
        echo "$(date): Escribiendo datos..." >> /shared/log.txt;
        sleep 10;
      done
    volumeMounts:
    - name: shared-data
      mountPath: /shared

  - name: reader
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - while true; do
        echo "Contenido del archivo:";
        cat /shared/log.txt 2>/dev/null || echo "Archivo no encontrado";
        sleep 15;
      done
    volumeMounts:
    - name: shared-data
      mountPath: /shared

  volumes:
  - name: shared-data
    emptyDir: {}
```

Aplicar y revisar logs:

```bash
kubectl apply -f emptydir-pod.yaml
kubectl get pod shared-volume-pod
kubectl logs shared-volume-pod -c writer --tail=5
kubectl logs shared-volume-pod -c reader --tail=10
```

Espera unos segundos si el reader aun muestra "Archivo no encontrado"; el writer crea `/shared/log.txt` en el volumen compartido.

**Captura #2:** logs del contenedor `reader` mostrando lineas con fecha escritas por `writer`.

---

## Paso 2 - PersistentVolume + PVC + Pod nginx

Crea `pv-pvc-stack.yaml` (PV, PVC y Pod en un solo archivo; aplicar en ese orden dentro del manifest):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /tmp/k8s-data
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: local-storage
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
spec:
  containers:
  - name: app
    image: nginx:latest
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: app-pvc
```
Aplicar y comprobar binding:

```bash
kubectl apply -f pv-pvc-stack.yaml
kubectl get pv
kubectl get pvc
kubectl get pod app-with-storage
kubectl describe pvc app-pvc | grep -E 'Status|Volume'
```

**Captura #3:** `kubectl get pv,pvc` con PV `Available`/`Bound` y PVC `Bound`.

Escribe un archivo de prueba en el volumen montado:

```bash
kubectl exec -it app-with-storage -- sh -c 'echo "persistencia dia 33" > /usr/share/nginx/html/index.html'
kubectl exec -it app-with-storage -- cat /usr/share/nginx/html/index.html
```

**Captura #4:** salida de `cat` mostrando el texto en el volumen persistente.

---

## Paso 3 - MySQL con almacenamiento persistente

Crea `mysql-storage.yaml`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mysql-storage
  hostPath:
    path: /tmp/mysql-data
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  storageClassName: mysql-storage
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: "rootpassword123"
  MYSQL_DATABASE: "myapp"
  MYSQL_USER: "appuser"
  MYSQL_PASSWORD: "userpassword123"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        envFrom:
        - secretRef:
            name: mysql-secret
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
```

Desplegar:

```bash
kubectl apply -f mysql-storage.yaml
kubectl get pv,pvc | grep mysql
kubectl rollout status deployment/mysql --timeout=180s
kubectl get pods -l app=mysql
```

**Captura #5:** Pod `mysql-*` en `Running` y PVC `mysql-pvc` en estado `Bound`.

---

## Paso 4 - Crear datos y probar persistencia

Obtener nombre del Pod:

```bash
MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "$MYSQL_POD"
```

Conectar y crear tabla de prueba (password: `rootpassword123`):

```bash
kubectl exec -it "$MYSQL_POD" -- mysql -uroot -prootpassword123 -e "
CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;
CREATE TABLE IF NOT EXISTS usuarios (id INT, nombre VARCHAR(50));
INSERT INTO usuarios VALUES (1, 'Juan'), (2, 'Maria');
SELECT * FROM usuarios;
"
```

**Captura #6:** salida del `SELECT` con las filas Juan y Maria.

Eliminar el Pod (el Deployment creara otro) y volver a consultar:

```bash
kubectl delete pod "$MYSQL_POD"
kubectl wait --for=condition=Ready pod -l app=mysql --timeout=180s
MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$MYSQL_POD" -- mysql -uroot -prootpassword123 -e "USE testdb; SELECT * FROM usuarios;"
```

**Captura #7:** mismo `SELECT` tras recrear el Pod (datos persisten en el PVC).

---

## Paso 5 - Monitorear uso de almacenamiento en el Pod

```bash
kubectl exec -it "$MYSQL_POD" -- df -h /var/lib/mysql
kubectl describe pvc mysql-pvc | grep -A5 "Used By"
```

**Captura #8:** salida de `df -h` en la ruta montada del volumen MySQL.

---

## Paso 6 - Aplicacion web + base de datos

Crea `webapp-with-db.yaml` (PV explicito para Minikube; la teoria del dia usa solo PVC, aqui anadimos PV con hostPath para que el claim haga bind):

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-app-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: mysql-app-storage
  hostPath:
    path: /tmp/mysql-app-data
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: mysql-app-storage
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql-app
  template:
    metadata:
      labels:
        app: mysql-app
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "rootpass123"
        - name: MYSQL_DATABASE
          value: "webapp"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-data
        persistentVolumeClaim:
          claimName: mysql-pvc-app
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-app-service
spec:
  selector:
    app: mysql-app
  ports:
  - port: 3306
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-with-db
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp-with-db
  template:
    metadata:
      labels:
        app: webapp-with-db
    spec:
      containers:
      - name: webapp
        image: httpd:2.4
        env:
        - name: DB_HOST
          value: "mysql-app-service"
        - name: DB_NAME
          value: "webapp"
        volumeMounts:
        - name: web-content
          mountPath: /usr/local/apache2/htdocs
      volumes:
      - name: web-content
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  selector:
    app: webapp-with-db
  ports:
  - port: 80
    nodePort: 30300
  type: NodePort
```

Desplegar y verificar:

```bash
kubectl apply -f webapp-with-db.yaml
kubectl get pv,pvc | grep mysql-app
kubectl rollout status deployment/mysql-app --timeout=180s
kubectl rollout status deployment/webapp-with-db --timeout=120s
kubectl get pods -l 'app in (mysql-app,webapp-with-db)'
kubectl get svc webapp-service
```

**Captura #9:** Deployments en `Ready` y Service `webapp-service` tipo `NodePort` (puerto 30300).

Acceso externo (Minikube):

```bash
minikube service webapp-service --url
curl -s "$(minikube service webapp-service --url)"
```

**Captura #10:** respuesta HTTP del Apache o pantalla del navegador en el NodePort.

---

## Paso 7 - Comparar emptyDir vs PVC (refuerzo rapido)

```bash
kubectl delete pod shared-volume-pod --ignore-not-found
kubectl apply -f emptydir-pod.yaml
kubectl logs shared-volume-pod -c reader --tail=5
```

Tras borrar el Pod, el log compartido en emptyDir **desaparece** (volumen efimero). Contrasta con el Paso 4 donde MySQL conservo filas en el PVC.

No hace falta captura obligatoria; anotalo en tus notas del dia.

---

## Limpieza (opcional)

```bash
kubectl delete -f webapp-with-db.yaml --ignore-not-found
kubectl delete -f mysql-storage.yaml --ignore-not-found
kubectl delete -f pv-pvc-stack.yaml --ignore-not-found
kubectl delete -f emptydir-pod.yaml --ignore-not-found
# PV con policy Retain pueden quedar; liberar manualmente si hace falta:
# kubectl delete pv local-pv mysql-pv mysql-app-pv --ignore-not-found
```

---

## Resenas importantes (reforzar al cerrar el dia)

1. **emptyDir** comparte datos entre contenedores del mismo Pod pero **no persiste** al eliminar el Pod.
2. **PV + PVC** separan provision del disco de la solicitud de la app; el Pod solo referencia el `claimName`.
3. **RWO** encaja con una replica de MySQL escribiendo en un disco; escalar escritura requiere otro diseno.
4. **PVC Pending** suele ser falta de PV compatible o StorageClass sin provisioner.
5. **hostPath** en los manifiestos es valido en Minikube/single-node; en produccion multi-nodo usar CSI/cloud y evitar hostPath.
6. **ReclaimPolicy Retain** deja datos al borrar el PVC; limpia PVs huerfanos para no acumular basura.
7. Tras cambios en volumenes de BD, valida persistencia con **delete pod** + consulta SQL, no solo `kubectl restart`.
8. **Backup:** `kubectl cp` sirve para pruebas; en produccion usa snapshots o Velero.

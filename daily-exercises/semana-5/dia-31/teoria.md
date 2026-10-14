# Dia 31 - Services y Networking en Kubernetes

## 1 Idea central
En Kubernetes, un `Service` es una abstraccion que da una IP estable y un nombre DNS a un grupo de Pods.
Resuelve tres problemas clave:

- Las IP de los Pods cambian al recrearse.
- Se necesita balancear trafico entre replicas.
- Hace falta un punto unico y estable de acceso.

## 2 Como fluye el trafico

- **Interno (dentro del cluster):** Pod -> DNS interno -> Service -> Pod backend.
- **Externo (desde fuera):** Cliente -> NodePort o LoadBalancer -> Service -> Pods.

El balanceo entre Pods lo realiza Kubernetes automaticamente cuando varios Pods cumplen el selector del Service.

## 3 Tipos de Service

### ClusterIP (default)
- Solo accesible dentro del cluster.
- Ideal para comunicacion entre microservicios (frontend -> backend, backend -> db).

### NodePort
- Expone el servicio en un puerto fijo del nodo (`30000-32767`).
- Permite acceso desde fuera del cluster usando `IP_DEL_NODO:nodePort`.

### LoadBalancer
- Crea un balanceador externo en cloud providers (AWS, GCP, Azure).
- En local suele requerir herramientas como MetalLB.

### ExternalName
- Mapea un nombre interno de Kubernetes a un DNS externo.
- Util para consumir APIs externas con nombre interno estandar.

### Headless Service (`clusterIP: None`)
- No asigna IP virtual propia.
- Expone endpoints directos de Pods.
- Muy usado con StatefulSets y bases distribuidas.

## 4 Selector, labels y endpoints
- Un Service usa `selector` para encontrar Pods por labels.
- Si no hay coincidencia, el Service queda sin endpoints.
- Revisiones basicas de debug:
  - `kubectl get svc`
  - `kubectl get endpoints <service-name>`
  - `kubectl get pods --show-labels`
  - `kubectl describe svc <service-name>`

## 5 DNS interno en Kubernetes
Kubernetes crea DNS interno automaticamente.

Formatos comunes:
- `service-name` (mismo namespace)
- `service-name.namespace.svc.cluster.local` (FQDN completo)

Prueba tipica desde un Pod de debug:
- `nslookup backend-service`
- `wget -qO- http://backend-service`

## 6 Seguridad y buenas practicas
- Nombrar servicios de forma consistente (`<app>-service`, `<app>-nodeport`).
- No exponer como NodePort/LoadBalancer lo que deba quedar interno.
- Limitar puertos y usar `NetworkPolicy` para restringir trafico.
- Documentar puertos, dependencias y tipo de exposicion de cada servicio.

## 7 Port-forward para pruebas
Permite acceder localmente a un Service sin exponerlo externamente:

- `kubectl port-forward service/backend-service 8080:80`
- Luego probar en `http://localhost:8080`

## 8 Conceptos clave para entrevista laboral

1. **Diferencia entre Service y Pod**
   - Pod es efimero (IP cambiante), Service da acceso estable y balanceado.

2. **ClusterIP vs NodePort vs LoadBalancer**
   - ClusterIP: solo interno.
   - NodePort: expone en puertos del nodo.
   - LoadBalancer: expone con LB administrado en cloud.

3. **Por que un Service puede no tener endpoints**
   - Labels de Pods no coinciden con el selector.
   - Pods no estan `Running/Ready`.

4. **Para que sirve Headless Service**
   - Descubrimiento directo de Pods, util en cargas stateful.

5. **Como restringir que solo frontend hable con backend**
   - Con `NetworkPolicy` permitiendo ingress solo desde Pods con label `app: frontend`.

## 9) Resumen del dia
Hoy se trabajo la base de networking en Kubernetes: exponer apps, conectar servicios internos, entender DNS interno, debuggear endpoints y aplicar criterios de seguridad para una arquitectura productiva.

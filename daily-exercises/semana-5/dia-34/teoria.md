# Dia 34 - Namespaces (organizacion del cluster)

## 1) Objetivo del dia

Organizar el cluster con **Namespaces**: aislamiento logico, separar ambientes (dev/prod), evitar conflictos de nombres y dominar `-n`, `-A` y el namespace por defecto del contexto.

## 2) Que es un Namespace

- Carpeta logica dentro del cluster (no es un cluster aparte ni un nodo dedicado).
- Recursos con el **mismo nombre** pueden coexistir en namespaces distintos (`web-app` en `dev` y en `prod`).
- Comparten nodos y red del cluster; **no** aislamento de red por defecto (para eso: NetworkPolicy).

Analogia: carpetas en un disco compartido -- mismos nombres de archivo en rutas distintas, pero el hardware es comun.

## 3) Comparativa (entrevista)

| Caracteristica                   |     Con Namespace    |   Solo `default` |
|----------------------------------|----------------------|------------------|
| Aislamiento logico               | Si                   |   No             |
| RBAC por ambito                  | Si (por NS)          |Limitado          |
| Cuotas (`ResourceQuota`)         | Si                   |No                |
| Nombres duplicados entre equipos | Si (en NS distintos) | No               |
| Uso tipico | Multi-equipo, multi-app, ambientes         | Labs simples     |

## 4) Namespaces del sistema (memorizar)

| Namespace |                           Uso                                        |
|-----------|----------------------------------------------------------------------|
| `default` |         Recursos si no especificas `namespace`                       |
| `kube-system` |       Componentes del plano de control y addons                  |
| `kube-public` |     Recursos legibles globalmente (poco uso directo)             |
| `kube-node-lease` | Heartbeats de nodos (Kubernetes 1.17+)                       |

**Entrevista:** nunca borres `kube-system` en un cluster real; elimina componentes criticos del control plane.

## 5) Crear namespaces

**Imperativo:**

```bash
kubectl create namespace mi-app-dev
```

**Declarativo (recomendado en GitOps):**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mi-app-dev
  labels:
    ambiente: desarrollo
    proyecto: mi-aplicacion
```

## 6) Desplegar recursos en un namespace

Tres formas equivalentes:

1. `metadata.namespace` en cada recurso del YAML.
2. `kubectl apply -f archivo.yaml -n mi-ns`
3. Cambiar contexto: `kubectl config set-context --current --namespace=mi-ns`

**Entrevista:** un Service `frontend-service` en `tienda-dev` se resuelve por DNS como:

`frontend-service.tienda-dev.svc.cluster.local`

## 7) Comandos clave

```bash
kubectl get namespaces          # kubectl get ns
kubectl get ns --show-labels
kubectl get pods -n mi-app-dev
kubectl get all -n mi-app-dev
kubectl get pods -A             # todos los namespaces
kubectl describe namespace mi-app-dev
kubectl config set-context --current --namespace=mi-app-dev
kubectl config view --minify | grep namespace
kubectl delete namespace mi-app-dev   # elimina TODO el contenido
```

## 8) Buenas practicas

- Nombres consistentes: `<proyecto>-<ambiente>` (`tienda-dev`, `tienda-prod`).
- No mezclar dev y prod en el mismo namespace.
- Labels en Namespace y en recursos (`ambiente`, `proyecto`, `equipo`).
- RBAC + `ResourceQuota` + `LimitRange` por equipo o ambiente.
- Automatizar creacion de namespaces en CI/CD.
- NodePort distinto por ambiente si expones varias apps en el mismo cluster local.

## 9) Errores comunes

- Olvidar `namespace` en YAML (todo cae en `default`).
- Deployment en un NS y Service en otro (selector sin endpoints).
- `kubectl delete namespace` sin confirmar (borrado en cascada de Pods, Services, PVCs del NS).
- Confundir namespace con cluster separado o con aislamiento de red automatico.
- Usar el mismo `nodePort` en dos Services del mismo cluster (colision).

## 10) Preguntas tipicas de entrevista

1. **Namespace vs cluster vs node:** el NS agrupa recursos en un cluster; los nodos ejecutan Pods de todos los NS.
2. **Dos Deployments `web-app`:** valido si estan en namespaces distintos.
3. **Listar pods de todo el cluster:** `kubectl get pods -A`.
4. **Namespace por defecto en kubeconfig:** `kubectl config set-context --current --namespace=<ns>`.
5. **Comunicacion entre NS:** DNS FQDN del Service (`<svc>.<ns>.svc.cluster.local`).
6. **Que elimina `kubectl delete ns`:** todos los recursos namespaced dentro de ese NS.
7. **Namespace vs NetworkPolicy vs RBAC:** organizacion logica vs filtro de red vs permisos de API.
8. **ResourceQuota vs LimitRange:** cuota total del NS vs limites por defecto por Pod/contenedor.

## 11) Diagrama mental

```
Cluster
├── Namespace: dev     -> web-app (1 replica), Services
├── Namespace: prod    -> web-app (3 replicas), Services
└── Namespace: kube-system -> kube-proxy, CoreDNS, etc.
```

## 12) Comandos utiles (resumen)

```bash
kubectl get ns
kubectl create namespace mi-nuevo-proyecto
kubectl get pods -n mi-namespace
kubectl get all -A
kubectl describe namespace mi-namespace
kubectl config set-context --current --namespace=default
```

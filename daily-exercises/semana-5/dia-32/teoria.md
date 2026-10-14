# Dia 32 - ConfigMaps y Secrets (configuracion segura)

## 1) Objetivo del dia

Separar **configuracion no sensible** del codigo (ConfigMap) y aislar **credenciales** (Secret), consumiendolas en Pods por variables de entorno y por archivos montados.

## 2) Por que no hardcodear

- Cambia por ambiente (dev, staging, prod).
- Riesgo de filtrar credenciales en imagenes o repos.
- Kubernetes permite inyectar config en runtime sin reconstruir la imagen (salvo que la app cachee valores al arranque).

## 3) ConfigMap vs Secret

### 3.1 ConfigMap (configuracion no sensible)

- **Que guarda:** parametros de app, URLs publicas, flags, fragmentos de config (`.properties`, `application.yaml`, etc.).
- **Donde vive:** recurso de API; en etcd se almacena en **texto plano**.
- **Limite:** 1 MiB por recurso.
- **Como lo consume el Pod:** variables de entorno, `envFrom`, volumen montado, o `kubectl` en debug.

### 3.2 Secret (datos sensibles)

- **Que guarda:** passwords, tokens, API keys, certificados TLS, credenciales de registry.
- **Donde vive:** recurso de API; en etcd los valores van en **base64** (codificacion, **no** cifrado).
- **Limite:** 1 MiB por recurso.
- **Como lo consume el Pod:** mismos mecanismos que ConfigMap (`env`, `envFrom`, volumen).

### 3.3 Comparacion rapida

| Criterio | ConfigMap | Secret |
|----------|-----------|--------|
| Proposito | Config de aplicacion | Credenciales y material sensible |
| Sensibilidad | No debe llevar secretos | Solo datos que no deben filtrarse |
| Formato en etcd | Texto plano | Base64 en el campo `data` |
| Tamano maximo | 1 MiB | 1 MiB |
| Inyeccion en Pod | `configMapKeyRef`, volumen `configMap` | `secretKeyRef`, volumen `secret` |

### 3.4 Errores comunes al elegir uno u otro

- Meter passwords o tokens en un **ConfigMap** (quedan en texto plano y son mas faciles de exponer).
- Creer que base64 en Secret **cifra** los datos (solo cambia la representacion).
- Asumir que `kubectl describe secret` oculta el valor para siempre (quien tenga RBAC puede leer el recurso completo).

### 3.5 Seguridad real (mas alla de Secret)

- **RBAC:** permisos minimos sobre recursos `secret`.
- **Encryption at rest:** cifrado de etcd en clusters productivos.
- **Git y CI:** no commitear Secrets reales; usar **Sealed Secrets**, **External Secrets Operator**, vault o plantillas sin valores.

## 4) Flujo mental

Admin/CI crea ConfigMap y Secret -> API de Kubernetes los guarda -> el Pod los referencia (`configMapKeyRef`, `secretKeyRef`, volumenes) -> la aplicacion lee env o archivos.

## 5) ConfigMap

- Formato clave-valor; puede incluir bloques multilinea (por ejemplo un `.properties` o un fragmento de config).
- Errores frecuentes: meter secretos en ConfigMap, nombres poco claros, no documentar claves.

**Creacion:** imperativo (`kubectl create configmap ... --from-literal` / `--from-file`) o declarativo (`kubectl apply -f configmap.yaml`).

## 6) Secret

- Tipos comunes: **Opaque** (generico), **kubernetes.io/tls**, **kubernetes.io/dockerconfigjson** (pull de registry privado).
- En YAML suele usarse `data` (base64) o `stringData` (texto plano en el manifest; el apiserver lo codifica).

**Entrevista:** por que `describe secret` no muestra valores por defecto: reduce filtrado accidental; aun asi quien tenga RBAC puede leer el recurso.

## 7) Uso en Pods

1. **Variable suelta:** `valueFrom.configMapKeyRef` / `secretKeyRef`.
2. **Todo el mapa como env:** `envFrom` con `configMapRef` y/o `secretRef` (cuidado: nombres de claves = nombres de variables).
3. **Archivos:** volumen `configMap` o `secret` + `volumeMounts`; `items` para montar solo una clave con nombre de archivo; `defaultMode` (por ejemplo `0400`) en Secret montado.

## 8) Actualizar configuracion

- `kubectl apply -f ...` o `kubectl edit configmap ...`
- Muchas apps **no recargan** env o archivos solas: suele hacer falta **`kubectl rollout restart deployment/<nombre>`** tras cambiar CM/Secret.
- `kubectl diff -f archivo.yaml` ayuda a revisar antes de aplicar.

## 9) Buenas practicas y seguridad

- No commitear Secrets reales; usar plantillas, Sealed Secrets, vaults, o ESO.
- RBAC minimo sobre recursos `secret`.
- Rotacion y auditoria; no loguear variables sensibles.
- Encryption at rest en etcd en clusters serios.

## 10) Preguntas tipicas de entrevista

1. **Diferencia ConfigMap vs Secret:** proposito y tratamiento en etcd; Secret sigue siendo legible con permisos.
2. **Por que mi Pod no ve el ConfigMap nuevo:** falta reinicio/rollout o la app no relee archivos.
3. **Base64 es cifrado:** no; es encoding.
4. **Montar solo una clave de un Secret:** volumen `secret` con `items`.
5. **Como evitar Secret en Git:** Sealed Secrets, External Secrets, SOPS, vault + inyeccion en CI.

## 11) Comandos utiles (recordatorio)

```bash
kubectl get configmaps
kubectl describe configmap <name>
kubectl get secrets
kubectl describe secret <name>
kubectl get secret <name> -o jsonpath='{.data.<key>}' | base64 -d
kubectl exec -it <pod> -- printenv | grep <PREFIX>
```

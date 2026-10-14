# Dia 33 - Volumenes y almacenamiento (datos que perduran)

## 1) Objetivo del dia

Persistir datos en Kubernetes: compartir archivos entre contenedores, reclamar almacenamiento con **PV/PVC** y validar que los datos sobreviven al reinicio o recreacion de Pods.

## 2) Por que hacen falta volumenes

- Los contenedores son **efimeros**: al reiniciar el Pod se pierde el filesystem del contenedor.
- Bases de datos y apps stateful necesitan disco que **sobreviva** al ciclo de vida del Pod.
- Los volumenes permiten compartir datos entre contenedores del mismo Pod o enlazar almacenamiento externo/nodos.

## 3) Comparativa de tipos de volumen

| Tipo | Persistencia | Multi-Pod | Uso comun |
|------|--------------|-----------|-----------|
| `emptyDir` | No (vive con el Pod) | Si (mismo Pod) | Cache, temp, logs compartidos |
| `hostPath` | Si (en el nodo) | No | Solo dev/pruebas locales |
| `configMap` / `secret` | No (config) | Si | Config y credenciales como archivos |
| `nfs` / CIFS | Si | Si (RWX) | Compartir entre Pods |
| Cloud (EBS, PD, Azure Disk) | Si | RWO tipico | Produccion |
| **PV / PVC** | Si | Depende del backend | Patron estandar de persistencia |

## 4) Flujo PV / PVC / Pod

```
Admin o provisioner -> PersistentVolume (PV)
Usuario / manifest   -> PersistentVolumeClaim (PVC) reclama capacidad
Pod                  -> volume persistentVolumeClaim -> monta en mountPath
```

- **PV:** recurso de almacenamiento en el cluster (como una "casa disponible").
- **PVC:** solicitud del usuario (tamano, `accessModes`, `storageClassName`).
- El scheduler enlaza PVC con un PV compatible; el Pod referencia el PVC por nombre.

## 5) Modos de acceso (`accessModes`)

| Modo                      | Significado                                    |
|---------------------------|------------------------------------------------|
| **ReadWriteOnce (RWO)**   | Un solo nodo puede montar en lectura-escritura |
| **ReadOnlyMany (ROX)**    | Varios nodos en solo lectura |
| **ReadWriteMany (RWX)**   | Varios nodos leen y escriben (requiere NFS, etc.) |

**Entrevista:** por que un PVC de MySQL suele ser **RWO** y una replica: una sola instancia escribe en el disco; escalar escritura requiere otro patron (operador, sharding, RWX con cuidado).

## 6) Volumenes basicos

### 6.1 emptyDir

- Directorio vacio creado al asignar el Pod al nodo; se borra al eliminar el Pod.
- Util para scratch, cache o **compartir archivos entre contenedores** del mismo Pod.

### 6.2 hostPath

- Monta una ruta del **filesystem del nodo**.
- El Pod debe ejecutarse en ese nodo; **no usar en produccion** multi-nodo (riesgo de seguridad y acoplamiento).

### 6.3 configMap / secret como volumen

- Montan claves como archivos (complemento al dia 32); no son almacenamiento de datos de aplicacion.

## 7) PersistentVolume y PersistentVolumeClaim

Ejemplo local (Minikube / single-node):

```yaml
# PV: capacidad, accessModes, reclaimPolicy, storageClassName, hostPath
# PVC: requests.storage, accessModes, storageClassName (debe coincidir)
# Pod: volumes[].persistentVolumeClaim.claimName
```

**Politicas de reclamacion (`persistentVolumeReclaimPolicy`):**

- **Retain:** al borrar el PVC, el PV y los datos en el backend pueden quedar para recuperacion manual.
- **Delete:** el provisioner elimina el volumen asociado (comun en cloud con aprovisionamiento dinamico).

**Entrevista:** PVC en **Pending** -- no hay PV que cumpla tamano, `accessMode` o `storageClass`; o falta provisioner dinamico para esa StorageClass.

## 8) StorageClass y aprovisionamiento dinamico

- **StorageClass** define como se crean PVs automaticamente al crear un PVC.
- Campos utiles: `provisioner`, `volumeBindingMode` (`WaitForFirstConsumer` retrasa el binding hasta saber en que nodo ira el Pod), `allowVolumeExpansion`.
- En local sin cloud suele usarse PV estatico + `hostPath` o `no-provisioner`.

## 9) StatefulSet y RWX (avanzado)

- **StatefulSet** + PVC por replica (`volumeClaimTemplates`) para identidad estable y disco por Pod.
- **RWX** solo con backends compatibles (NFS, GlusterFS, algunos CSI); no asumir RWX en EBS estandar.

## 10) Backup y operacion

- Copia manual: `kubectl cp <pod>:/ruta /backup/local`
- Produccion: **Velero**, snapshots del proveedor, o jobs de backup sobre el volumen.
- Monitoreo basico: `kubectl exec ... -- df -h` dentro del contenedor.

## 11) Buenas practicas y errores comunes

**Buenas practicas**

- StorageClass y aprovisionamiento dinamico en entornos reales.
- PV dedicados para BD; backups y politica de retencion documentada.
- No usar `hostPath` en clusters productivos compartidos.

**Errores comunes**

- Usar `emptyDir` esperando persistencia tras borrar el Pod.
- PVs **Retain** sin limpiar (volumenes huerfanos).
- PVC y PV con `storageClassName` distintos.
- Olvidar que `hostPath` ata el Pod al nodo.

## 12) Preguntas tipicas de entrevista

1. **Diferencia emptyDir vs PVC:** emptyDir muere con el Pod; PVC enlaza almacenamiento persistente.
2. **PV vs PVC:** quien provisiona el disco vs quien lo solicita/consume.
3. **RWO vs RWX:** cuantos nodos pueden montar y en que modo.
4. **PVC Pending:** sin PV compatible o sin provisioner.
5. **Datos no persisten tras reinicio:** comprobar que el Pod usa `persistentVolumeClaim`, no `emptyDir`.
6. **Expandir un PVC:** solo si `allowVolumeExpansion: true` en la StorageClass y el CSI lo soporta.
7. **hostPath en produccion:** evitar; riesgo de acceso al host y falta de portabilidad entre nodos.

## 13) Comandos utiles

```bash
kubectl get pv
kubectl get pvc
kubectl describe pvc <name>
kubectl get storageclass
kubectl exec -it <pod> -- df -h
kubectl delete pod <name>   # probar persistencia con Deployment/StatefulSet
```

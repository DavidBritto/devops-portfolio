🚀 Día 11: Redes y Volúmenes - Conectando el Mundo Docker
Hoy abordamos dos de los conceptos más importantes para construir aplicaciones reales con Docker: cómo hacer que los contenedores se comuniquen entre sí (Redes) y cómo asegurar que los datos no se pierdan (Volúmenes).

🧠 Conceptos Clave
Redes en Docker: Por defecto, Docker aísla los contenedores. Para que puedan comunicarse, deben estar en la misma red. Docker tiene un servidor DNS interno que permite a los contenedores encontrarse usando su nombre de servicio.

Persistencia de Datos: Los contenedores son efímeros. Si eliminas un contenedor, sus datos se van con él. Para guardar datos importantes (como una base de datos), necesitamos almacenarlos fuera del contenedor.

Volúmenes vs. Bind Mounts:

Volúmenes: Son la forma recomendada por Docker. Docker gestiona el almacenamiento en una parte específica del disco del host. Son más portables y fáciles de gestionar.

Bind Mounts: Mapean un directorio de tu máquina local directamente a un directorio dentro del contenedor. Son excelentes para desarrollo, ya que puedes editar código en tu host y ver los cambios reflejados instantáneamente en el contenedor.

🛠️ Tareas Prácticas Realizadas
Creación y Uso de Redes Personalizadas:

Se creó una red de tipo bridge (la más común para un solo host) con docker network create miapp-net.

Se lanzaron dos contenedores (api y db) conectados a esa misma red.

Se verificó la conectividad desde el contenedor api haciendo ping db. El ping funcionó gracias al DNS interno de Docker, que resolvió el nombre db a la IP interna del otro contenedor.

Gestión de Volúmenes para Persistencia:

Se creó un volumen gestionado por Docker con docker volume create vol-db.

Se lanzó un contenedor montando este volumen en una ruta específica con la bandera -v vol-db:/datos.

Se verificó que los datos escritos en /datos dentro del contenedor persistían incluso después de eliminar (docker rm) y volver a crear el contenedor, siempre y cuando se montara el mismo volumen.

Desafío Adicional (MongoDB + Mongo Express):

Se aplicaron ambos conceptos para levantar una pila funcional.

Se creó una red miapp-net.

Se lanzó un contenedor mongo en esa red.

Se lanzó un contenedor mongo-express (una interfaz web para MongoDB) en la misma red.

Se configuró mongo-express usando una variable de entorno para que se conectara a MongoDB usando su nombre de servicio: -e ME_CONFIG_MONGODB_SERVER=mongo.

Resultado: Se pudo acceder a la interfaz de Mongo Express en http://localhost:8081 y gestionar la base de datos que corría en otro contenedor, demostrando una comunicación exitosa a través de la red de Docker.

Este día fue esencial para entender cómo construir arquitecturas de microservicios, donde los componentes aislados (contenedores) necesitan hablar entre sí y guardar información de forma permanente.
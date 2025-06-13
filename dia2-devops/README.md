##Este readme fue puramente escrito en nano y subido a este repo con git desde wsl2

#Tarea Opcional del Día 2

##🛠️ 1. Exploración básica
- Abrí la terminal y ejecutá estos comandos. Luego anotá qué hace cada uno:

*whoami*   *Muestra el nombre de Usuario*
*pwd*   *Me muestra la ruta donde estoy*
*ls -lah* *Muestra todos los archivos legibles*
*df -hT*  *Se usa para revisar el espacio libre y usado en los discos o sistemas de archivos*
*uptime*  *muestra un resumen rápido del estado y la carga del Sistema*

##📂 2. Navega por los directorios clave del sistema:

cd /   *Se va al Root Directory*
ls    *hace una lista de archivos del directorio donde esta* 
cd /etc && ls *Se va al directorio etc y hace una lista*
cd /home && ls *SE fue a home y muestra el usuario*

##🧠 5. Reto de comprensión
¿Qué hace este comando?:

chmod u=rwx,g=rx,o= hola.txt

Explicalo con tus palabras:
**R** *el comando establece que para el archivo hola.txt: El propietario tiene control total (leer, escribir, ejecutar).El grupo puede leerlo y ejecutarlo. Todos los demás no tienen ningún tipo de acceso.*

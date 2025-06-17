Día 3: Automatizando mi Entorno de Laboratorio con Vagrant
Hoy el desafío se centró en Vagrant, una herramienta increíble para crear y gestionar entornos de desarrollo portátiles y reproducibles. La idea es simple: en lugar de instalar todo directamente en mi máquina, defino una máquina virtual (VM) en un archivo de texto, y Vagrant se encarga de crearla, configurarla y destruirla por mí.

¡Perfecto para probar cosas sin miedo a romper mi sistema!

⚙️ Instalación en mi equipo con Ubuntu
El proceso de instalación fue bastante directo en mi sistema Ubuntu.

Instalar VirtualBox (El Hipervisor) VirtualBox es el software que realmente corre la máquina virtual. Vagrant solo le da las órdenes.
Bash

sudo apt update && sudo apt install virtualbox -y
Instalar Vagrant Esta es la herramienta que orquesta todo.
Bash

sudo apt install vagrant -y
Verificar la Instalación Para asegurarme de que todo se instaló correctamente, ejecuté:
Bash

vagrant --version
Y me mostró una versión reciente, confirmando que la instalación fue un éxito.
🏗️ Creando mi primer Vagrantfile
El corazón de Vagrant es el Vagrantfile. Es un archivo de configuración escrito en Ruby donde defino todas las características de mi máquina virtual: qué sistema operativo usar, qué red configurar y qué software instalar.

Creé un archivo llamado Vagrantfile con este contenido inicial para probar:

Ruby

# Vagrantfile

Vagrant.configure("2") do |config|
  # 1. Box: La imagen base. Usé una de Ubuntu 22.04 LTS.
  config.vm.box = "ubuntu/jammy64"
  
  # 2. Network: Configuré una red privada para acceder a la VM desde mi PC.
  config.vm.network "private_network", ip: "192.168.33.10"
  
  # 3. Provisioning: Los comandos que se ejecutan automáticamente al crear la VM.
  # Aquí instalé Nginx y creé un archivo de prueba.
  config.vm.provision "shell", inline: <<-SHELL
    echo "¡Hola desde el provisionamiento!" > /tmp/hola.txt
    apt update && apt install -y nginx
    systemctl start nginx
  SHELL
end
🚀 Poniendo en marcha la VM
Con el Vagrantfile listo en mi carpeta, levantar la máquina fue tan simple como ejecutar:

Bash

vagrant up
Este comando leyó mi Vagrantfile, descargó la imagen de Ubuntu (la primera vez), creó la VM en VirtualBox y ejecutó los comandos de provisionamiento.

Para conectarme a la máquina por SSH, usé:

Bash

vagrant ssh
Una vez dentro, verifiqué que el provisionamiento había funcionado:

Bash

cat /tmp/hola.txt
Y efectivamente, me mostró el mensaje: ¡Hola desde el provisionamiento!.

📚 Mi Desafío del Día: Servidor Nginx Personalizado
La tarea principal de hoy era aplicar lo aprendido para crear un entorno específico:

Una VM con Nginx instalado.
Un archivo en /var/www/html/index.html con mi nombre.
Que fuera accesible desde el navegador de mi PC en la dirección http://192.168.33.10.
Mi Solución: El Vagrantfile Final
Modifiqué el Vagrantfile para cumplir con los requisitos del desafío. La clave estuvo en el bloque de provision:

Ruby

# Vagrantfile final para el desafío del Día 3

Vagrant.configure("2") do |config|
  # Usar la imagen de Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"

  # Asignar una IP privada para acceder desde mi navegador
  config.vm.network "private_network", ip: "192.168.33.10"

  # Provisionamiento con Shell para instalar Nginx y crear mi página personalizada
  config.vm.provision "shell", inline: <<-SHELL
    apt update && apt install -y nginx
    echo "<h1>Hola, soy David Britto</h1>" > /var/www/html/index.html
  SHELL
end
Verificando el resultado
Ejecuté vagrant destroy para eliminar la máquina anterior y luego vagrant up para crear la nueva con la configuración final.

Después de que terminó, abrí mi navegador y fui a la dirección http://192.168.33.10, ¡y ahí estaba mi página personalizada! Desafío completado.

Hoy fue un día genial. Vagrant es una herramienta poderosa que me permite tener laboratorios limpios para cada prueba. La capacidad de definir toda una máquina en un simple archivo de texto y levantarla en minutos con vagrant up es algo que usaré muchísimo.
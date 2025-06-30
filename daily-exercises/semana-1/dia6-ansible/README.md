# 🚀 Día 6: Introducción a Ansible y Automatización con Roles

Este documento resume las tareas y aprendizajes del Día 6 del desafío #90DaysOfDevOps. El objetivo principal fue comprender los fundamentos de Ansible y evolucionar de un playbook simple a una estructura profesional basada en roles para automatizar la configuración de un servidor.

---

## 🧠 Conceptos Clave Aprendidos

-   **Infraestructura como Código (IaC):** La práctica de gestionar y aprovisionar la infraestructura a través de código, en lugar de procesos manuales.
-   **Ansible - Agente-less:** Ansible no requiere la instalación de ningún software (agente) en los servidores que gestiona. Se comunica directamente a través de SSH, lo que simplifica enormemente su despliegue.
-   **Idempotencia:** Una de las características más potentes de Ansible. Si una tarea ya se ha realizado (por ejemplo, un paquete ya está instalado), Ansible no volverá a ejecutarla. Solo aplica los cambios necesarios.
-   **Componentes de Ansible:**
    -   **Inventario:** Lista de servidores (nodos) a gestionar.
    -   **Playbooks:** Archivos YAML que definen una serie de tareas a ejecutar. Son las "recetas" de nuestra automatización.
    -   **Módulos:** Unidades de trabajo que realizan acciones específicas (ej: `apt` para instalar paquetes, `copy` para copiar archivos).
    -   **Roles:** La forma profesional de organizar los playbooks en componentes reusables y especializados.

---

## 🏗️ Parte 1: Primer Contacto - Despliegue Simple (Freelancer)

El primer ejercicio consistió en levantar una máquina virtual con Vagrant y usar un único playbook de Ansible para instalar Nginx y desplegar una página web estática.

### Estructura del Proyecto Simple:
```
freelancer-deploy/
├── Vagrantfile
├── playbook.yml
└── files/
└── nginx.conf
```
## 🎯 Parte 2: Desafío Principal - Estructura Profesional con Roles
El verdadero desafío del día fue refactorizar la lógica anterior en una estructura profesional, modular y reutilizable utilizando Roles de Ansible.

**Objetivo:** Crear un playbook que automatice:

La instalación de Nginx con una página personalizada.
La creación de un usuario devops con privilegios sudo.
La configuración de un firewall básico con ufw.
Estructura Profesional del Proyecto
```
tarea-practica/
├── Vagrantfile
├── desplegar_app.yml
├── roles/
│   ├── nginx/
│   │   ├── files/
│   │   │   └── index.html
│   │   └── tasks/
│   │       └── main.yml
│   ├── devops_user/
│   │   └── tasks/
│   │       └── main.yml
│   └── firewall/
│       └── tasks/
│           └── main.yml
└── README.md
```

## ⚙️ Cómo Ejecutar el Proyecto Final
**Prerrequisitos:** Asegúrate de tener Vagrant, Ansible y VirtualBox instalados.
**Iniciar:** Clona el repositorio, navega a la carpeta del proyecto (tarea-practica) 
**ejecuta:** vagrant up

## Verificar:
**Página Web:** Abre tu navegador y visita http://192.168.33.11.
**Usuario:** Desde la terminal, ejecuta vagrant ssh -c "id devops".
**Firewall:** Desde la terminal, ejecuta vagrant ssh -c "sudo ufw status".

## ✅ Conclusión y Aprendizajes
Este día fue fundamental para pasar de simples scripts a una automatización estructurada. La principal lección es el poder de los Roles de Ansible para crear código modular, fácil de leer, reutilizable y mantenible, lo cual es esencial en cualquier entorno de DevOps profesional.


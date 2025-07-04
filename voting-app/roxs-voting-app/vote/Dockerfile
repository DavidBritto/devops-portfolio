# Paso 1: Usar una imagen base oficial de Python
FROM python:3.10-slim

# Paso 2: Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Paso 3: Copiar el archivo de dependencias y las instala
# Esto se hace primero para aprovechar el caché de Docker.
# Si requirements.txt no cambia, Docker no volverá a instalar las dependencias.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Paso 4: Copiar el resto del código de la aplicación
COPY . .

# Paso 5: Comando para ejecutar la aplicación cuando el contenedor inicie
CMD ["python3", "app.py"]

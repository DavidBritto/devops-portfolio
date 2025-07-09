# Paso 1: Usar una imagen base oficial de Node.js
FROM node:20-alpine

# Paso 2: Establecer el directorio de trabajo
WORKDIR /app

# Paso 3: Copiar el package.json y package-lock.json e instalar dependencias
COPY package*.json ./
RUN npm install

# Paso 4: Copiar el resto del código
COPY . .

# Paso 5: Comando para ejecutar la aplicación
CMD ["node", "main.js"]
FROM node:18-alpine
WORKDIR /app
COPY package.json .
# RUN npm install # Lo omitimos porque no hay dependencias
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

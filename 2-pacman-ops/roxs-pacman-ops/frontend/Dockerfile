
FROM node:22-alpine AS builder

LABEL maintainer="RoxsRoss DevOps Challenge" \
      version="1.0.0" \
      description="Pacman DevOps Challenge Frontend" \
      challenge="90DaysWithRoxs"

WORKDIR /app

COPY package.json package-lock.json* ./

RUN npm ci --only=production

COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

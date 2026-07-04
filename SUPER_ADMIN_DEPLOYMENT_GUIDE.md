# HyperLocal Enterprise Web Portal — Deployment Manual
**Version:** 2.0

---

## 1. Production Deployment Strategy

The portal is packaged as a **production-ready multi-stage Docker build** and served through a lightweight, high-performance **Nginx** server container.

---

## 2. Multi-Stage Dockerfile Layout

```dockerfile
# Stage 1: Build React Application
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
# Custom configuration to handle client-side routing
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
    location /api { \
        proxy_pass http://api-gateway:8080; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 3. Docker Compose Orchestration

The portal service integrates with the existing stack within the bridge network:

```yaml
  enterprise-portal:
    build:
      context: ./enterprise-portal
      dockerfile: Dockerfile
    container_name: hyperlocal-enterprise-portal
    ports:
      - "4000:80"   # Exposed publicly on port 4000
    networks:
      - hyperlocal-network
    depends_on:
      api-gateway:
        condition: service_healthy
```

---

## 4. Operational Maintenance

### 4.1 Log Management
Nginx logs are routed to stdout/stderr and collected by Loki:
```bash
docker-compose logs -f enterprise-portal
```

### 4.2 Local Dev Launch
```bash
cd enterprise-portal
npm install
npm run dev
# Starts local development server on http://localhost:4000
```

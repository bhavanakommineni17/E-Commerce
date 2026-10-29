# Stage 1: Build React static assets with Vite
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies using cache layers
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Stage 2: Production Nginx Server
FROM nginx:alpine

# Copy compiled assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy customized Nginx reverse proxy configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose container port
EXPOSE 80

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

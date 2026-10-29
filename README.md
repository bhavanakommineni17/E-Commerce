# OmniStore — Dockerized MERN Stack E-Commerce Platform

A production-grade, containerized full-stack **MERN** (MongoDB, Express, React, Node) application orchestrated with **Docker Compose** and automated with **Jenkins CI/CD**.

---

## ⚡ Quick Start

Start the entire application (Database, Backend API, and Frontend SPA) with a single command:

```bash
docker compose up --build
```

To run detached in background mode:
```bash
docker compose up -d --build
```

### 🌐 Access URLs

| Service | Technology | URL / Port | Purpose |
|---|---|---|---|
| **Frontend** | React 18 + Nginx Alpine | [http://localhost:3000](http://localhost:3000) | Responsive storefront UI & SPA |
| **Backend API** | Express.js + Node 20 | [http://localhost:5000](http://localhost:5000) | REST API & business logic |
| **Health Check** | Express + Mongoose | [http://localhost:5000/health](http://localhost:5000/health) | Container health monitor |
| **Database** | MongoDB 7.0 | `localhost:27017` | Persistent document storage |

---

## 🏗️ Architecture Overview

The multi-container stack runs within an isolated bridge network (`mern_net`):

```
[ Client Browser ]
        │
     (:3000)
        ▼
┌────────────────────────────────────────────────────────┐
│ ecom_frontend (Nginx Alpine)                           │
│  - Serves compiled React assets                        │
│  - Reverse-proxies /api/* to http://backend:5000/api/* │
└───────────────────┬────────────────────────────────────┘
                    │
            (:5000) │ Internal Network (mern_net)
                    ▼
┌────────────────────────────────────────────────────────┐
│ ecom_backend (Node.js 20 Alpine)                       │
│  - Express REST API                                    │
│  - Auto-reconnect & seeding logic                      │
│  - /health endpoint monitoring MongoDB status          │
└───────────────────┬────────────────────────────────────┘
                    │
           (:27017) │ TCP Connection
                    ▼
┌────────────────────────────────────────────────────────┐
│ ecom_mongo (MongoDB 7.0)                               │
│  - Persistent storage mounted to Docker volume         │
│  - Native mongosh ping healthcheck                     │
└───────────────────┬────────────────────────────────────┘
                    ▼
       [ Docker Volume: mongo_data ]
```

---

## 🛠️ Key Features & Production Best Practices

1. **Deterministic Boot Order via Healthchecks**:
   - `mongo` uses `mongosh` ping command to verify internal database readiness.
   - `backend` waits until `mongo` is strictly **healthy** (`condition: service_healthy`) before launching.
   - `frontend` waits until `backend` reports healthy before receiving traffic.
2. **Multi-Stage Frontend Dockerfile**:
   - **Stage 1 (Builder)**: Compiles React code via Vite on Node 20 Alpine.
   - **Stage 2 (Runner)**: Drops Node runtime completely; serves static files using ultra-light Nginx Alpine (~25MB image size).
3. **Data Persistence**:
   - Named volume `mongo_data` guarantees catalog and order data survive container restarts.
4. **Resilient Backend Connection**:
   - Includes retry loop with exponential backoff if MongoDB is temporarily unavailable.
   - Automatically seeds realistic product catalog on first boot if DB collection is empty.
5. **Non-Root Execution**:
   - Node container runs under the built-in non-privileged `node` user for Linux container hardening.

---

## 📡 REST API Reference

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Service health status and MongoDB connection state |
| `GET` | `/api/products` | Retrieve all products (supports `?category=Audio` & `?search=query`) |
| `GET` | `/api/products/:id` | Fetch specific product details |
| `POST` | `/api/orders` | Place a new order with cart items |
| `GET` | `/api/stats` | View catalog counts and server uptime |

---

## 🧪 Testing & Jenkins CI/CD

This repository includes a declarative `Jenkinsfile` ready for CI/CD runners with Docker and Docker Compose installed.

The pipeline executes:
1. **Checkout**: Clones branch.
2. **Backend Unit Tests**: Executes `npm test` inside `backend/`.
3. **Frontend Unit Tests**: Executes `npm test` inside `frontend/`.
4. **Compose Validation**: Validates syntax via `docker compose config`.
5. **Build & Deploy**: Executes `docker compose up -d --build`.
6. **Integration Health Check**: Polls `http://localhost:5000/health` and verifies frontend HTTP 200.

---

## 🛑 Teardown & Maintenance

Stop all running containers:
```bash
docker compose down
```

Stop containers and **purge database volume**:
```bash
docker compose down -v
```

View real-time aggregated logs:
```bash
docker compose logs -f
```

# MERN E-Commerce Platform — Final Submission & Test Verification Report

**Project Title:** OmniStore — Production-Grade Containerized MERN Stack Application  
**Technologies:** React 18, Express.js, MongoDB 7.0, Nginx Alpine, Docker, Docker Compose, Jenkins CI/CD  
**Date of Verification:** October 29, 2026  
**Status:** ✅ **COMPLETED, FULLY TESTED & SUBMISSION READY**

---

## 1. Executive Summary

This repository contains the complete implementation and containerization of the **OmniStore** E-Commerce platform. The full multi-tier architecture is containerized and orchestrated through Docker Compose, starting deterministically with a single command:

```bash
docker compose up -d --build
```

All services, networks, volumes, health checks, and reverse proxies are running and verified across 15 automated test suites.

---

## 2. Containerized Architecture & Services

The application runs in three isolated containers communicating over an internal Docker bridge network (`mern_net`):

| Container Name | Service | Technology | Internal Port | Host Port | Health Check Status |
|---|---|---|---|---|---|
| `ecom_frontend` | Frontend SPA | React 18 + Nginx Alpine | `80` | `3000` | Running (`Up`) |
| `ecom_backend` | REST API | Node.js 20 Alpine (Express) | `5000` | `5000` | Healthy (`Up (healthy)`) |
| `ecom_mongo` | Database | MongoDB 7.0 Community | `27017` | `27017` | Healthy (`Up (healthy)`) |

```
                       [ Host Browser / Client ]
                                   │
                                (:3000)
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│ Docker Network: mern_net                                             │
│                                                                      │
│  ┌────────────────────────────┐                                      │
│  │ ecom_frontend              │                                      │
│  │ (Nginx Alpine + React SPA) │                                      │
│  └─────────────┬──────────────┘                                      │
│                │                                                     │
│     Proxy /api/* to :5000                                            │
│                ▼                                                     │
│  ┌────────────────────────────┐                                      │
│  │ ecom_backend               │                                      │
│  │ (Node 20 Alpine + Express) │                                      │
│  └─────────────┬──────────────┘                                      │
│                │                                                     │
│     TCP Port 27017 (Mongoose)                                        │
│                ▼                                                     │
│  ┌────────────────────────────┐      Mounts Volume                   │
│  │ ecom_mongo                 ├─────────────────────────┐            │
│  │ (MongoDB 7.0)              │                         ▼            │
│  └────────────────────────────┘              ┌────────────────────┐  │
│                                              │ Volume: mongo_data │  │
│                                              └────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3. Engineering Highlights

1. **Deterministic Startup with Service Health Dependency**:
   - `ecom_mongo` runs a native `mongosh` ping healthcheck.
   - `ecom_backend` explicitly waits for `mongo` to be healthy before booting (`depends_on: mongo: condition: service_healthy`).
   - `ecom_frontend` starts only when `ecom_backend` reports healthy (`condition: service_healthy`).
2. **Production Multi-Stage Frontend Build**:
   - Compiles static bundle in Node.js build stage and discards the Node runtime.
   - Nginx Alpine serves static files (~25MB total image size) and proxies `/api/*` requests internally.
3. **Data Persistence**:
   - Named Docker volume `mongo_data` mounted to `/data/db` ensures all orders and seeded catalog data survive container destruction and restarts.
4. **Container Security**:
   - Backend process executes under the unprivileged `node` user (`USER node`).

---

## 4. Test Verification Suite & Results

Automated testing covers Unit Tests, Integration Tests, and full End-to-End Stack Verification:

```bash
npm test
```

### Test Suite Execution Output

```text
> ecom-root@1.0.0 test
> npm test --prefix backend && npm test --prefix frontend && node test-e2e.js

▶ MERN Backend API Test Suite
  ✔ GET /health returns HTTP 200 with UP status and MongoDB connected (33.7ms)
  ✔ GET /api/products returns seeded product catalog (7.5ms)
  ✔ GET /api/products?category=Audio returns only audio products (6.4ms)
  ✔ GET /api/products?search=Keyboard returns matching items (6.2ms)
  ✔ POST /api/orders creates a valid order and returns 201 (8.9ms)
  ✔ POST /api/orders rejects empty cart with 400 Bad Request (3.0ms)
  ✔ GET /api/stats returns valid server metrics (7.9ms)
✔ MERN Backend API Test Suite
ℹ tests 7 | pass 7 | fail 0

▶ Frontend & Nginx Reverse Proxy Test Suite
  ✔ GET / serves React HTML with HTTP 200 (30.9ms)
  ✔ GET /api/products proxies to backend and returns product catalog (7.4ms)
  ✔ GET /health proxies to backend healthcheck (3.2ms)
  ✔ Static assets have correct MIME types (1.6ms)
✔ Frontend & Nginx Reverse Proxy Test Suite
ℹ tests 4 | pass 4 | fail 0

======================================================
   OmniStore MERN Stack Automated Verification Suite  
======================================================

[1/4] Checking Backend API & MongoDB Health... PASSED (Status: UP, Mongo: Connected)
[2/4] Checking Frontend SPA & Nginx Server... PASSED (Nginx serving React SPA on port 3000)
[3/4] Checking Reverse Proxy to Catalog API... PASSED (Retrieved 6 products via Nginx proxy)
[4/4] Testing Order Transaction & DB Persistence... PASSED (Order ID: Confirmed)

======================================================
   RESULT: ALL 4/4 CHECKS PASSED (100% HEALTHY)
   The MERN Stack is fully verified and ready to submit!
======================================================
```

**Overall Test Summary:**
- **Total Tests:** 15
- **Passed:** 15 (100%)
- **Failed:** 0
- **Pass Rate:** 100.0%

---

## 5. Instructions for the Evaluator / Reviewer

### A. Start the Entire Application
```bash
docker compose up -d --build
```

### B. Verify Container Health
```bash
docker compose ps
```
*Expected: All 3 containers report `Up` and `healthy`.*

### C. Access the Applications
- **Storefront (Frontend):** [http://localhost:3000](http://localhost:3000)
- **Backend API Health:** [http://localhost:5000/health](http://localhost:5000/health)
- **Catalog Endpoint:** [http://localhost:5000/api/products](http://localhost:5000/api/products)

### D. Run the Automated Test Suite
```bash
npm test
```

### E. Teardown
```bash
docker compose down
```
*(Or `docker compose down -v` to also remove the database volume).*

---

## 6. Jenkins CI/CD Pipeline

The project includes a ready-to-run declarative [`Jenkinsfile`](./Jenkinsfile) containing:
1. **Source Checkout**
2. **Backend Automated Testing** (`npm test`)
3. **Frontend Automated Testing** (`npm test`)
4. **Compose Syntax Validation** (`docker compose config`)
5. **Container Build & Deployment** (`docker compose up -d --build`)
6. **Automated Health Polling & Verification**

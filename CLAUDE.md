# CLAUDE.md - Infrastructure Service

This file provides service-specific guidance to Claude Code when working with the MVP Store Infrastructure.

## Project Overview

**MVP Store Infrastructure** provides the foundational services for the microservices architecture, including the API Gateway (Nginx), Redis cache, and RabbitMQ message queue. This is the backbone that enables fault-tolerant communication between all services.

**Role in Architecture**: Central infrastructure layer providing API Gateway, shared caching, message queuing, and service discovery.

**Related Services**:
- Backend: `mvp-store-backend/` - Connects through API Gateway
- Payment Service: `mvp-store-payment-service/` - Connects through API Gateway
- Frontend: `mvp-store-frontend/` - Served through API Gateway

For complete system architecture, see [Root CLAUDE.md](../CLAUDE.md).

## Components

### API Gateway (Nginx)
- **Purpose**: Single entry point for all external traffic
- **Port**: 8090 (HTTP), 8443 (HTTPS)
- **Features**:
  - Load balancing
  - Request routing
  - SSL termination
  - Health check proxy
  - Retry logic

### Redis Cache
- **Purpose**: Shared caching layer for all services
- **Port**: 6380 (external), 6379 (internal)
- **Auth**: Password `mvp_secret`
- **Features**:
  - Session storage
  - Data caching
  - Rate limiting support

### RabbitMQ Message Queue
- **Purpose**: Async communication between services
- **Ports**: 5680 (AMQP), 15680 (Management UI)
- **Auth**: `mvp_user` / `mvp_secret`
- **Management UI**: http://localhost:15680
- **Features**:
  - Message queuing
  - Reliable delivery
  - Dead letter queues

## Network Architecture

### Docker Network
- **Name**: `mvp_store_network`
- **Type**: Bridge network
- **Purpose**: Enable inter-service communication
- **Services Connected**: All MVP Store services

### Service Discovery
Services can reach each other using container names:
```
api-gateway     → http://mvp-store-gateway
backend         → http://mvp-store-backend:8080
payment         → http://mvp-store-payment:8080
redis           → redis://mvp-store-redis:6379
rabbitmq        → amqp://mvp-store-rabbitmq:5672
```

## API Gateway Configuration

### Routing Rules

**Frontend (Static & SSR):**
```nginx
location / {
    proxy_pass http://mvp-store-frontend:3000;
}
```

**Backend API:**
```nginx
location /api/ {
    proxy_pass http://mvp-store-backend:8080/;
}
```

**Payment API:**
```nginx
location /api/payment/ {
    proxy_pass http://mvp-store-payment:8080/api/;
}
```

**Health Checks:**
```nginx
location /health {
    # Gateway health endpoint
}
```

### Load Balancing
Configure in `nginx/upstream.conf`:
```nginx
upstream backend_servers {
    least_conn;  # Load balancing method
    server mvp-store-backend:8080 max_fails=3 fail_timeout=30s;
    # Add more backend instances for scaling
}
```

### Retry Logic
```nginx
proxy_next_upstream error timeout http_502 http_503 http_504;
proxy_next_upstream_tries 3;
proxy_next_upstream_timeout 10s;
```

## Development Workflow

### Starting Development (Recommended Order)

1. **Initialize Infrastructure:**
   ```bash
   cd mvp-store-infrastructure
   make init
   ```

2. **Start Backend Services:**
   ```bash
   cd ../mvp-store-backend
   make up

   cd ../mvp-store-payment-service
   make up
   ```

3. **Start Frontend:**
   ```bash
   cd ../mvp-store-frontend
   make up  # or npm run dev for local development
   ```

4. **Verify System:**
   ```bash
   # Check API Gateway
   curl http://localhost:8090/health

   # Check Backend
   curl http://localhost:8090/api/health

   # Check Frontend
   curl http://localhost:8090/
   ```

### Stopping Development

```bash
# Stop individual services first
cd mvp-store-frontend && make down
cd ../mvp-store-backend && make down
cd ../mvp-store-payment-service && make down

# Stop infrastructure last
cd ../mvp-store-infrastructure && make down
```

## Redis Configuration

### Connection from Services

```bash
# Environment variables for services
REDIS_HOST=mvp-store-redis
REDIS_PORT=6379
REDIS_PASSWORD=mvp_secret
```

### Testing Redis Connection

```bash
# From host
redis-cli -h localhost -p 6380 -a mvp_secret ping

# From container
docker exec -it mvp-store-redis redis-cli -a mvp_secret ping
```

### Common Redis Operations

```bash
# Access Redis CLI
docker exec -it mvp-store-redis redis-cli -a mvp_secret

# Check keys
KEYS *

# Monitor commands
MONITOR

# Get info
INFO
```

## RabbitMQ Configuration

### Management Interface
Access at: http://localhost:15680
- Username: `mvp_user`
- Password: `mvp_secret`

### Connection from Services

```bash
# Environment variables
RABBITMQ_HOST=mvp-store-rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=mvp_user
RABBITMQ_PASSWORD=mvp_secret
RABBITMQ_VHOST=/
```

### Monitoring Queues

1. Open http://localhost:15680
2. Navigate to "Queues" tab
3. Monitor message rates, consumers, and queue lengths

## Health Monitoring

### Health Check Endpoints

```bash
# API Gateway health
curl http://localhost:8090/health

# Backend health (via gateway)
curl http://localhost:8090/api/health

# Payment service health (via gateway)
curl http://localhost:8090/api/payment/health

# Direct service access (for debugging)
curl http://localhost:8191/health  # Backend direct
curl http://localhost:8192/api/health  # Payment direct
```

### Service Status Monitoring

```bash
# Check all containers
docker ps --filter "name=mvp-store"

# Check specific service
docker ps --filter "name=mvp-store-gateway"

# View resource usage
docker stats mvp-store-gateway mvp-store-redis mvp-store-rabbitmq
```

## Security Considerations

1. **Credentials**: Change default passwords in production
2. **Network Isolation**: Keep internal services on private network
3. **SSL/TLS**: Enable HTTPS for API Gateway in production
4. **Rate Limiting**: Configure Nginx rate limiting
5. **Firewall**: Only expose necessary ports (8090, 8443)

## Claude Code Guidelines

When working on infrastructure:
1. **Test Configuration Changes** - Always validate Nginx config before restarting
2. **Backup Data** - Use `make clean` carefully as it deletes all data
3. **Network First** - Ensure shared network exists before starting services
4. **Monitor Logs** - Check logs when debugging connectivity issues
5. **Health Checks** - Verify all services are healthy after changes
6. **Documentation** - Update this file when adding new services or routes
7. **Security** - Never commit credentials to version control
8. **Port Management** - Document any port changes in this file
9. **Graceful Shutdown** - Stop services in reverse order (services → infrastructure)
10. **Version Control** - Keep configuration files in sync across environments
# Docker Troubleshooting Guide

## Common Docker Build Issues and Solutions

### 1. Python Package Installation Issues

#### Issue: pip install fails during Docker build
```
RUN pip install --no-cache-dir -r requirements.txt
Collecting fastapi==0.104.1 (from -r requirements.txt (line 2))
Downloading fastapi-0.104.1-py3-none-any.whl.metadata (24 kB)
...
```

#### Solutions:

**A. Update pip and setuptools first:**
```dockerfile
RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt
```

**B. Install system dependencies for Python packages:**
```dockerfile
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        default-libmysqlclient-dev \
        pkg-config \
        python3-dev \
        build-essential \
    && rm -rf /var/lib/apt/lists/*
```

**C. Use specific Python version:**
```dockerfile
FROM python:3.11-slim
```

**D. Install packages individually if bulk install fails:**
```dockerfile
RUN pip install fastapi==0.104.1
RUN pip install uvicorn[standard]==0.24.0
RUN pip install python-multipart==0.0.6
RUN pip install sqlalchemy==2.0.23
RUN pip install alembic==1.12.1
```

### 2. Memory Issues

#### Issue: Docker build runs out of memory

#### Solutions:

**A. Increase Docker memory limit:**
- Docker Desktop: Settings > Resources > Memory (increase to 4GB+)

**B. Use multi-stage builds:**
```dockerfile
# Build stage
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
```

### 3. Network Issues

#### Issue: Cannot download packages

#### Solutions:

**A. Use different package index:**
```dockerfile
RUN pip install --no-cache-dir -i https://pypi.org/simple/ -r requirements.txt
```

**B. Configure DNS:**
```dockerfile
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

### 4. Permission Issues

#### Issue: Permission denied errors

#### Solutions:

**A. Run as non-root user:**
```dockerfile
RUN adduser --disabled-password --gecos '' appuser
USER appuser
```

**B. Fix file permissions:**
```dockerfile
RUN chmod +x /app/entrypoint.sh
```

### 5. Build Context Issues

#### Issue: Build context too large

#### Solutions:

**A. Use .dockerignore:**
```
node_modules/
.git/
*.log
.env
__pycache__/
*.pyc
.pytest_cache/
```

**B. Multi-stage builds to reduce final image size**

### 6. Specific Package Issues

#### Issue: mysqlclient installation fails

#### Solutions:

**A. Use PyMySQL instead:**
```
# In requirements.txt, replace:
# mysqlclient==2.1.1
# with:
PyMySQL==1.1.0
```

**B. Install MySQL development headers:**
```dockerfile
RUN apt-get update && apt-get install -y \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config
```

#### Issue: Cryptography package fails

#### Solutions:

**A. Install Rust compiler:**
```dockerfile
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    cargo
```

**B. Use pre-compiled wheels:**
```dockerfile
RUN pip install --only-binary=cryptography cryptography
```

### 7. Docker Compose Issues

#### Issue: Services fail to start

#### Solutions:

**A. Check service dependencies:**
```yaml
services:
  backend:
    depends_on:
      - mysql
      - redis
```

**B. Add health checks:**
```yaml
services:
  mysql:
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
```

**C. Use wait scripts:**
```dockerfile
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /wait
RUN chmod +x /wait
CMD /wait && python app/main.py
```

### 8. Environment-Specific Issues

#### Issue: Different behavior on different OS

#### Solutions:

**A. Use consistent base images:**
```dockerfile
FROM python:3.11-slim-bullseye
```

**B. Pin all package versions:**
```
fastapi==0.104.1
uvicorn==0.24.0
# etc.
```

### 9. Debugging Docker Builds

#### Useful commands:

**A. Build with verbose output:**
```bash
docker build --progress=plain --no-cache .
```

**B. Inspect intermediate layers:**
```bash
docker run -it <intermediate-image-id> /bin/bash
```

**C. Check logs:**
```bash
docker logs <container-id>
```

**D. Build specific service:**
```bash
docker-compose build backend
```

### 10. Quick Fixes

#### A. Clear Docker cache:
```bash
docker system prune -a
docker builder prune
```

#### B. Restart Docker daemon:
```bash
# On Windows/Mac: Restart Docker Desktop
# On Linux:
sudo systemctl restart docker
```

#### C. Check Docker version compatibility:
```bash
docker --version
docker-compose --version
```

## Build Scripts

### Windows (build.bat):
```batch
@echo off
echo Building Docker containers...
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo Build complete!
```

### PowerShell (build.ps1):
```powershell
Write-Host "Building Docker containers..." -ForegroundColor Green
docker-compose down
docker-compose build --no-cache
docker-compose up -d
Write-Host "Build complete!" -ForegroundColor Green
```

### Linux/Mac (build.sh):
```bash
#!/bin/bash
echo "Building Docker containers..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d
echo "Build complete!"
```

## Monitoring and Logs

### View logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Monitor resource usage:
```bash
docker stats
```

### Check container health:
```bash
docker-compose ps

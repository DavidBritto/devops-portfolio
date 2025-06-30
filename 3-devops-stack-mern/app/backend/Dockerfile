FROM python:3.13-alpine AS builder

LABEL org.opencontainers.image.title="roxs-devops-project" \
    org.opencontainers.image.description="A fullstack DevOps project using Python and Uvicorn" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.authors="roxsross" \
    org.opencontainers.image.licenses="MIT"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    && rm -rf /var/cache/apk/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --user -r /tmp/requirements.txt

# Etapa final
FROM python:3.13-alpine AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/home/appuser/.local/bin:$PATH" \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apk add --no-cache \
    postgresql-client \
    && rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /root/.local /home/appuser/.local

COPY --chown=appuser:appgroup . /app/

USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:3000/health')" || exit 1

EXPOSE 3000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000", "--workers", "1"]
FROM python:3.13-alpine

# --- LÍNEA AÑADIDA AQUÍ ---
# Instalamos la herramienta 'curl' para que el healthcheck funcione
RUN apk add --no-cache curl
# --------------------------

WORKDIR /app
COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt
COPY ./ /app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "3000"]

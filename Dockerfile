# FROM python:3.14.7-alpine3.24
# ENV PYTHONUNBUFFERED=1
# ENV TERM=screen-256color
# ENV PYTHONPATH=/app/src
# ENV DJANGO_SETTINGS_MODULE=config.settings
# ENV BASE_DIR=/app/src
# EXPOSE 8000
# WORKDIR /app
# ENTRYPOINT ["/app/entrypoint.sh"]
# CMD ["granian", "--access-log", "--host", "0.0.0.0", "--port", "8000", "--interface", "wsgi", "config.wsgi:application"]
# RUN mkdir -p /app/var/log
# RUN apk upgrade \
#   && apk add --no-cache postgresql-dev gcc musl-dev curl bash
# # Project dep management
# # Ditch pipenv when uv swap is complete
# RUN pip install -U --no-cache-dir pipenv==2024.3.1
# ARG UV_VERSION=0.7.19
# RUN curl -LO "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-musl.tar.gz"
# RUN tar -xzf uv-x86_64-unknown-linux-musl.tar.gz
# RUN mv uv-x86_64-unknown-linux-musl/uv /usr/local/bin/
# RUN chmod +x /usr/local/bin/uv
# COPY entrypoint.sh /app/entrypoint.sh
# syntax=docker/dockerfile:1
ARG PYTHON_IMAGE=python:3.14.7-alpine3.24

# ---------- builder ----------
FROM ${PYTHON_IMAGE} AS builder
COPY --from=ghcr.io/astral-sh/uv:0.12.21 /uv /usr/local/bin/uv

RUN apk add --no-cache gcc musl-dev postgresql-dev

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/venv

WORKDIR /app

# ---------- runtime ----------
FROM ${PYTHON_IMAGE} as base

RUN apk add --no-cache libpq bash

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:${PATH}" \
    PYTHONPATH=/app/src \
    DJANGO_SETTINGS_MODULE=config.settings \
    BASE_DIR=/app/src

WORKDIR /app
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh
RUN mkdir -p /app/var/log
EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["granian", "--access-log", "--host", "0.0.0.0", "--port", "8000", "--interface", "wsgi", "config.wsgi:application"]

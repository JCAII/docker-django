FROM python:3.11.9-alpine3.20
ENV PYTHONBUFFERED 1
ENV TERM screen-256color
ENV PYTHONPATH=/app/src
ENV DJANGO_SETTINGS_MODULE=config.settings
ENV BASE_DIR=/app/src
EXPOSE 8000
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gunicorn", "--access-logfile", "-", "--forwarded-allow-ips", "*", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
RUN mkdir -p /app/var/log
RUN apk add --no-cache postgresql-client==13.12 gcc musl-dev python3-dev py-pip bash
RUN pip install -U --no-cache-dir pip \
    && pip install -U --no-cache-dir pipenv==2024.3.1
ADD entrypoint.sh /app/entrypoint.sh

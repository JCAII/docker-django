FROM python:3.9.1-buster
ENV PYTHONBUFFERED 1
ENV TERM screen-256color
ENV PYTHONPATH=/app/src
ENV DJANGO_SETTINGS_MODULE=config.settings
ENV BASE_DIR=/app/src
ENV PIPENV_VENV_IN_PROJECT=1
EXPOSE 8000
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["gunicorn", "--access-logfile", "-", "--forwarded-allow-ips", "*", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
RUN mkdir -p /app/var/log
RUN \
  echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' \
    > /etc/apt/sources.list.d/postgresql.list \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - \
  && apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client-12 \
  && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir pipenv
ADD entrypoint.sh /app/entrypoint.sh

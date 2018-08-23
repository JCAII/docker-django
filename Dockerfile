FROM python:3.6.6-stretch
ENV PYTHONBUFFERED 1
ENV TERM screen-256color
ENV PYTHONPATH=/app/src
ENV DJANGO_SETTINGS_MODULE=config.settings.production
ENV BASE_DIR=/app/src
ENV PIPENV_VENV_IN_PROJECT=1
EXPOSE 8000
WORKDIR /app
CMD ["gunicorn", "--access-logfile", "-", "--bind", "0.0.0.0:8000", "config.wsgi:application"]
RUN pip install --no-cache-dir pipenv
ADD entrypoint.sh entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
RUN \
  echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' \
    > /etc/apt/sources.list.d/postgresql.list \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - \
  && apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client-9.5 \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /app/var/log

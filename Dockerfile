FROM python:3.12-slim

WORKDIR /app
RUN useradd -m appuser

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8080
USER appuser

CMD ["gunicorn", "-b", "0.0.0.0:8080", "app.main:create_app()"]

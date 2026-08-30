FROM python:3.11-slim

WORKDIR /app

# Install dependencies before copying the rest of the app so this layer
# stays cached across code-only changes (only re-runs when requirements change).
COPY app/requirements.txt app/requirements.txt
RUN pip install --no-cache-dir -r app/requirements.txt

COPY . .

RUN useradd --create-home --shell /bin/bash appuser
USER appuser

CMD ["python", "app/app.py"]

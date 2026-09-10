FROM python:3.13-slim

WORKDIR /app

ARG PIP_INDEX_URL=""
ARG PIP_TRUSTED_HOST=""

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd -m -u 1000 hosted_agent
USER hosted_agent

EXPOSE 8088

COPY . .

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8088/readiness')"

CMD ["python", "basic_agent.py"]

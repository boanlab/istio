FROM python:3.9-slim

WORKDIR /app

COPY client.py .
COPY run_client.sh .

RUN chmod +x run_client.sh

CMD ["/app/run_client.sh"]

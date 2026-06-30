FROM python:3.11-slim
WORKDIR /app
RUN pip install flask
COPY app/app.py .
ENTRYPOINT ["python", "app.py"]
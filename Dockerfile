# Use a more recent stable Python version if possible (e.g., 3.9, 3.10, 3.11)
FROM python:3.7-slim-buster

EXPOSE 8080 # Changed to 8080

RUN apt-get update && apt-get install -y \
    build-essential \
    software-properties-common \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .

RUN pip3 install -r requirements.txt

COPY . .

# Using 'sh -c' to ensure the $PORT environment variable is evaluated by the shell
ENTRYPOINT ["sh", "-c", "streamlit run app.py --server.port $PORT --server.address 0.0.0.0"]
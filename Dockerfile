
FROM ubuntu:22.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# Use different mirror and retry logic
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing || apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 python3-pip git zip unzip openjdk-8-jdk wget \
    build-essential libssl-dev libffi-dev python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install buildozer
RUN pip3 install buildozer cython

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Create working directory
WORKDIR /app

# Copy project files
COPY . .

# Build APK
CMD ["buildozer", "android", "debug"]

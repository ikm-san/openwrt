OpenWrt Docker Image
This repository provides a Dockerfile to build and run OpenWrt in a Docker container.

Prerequisites
Docker
QEMU
Build and Run OpenWrt in Docker

Step 1: Create a Dockerfile
Create a file named Dockerfile with the following content:

```
FROM ubuntu:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    qemu-utils \
    qemu-system-x86 \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Add the script
COPY extract_and_convert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/extract_and_convert.sh

# Run the script
RUN /usr/local/bin/extract_and_convert.sh

# Set the default command
CMD ["qemu-system-x86_64", "-hda", "/openwrt.vhdx", "-nographic", "-enable-kvm"]
```

Step 2: Create a Script for Downloading and Converting the Image
Create a file named extract_and_convert.sh with the following content:

```
#!/bin/sh
wget http://downloads.openwrt.org/releases/23.05.2/targets/x86/64/openwrt-23.05.2-x86-64-generic-ext4-combined-efi.img.gz -O /tmp/openwrt.img.gz
gunzip /tmp/openwrt.img.gz
qemu-img convert -f raw -O vpc /tmp/openwrt.img /openwrt.vhdx
```

Step 3: Build the Docker Image
In the directory containing Dockerfile and extract_and_convert.sh, run:

```
docker build -t openwrt-docker .
```

Step 4: Run the Docker Container
Run the following command to start the container:

```
docker run --rm -it --device /dev/kvm openwrt-docker
```

FROM ubuntu:26.04

# Create container with:
# docker build -f ubuntu26.04.Dockerfile --force-rm --no-cache -t ext-specimens/ubuntu26.04 .
#
# Run script with:
# docker run --privileged=true -v /dev/loop-control:/dev/loop-control -u ${UID}:${GID} ext-specimens/ubuntu26.04 ./generate-specimens-linux.sh

ARG UID=1000
ARG GID=1000

# Combining the apt commands into a single run reduces the size of the resulting image.
# The apt installations below are interdependent and need to be done in sequence.
RUN apt -y update && \
    apt -y install apt-transport-https apt-utils && \
    apt -y install libterm-readline-gnu-perl software-properties-common && \
    apt -y upgrade && \
    apt -y install --no-install-recommends \
        attr \
        coreutils \
        e2fsprogs \
        keyutils \
        locales \
        sudo \
        util-linux && \
    apt clean && rm -rf /var/cache/apt/* /var/lib/apt/lists/*

# Set terminal to UTF-8 by default
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Set up necessary sudo access
RUN usermod --append --groups sudo ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/chown" > /etc/sudoers.d/ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/dmesg" >> /etc/sudoers.d/ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/mkdir" >> /etc/sudoers.d/ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/mknod" >> /etc/sudoers.d/ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/mount" >> /etc/sudoers.d/ubuntu && \
    echo "ubuntu ALL=(ALL:ALL) NOPASSWD: /usr/bin/umount" >> /etc/sudoers.d/ubuntu

WORKDIR /home/ubuntu

USER ubuntu

COPY *.sh LICENSE /home/ubuntu

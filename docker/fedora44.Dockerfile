FROM fedora:44

# Create container with:
# docker build -f fedora44.Dockerfile --force-rm --no-cache -t ext-specimens/fedora44 .
#
# Run script with:
# docker run --privileged=true -u ${UID}:${GID} ext-specimens/fedora44 ./generate-specimens-linux.sh

ARG UID=1000
ARG GID=1000

RUN dnf install -y \
        attr \
        coreutils \
        e2fsprogs \
        util-linux \
        which

# Set up necessary sudo access
RUN groupadd --gid ${GID} build && \
    useradd --create-home --gid ${GID} --shell /bin/bash --uid ${UID} build && \
    usermod --append --groups wheel build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/chown" > /etc/sudoers.d/build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/dmesg" >> /etc/sudoers.d/build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/mkdir" >> /etc/sudoers.d/build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/mknod" >> /etc/sudoers.d/build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/mount" >> /etc/sudoers.d/build && \
    echo "build ALL=(ALL:ALL) NOPASSWD: /usr/bin/umount" >> /etc/sudoers.d/build

WORKDIR /home/build

USER build

COPY *.sh LICENSE /home/build

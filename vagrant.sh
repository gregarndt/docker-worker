#! /bin/bash

set -e -v -x

sudo ln -s /vagrant /worker

NODE_VERSION=v6.9.1
DOCKER_VERSION=1.12.0-0~xenial
KERNEL_VER=$(uname -r)
V4L2LOOPBACK_VERSION=0.9.1

lsb_release -a

# add docker group and add current user to it
sudo groupadd docker
sudo usermod -a -G docker ubuntu

sudo apt-get update -y

[ -e /usr/lib/apt/methods/https ] || {
  apt-get install apt-transport-https
}

# Add docker gpg key and update sources
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo sh -c "echo deb https://apt.dockerproject.org/repo ubuntu-xenial main\
> /etc/apt/sources.list.d/docker.list"

## Update to pick up new registries
sudo apt-get update -y

## Update kernel
sudo apt-get install -y \
    linux-image-$KERNEL_VER \
    linux-headers-$KERNEL_VER \
    linux-image-extra-$KERNEL_VER \
    linux-image-extra-virtual \
    dkms


## Install all the packages
sudo apt-get install -y \
    unattended-upgrades \
    docker-engine=$DOCKER_VERSION \
    lvm2 \
    curl \
    build-essential \
    git-core \
    pbuilder \
    cdbs \
    jq \
    rsyslog-gnutls \
    openvpn \
    lxc \
    gstreamer1.0-alsa \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-tools \

# Install node
cd /usr/local/ && \
  curl https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.gz | tar -xz --strip-components 1 && \
  node -v

## Install v4l2loopback
cd /usr/src
rm -rf v4l2loopback-$V4L2LOOPBACK_VERSION
sudo git clone --branch v$V4L2LOOPBACK_VERSION https://github.com/umlaeute/v4l2loopback.git v4l2loopback-$V4L2LOOPBACK_VERSION
cd v4l2loopback-$V4L2LOOPBACK_VERSION
sudo dkms install -m v4l2loopback -v $V4L2LOOPBACK_VERSION -k ${KERNEL_VER}
sudo dkms build -m v4l2loopback -v $V4L2LOOPBACK_VERSION -k ${KERNEL_VER}

echo "v4l2loopback" | sudo tee --append /etc/modules

cat <<EOF | sudo tee --append /etc/modprobe.d/test-modules.conf >&2
options v4l2loopback devices=100
EOF

sudo modprobe v4l2loopback


# Install Audio loopback devices
echo "snd-aloop" | sudo tee --append /etc/modules

cat <<EOF | sudo tee --append /etc/modprobe.d/test-modules.conf >&2
options snd-aloop enable=1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 index=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
EOF

sudo modprobe snd-aloop

# Create dependency file
depmod


# Configure the docker daemon to use the overlay2 storage driver
mkdir /etc/systemd/system/docker.service.d
cat << EOF > /etc/systemd/system/docker.service.d/docker.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -s overlay2
EOF

# Reload systemd and restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker

#! /bin/bash -vex
sudo apt-get update
sudo apt-get install -y lxc build-essential git v4l-utils gstreamer0.10-tools

# Install node
export NODE_VERSION=v0.11.13
cd /usr/local/ && \
  curl https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.gz | tar -xz --strip-components 1 && \
  node -v

cd $HOME
git clone https://github.com/umlaeute/v4l2loopback.git
cd v4l2loopback
make KCPPFLAGS="-DMAX_DEVICES=100" && sudo make install
cd / && rm -rf $HOME/v4l2loopback

cat << EOF > /etc/modprobe.d/test-modules.conf
options snd-aloop enable=1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 index=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29
options v4l2loopback devices=100
EOF

sh -c 'echo "v4l2loopback" >> /etc/modules'
sh -c 'echo "snd-aloop" >> /etc/modules'
depmod

sudo modprobe v4l2loopback
sudo modprobe snd-aloop
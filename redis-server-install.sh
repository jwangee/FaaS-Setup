#!/bin/bash

# Download the stable Redis server. Compile and install.
sudo apt update
sudo apt install -y make apt-transport-https ca-certificates g++ make pkg-config
sudo apt install -y tcl

cd /local
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
sudo make install

# Configure the redis server.
cd /local/redis-stable
sudo cp utils/redis_init_script /etc/init.d/redis_6379
sudo mkdir /etc/redis
# Create a directory that works as data and working directory for this Redis server.
sudo mkdir /var/redis
sudo mkdir /var/redis/6379

sudo cp /local/redis.conf /etc/redis/6379.conf
sudo update-rc.d redis_6379 defaults
sudo /etc/init.d/redis_6379 start

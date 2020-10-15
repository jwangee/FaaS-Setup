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
sudo mkdir /etc/redis
sudo mkdir /var/redis
cd /local/redis-stable

# redis_6379
# Set the init script
sudo cp utils/redis_init_script /etc/init.d/redis_6379
# Set the data and working directory
sudo mkdir /var/redis/6379
# Set the redis config
sudo cp /local/redis.conf /etc/redis/6379.conf
sudo update-rc.d redis_6379 defaults
sudo /etc/init.d/redis_6379 start

# redis_6380
# Set the init script
sudo cp utils/redis_init_script /etc/init.d/redis_6380
sudo sed -i "s/6379/6380/g" /etc/init.d/redis_6380
# Set the data and working directory
sudo mkdir /var/redis/6380
# Set the redis config
sudo cp /local/redis.conf /etc/redis/6380.conf
sudo sed -i "s/6379/6380/g" /etc/redis/6380.conf
sudo update-rc.d redis_6380 defaults
sudo /etc/init.d/redis_6380 start

# redis_6381
# Set the init script
sudo cp utils/redis_init_script /etc/init.d/redis_6381
sudo sed -i "s/6379/6381/g" /etc/init.d/redis_6381
# Set the data and working directory
sudo mkdir /var/redis/6381
# Set the redis config
sudo cp /local/redis.conf /etc/redis/6381.conf
sudo sed -i "s/6379/6381/g" /etc/redis/6381.conf
sudo update-rc.d redis_6381 defaults
sudo /etc/init.d/redis_6381 start

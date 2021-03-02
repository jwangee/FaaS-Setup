#!/bin/bash

# Install Golang (Deprecated: it always installs the newest version)
#sudo add-apt-repository ppa:longsleep/golang-backports -y
#sudo apt-get update
#sudo apt-get install golang-go -y

# Install Golang 1.15
sudo apt-get update -y
wget https://dl.google.com/go/go1.15.6.linux-amd64.tar.gz
sudo tar -xvf go1.15.6.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv -v go /usr/local

echo '' >> ~/.bashrc
echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
echo 'GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> ~/.bashrc
source ~/.bashrc

# Install protobuf
sudo apt-get install autoconf automake libtool curl make g++ unzip -y
cd $(dirname ${0})
git clone https://github.com/google/protobuf.git
cd protobuf
git submodule update --init --recursive
./autogen.sh
./configure
make -j
make check -j
sudo make install
sudo ldconfig
cd -

## Install gRPC as a go module
#export GO111MODULE=on
#go get google.golang.org/grpc
#
## Install protoc plugin for Go
#go get github.com/golang/protobuf/protoc-gen-go
#export PATH="$PATH:$(go env GOPATH)/bin"
#
## Copy k8s config
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config
#
## Install controller
#git clone https://github.com/USC-NSL/Low-Latency-FaaS.git
#cd Low-Latency-FaaS
#make

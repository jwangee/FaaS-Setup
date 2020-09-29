#!/bin/bash

LOG="/local/kube_start.log"
KUBE_JOIN=/local/kube_join.sh
#if [ -z "$1" ]
#  then
#    echo "No argurments supplied"
#    exit 0
#fi
#NODE_IP=$1
NODE_IP=$(ip route get $(ip route show 0.0.0.0/0 | grep -oP 'via \K\S+') | grep -oP 'src \K\S+')
echo "ip=${NODE_IP}"

#sudo rm -f ${KUBE_JOIN}

log() {
	echo "$(date): $1" >> ${LOG}
}
log "Executing kube-start"

# generate keys to get token via SCP
/usr/bin/geni-get key > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
log "Created ssh key"


#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y software-properties-common
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker.io
log "Installed docker"

#sudo groupadd docker
#sudo usermod -aG docker $USER
#newgrp docker
echo "{\"data-root\": \"/docker\"}" | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
log "Started docker"

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold docker.io kubelet kubeadm kubectl
log "Installed kubernetes"

sudo swapoff -a


echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$NODE_IP\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl restart kubelet
log "Started kubernetes"

HOSTNAME="$(hostname)"
#echo ${HOSTNAME}

if [[ ${HOSTNAME} =~ "node0" ]]; then
    echo "export KUBECONFIG=/local/kubeconfig" | sudo tee -a /etc/environment
    log "I am the master"
    log "Made proj directory"

    export KUBECONFIG=/local/kubeconfig
    log "Exported KUBECONFIG"
    JOIN_STRING="$(sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tail -2)"
    log "Finished kubeadm init"

    # Prepare the kubeconfig file for worker nodes.
    sudo rm -f /local/kubeconfig
    sudo cp -i /etc/kubernetes/admin.conf /local/kubeconfig
    sudo chmod 777 /local/kubeconfig
    #sudo chown $(id -u):$(id -g) /local/kubeconfig

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
    log "Applied Weave"
    kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
    log "Created namespace for openfaas"

    LOCAL_KUBE_JOIN="/local/.tmp.kube_join.sh"
    echo "#!/bin/bash" > ${LOCAL_KUBE_JOIN}
    echo "${JOIN_STRING}" >> ${LOCAL_KUBE_JOIN}
    sudo chmod 777 ${LOCAL_KUBE_JOIN}
    sudo mv ${LOCAL_KUBE_JOIN} ${KUBE_JOIN}
    log "Created kube join file"
else
    log "I am a worker"
    MASTER_HOST="node0.$(hostname | cut -d. -f2-)"
    ssh-keyscan -H ${MASTER_HOST} >> ~/.ssh/known_hosts
    while true
    do
        if scp $MASTER_HOST:${KUBE_JOIN} ${KUBE_JOIN} &> /dev/null
        then
            break
        fi
        log "Waiting for the kubernetes token..."
        sleep 5
    done

    #until [ -f ${KUBE_JOIN} ]
    #do
    #echo "Waiting for join command" >> ${LOG}
    #    sleep 5
    #done
    log "Joining"
    sed -i "$ s/$/ --node-name $(hostname | cut -d. -f1)/" ${KUBE_JOIN}
    sudo ${KUBE_JOIN}
    log "Joined"
fi

# init cluster w/ calico cidr parameters
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# setup config for regular user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# untaint master
#kubectl taint nodes --all node-role.kubernetes.io/master-

# install calico
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

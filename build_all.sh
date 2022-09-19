#!/bin/bash


set -e
# Set –e is used within the Bash to stop execution instantly as a query exits while having a non-zero status.


RED='\033[0;31m'
GREEN='\033[0;32m'
BLACK='\033[0m'


Pre_requisite () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Pre-requisites**                 #
echo -e ${GREEN}#########################################${BLACK}
}

Install_APT_Packages () {
	sudo apt-get install make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl git python3-pip virtualbox fabric virtualbox-qt
}

Install_pip_packages() {
	pip3 install ansible fabric3 jsonpickle requests PyYAML decorator
	echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
	source $HOME/.bashrc
}

Install_vagrant () {
	sudo curl -O https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.deb
	sudo apt update
	sudo apt install ./vagrant_2.2.19_x86_64.deb
	vagrant plugin install vagrant-vbguest vagrant-disksize vagrant-vbguest vagrant-mutate
}



Build_AGW () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Build-AGW**                 
echo -e ${GREEN}#########################################${BLACK}
}

Open_network_interfaces () {
	sudo mkdir -p /etc/vbox/
	sudo touch /etc/vbox/networks.conf
	sudo sh -c "echo '* 192.168.0.0/16' > /etc/vbox/networks.conf"
	sudo sh -c "echo '* 3001::/64' >> /etc/vbox/networks.conf"
}

Clone_code () {
DIR="$HOME/workspace/magma"
if [ -d "$DIR" ]; then
  ### Take action if $DIR exists ###
  echo "Directory Exists ${DIR}"
else
  ###  Control will jump here if $DIR does NOT exists ###
  mkdir workspace && cd workspace
  sudo rm -rf magma
  git clone https://github.com/magma/magma.git
fi
}

Commit_ID () {
cd magma
echo "Give the commit id"
read COMMITID
git checkout $COMMITID
export MAGMA_ROOT=$HOME/workspace/magma
}

Build_agw () {
export MAGMA_ROOT=$HOME/workspace/magma
cd lte/gateway
sudo modprobe vboxnetadp
vagrant destroy -f
fab release package:destroy_vm=True
}

#Copy_package () {
#mkdir magma-packages
#vagrant ssh -c "cp -r magma-packages /vagrant"
#}


Build_FED () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Build-FEG**
echo -e ${GREEN}#########################################${BLACK}
}

Generate_certs () {
cd 
cd ${MAGMA_ROOT} && mkdir -p .cache/test_certs/ && mkdir -p .cache/feg/
cd ${MAGMA_ROOT}/.cache/test_certs/
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 365000 -out rootCA.pem -subj "/C=US/CN=rootca.magma.test"
# create snowflake
cd
cd ${MAGMA_ROOT}/.cache/feg/ && touch snowflake
}

Build_FEDImage () {
cd
cd ${MAGMA_ROOT}/feg/gateway/docker
python3 build.py
}

#echo -e ${GREEN} Run docker containers and check health ${BLACK}
#cd
#cd ${MAGMA_ROOT}/feg/gateway/docker
#python3 build.py -e


Export_FEDImages () {
cd
mkdir images
cd images
docker save feg_gateway_go | gzip > feg_gateway_go.tar.gz
docker save feg_gateway_python | gzip > feg_gateway_python.tar.gz
}

Build_ORC8R () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Build-ORC8R**
echo -e ${GREEN}#########################################${BLACK}
}

Build_Orc8r () {
cd
cd ${MAGMA_ROOT}/orc8r/cloud/docker
python3 build.py --all --nocache --parallel
}

Export_ORC8RImages () {
cd
cd images
docker save orc8r_nginx | gzip > nginx.tar.gz
docker save orc8r_controller  | gzip > controller.tar.gz
}

NMS () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Build-NMS**
echo -e ${GREEN}#########################################${BLACK}
}

Build_NMS () {
cd
cd ${MAGMA_ROOT}/nms
COMPOSE_PROJECT_NAME=magmalte docker-compose build magmalte
}

Export_NMSImages () {
cd
cd images
docker save magmalte_magmalte | gzip > magmalte.tar.gz
}

Build_CWF () {
echo -e ${GREEN}#########################################
echo -e ${GREEN}#    **Build-CWF**
echo -e ${GREEN}#########################################${BLACK}
}

Build_CWF_Image () {
cd
cd ${MAGMA_ROOT}/cwf/gateway/docker
docker-compose --file docker-compose.yml --file docker-compose.override.yml build --parallel
}

Export_CWFImages () {
cd
cd images
docker save cwf_cwag_go | gzip > cwag_go.tar.gz
docker save cwf_gateway_go | gzip > gateway_go.tar.gz
docker save cwf_gateway_sessiond | gzip > gateway_sessiond.tar.gz
docker save cwf_gateway_python | gzip > gateway_python.tar.gz
docker save cwf_gateway_pipelined | gzip > gateway_pipelined.tar.gz
}


Pre_requisite
Install_APT_Packages
Install_pip_packages
Install_vagrant
Build_AGW
Open_network_interfaces
Clone_code
Commit_ID
Build_agw
Build_FED
Generate_certs
Build_FEDImage
Export_FEDImages
Build_ORC8R
Build_Orc8r
Export_ORC8RImages
NMS
Build_NMS
Export_NMSImages
Build_CWF
Build_CWF_Image
Export_CWFImages

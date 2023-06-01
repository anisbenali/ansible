# Makefile
.PHONY: check-sshagent set-env copy_hostname
VARS=variables/$(ENV)-terraform.tfvars
BOLD=$(shell tput bold)
RED=$(shell tput setaf 1)
RESET=$(shell tput sgr0)

https_proxy = http://proxy-appli.infra.dgfip:8080
http_proxy = http://proxy-appli.infra.dgfip:8080
no_proxy = localhost,0,1,2,3,4,5,6,7,8,9,dgfip,rie.gouv.fr,internal,local
export https_proxy
export http_proxy
export no_proxy

# Environnement
###############

set-env:
	@if [ -z $(ENV) ]; then \
		echo "$(BOLD)$(RED)ATTENTION : ENV n'a pas été configuré$(RESET)"; \
		echo "$(BOLD)Usage : make <cible> ENV=<environnement>$(RESET)"; \
		ERROR=1; exit 1; \
	fi ;
set-playbook:
	@if [ $(PLAYBOOK) ]; then \
	echo "$(BOLD) Execussion playbook $(PLAYBOOK) $(RESET)"; \
	fi
	
# Config ssh
############
IP=`grep 'fip_bastion:' inventories/$(ENV)/group_vars/all.yml | awk -F'"' '{print $$2}'`
copy_hostname:
	@cp templates/ssh.j2 ssh.cfg; sed -i "s/hostname/$(IP)/" ssh.cfg

# Gestion de l'agent SSH
########################
check-sshagent: ssh_key.pem
	@chmod 0600 ssh_key.pem

ssha = ssh-agent bash -c "ssh-add ssh_key.pem; $1"
ssh_key.pem:
	$(error \
		Le fichier ssh_key.pem est nécessaire pour interagir avec les VM créées.	\
		Pour le créer, connectez-vous sur votre tenant OpenStack dans Horizon,		\
		sélectionnez "Compute / Paires de clés", puis "Créer une paire de clés".	\
		Nommez la "ssh_key" et copiez le contenu dans le fichier terraform.tfvars.		\
	)

# ANSIBLE
deploy-ansible: set-env set-playbook check-sshagent copy_hostname
	$(call ssha,ansible-playbook -i inventories/$(ENV) $(PLAYBOOK) -v)

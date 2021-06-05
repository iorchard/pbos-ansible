#!/bin/bash

MYSITE="default"
VAULTFILE="inventory/${MYSITE}/group_vars/all/vault.yml"

# Create vault file.
read -s -p 'ssh password: ' SSHPASS; echo ""
read -s -p 'sudo password: ' SUDOPASS; echo ""
read -s -p 'openstack admin password: ' OS_ADMIN_PASS; echo ""
MARIADB_ROOTP_ASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
RABBITMQ_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
MARIADB_KEYSTONE_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)

echo "---" > $VAULTFILE
echo "vault_ssh_password: '$SSHPASS'" >> $VAULTFILE
echo "vault_sudo_password: '$SUDOPASS'" >> $VAULTFILE
echo "vault_openstack_admin_password: '$OS_ADMIN_PASS'" >> $VAULTFILE
echo "vault_mariadb_root_password: '$MARIADB_ROOT_PASS'" >> $VAULTFILE
echo "vault_rabbitmq_openstack_password: '$RABBITMQ_PASS'" >> $VAULTFILE
echo "vault_mariadb_keystone_password: '$MARIADB_KEYSTONE_PASS'" >> $VAULTFILE
echo -n "..." >> $VAULTFILE
head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8 > .vaultpass
ansible-vault encrypt $VAULTFILE

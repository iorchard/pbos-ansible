#!/bin/bash

MYSITE="default"
VAULTFILE="inventory/${MYSITE}/group_vars/all/vault.yml"

# Create vault file.
read -s -p 'ssh password: ' SSHPASS; echo ""
read -s -p 'sudo password: ' SUDOPASS; echo ""
read -s -p 'openstack admin password: ' OS_ADMIN_PASS; echo ""
MARIADB_ROOT_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
RABBITMQ_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
KEYSTONE_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
GLANCE_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
PLACEMENT_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
NEUTRON_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
METADATA_SECRET=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
CINDER_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
RBD_SECRET=$(cat /proc/sys/kernel/random/uuid)
CEPH_FSID=$(cat /proc/sys/kernel/random/uuid)
NOVA_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
BARBICAN_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
BARBICAN_KEK=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 32)

echo "---" > $VAULTFILE
echo "vault_ssh_password: '$SSHPASS'" >> $VAULTFILE
echo "vault_sudo_password: '$SUDOPASS'" >> $VAULTFILE
echo "vault_openstack_admin_password: '$OS_ADMIN_PASS'" >> $VAULTFILE
echo "vault_mariadb_root_password: '$MARIADB_ROOT_PASS'" >> $VAULTFILE
echo "vault_rabbitmq_openstack_password: '$RABBITMQ_PASS'" >> $VAULTFILE
echo "vault_keystone_password: '$KEYSTONE_PASS'" >> $VAULTFILE
echo "vault_glance_password: '$GLANCE_PASS'" >> $VAULTFILE
echo "vault_placement_password: '$PLACEMENT_PASS'" >> $VAULTFILE
echo "vault_neutron_password: '$NEUTRON_PASS'" >> $VAULTFILE
echo "vault_metadata_secret: '$METADATA_SECRET'" >> $VAULTFILE
echo "vault_cinder_password: '$CINDER_PASS'" >> $VAULTFILE
echo "vault_rbd_secret: '$RBD_SECRET'" >> $VAULTFILE
echo "vault_ceph_fsid: '$CEPH_FSID'" >> $VAULTFILE
echo "vault_nova_password: '$NOVA_PASS'" >> $VAULTFILE
echo "vault_barbican_password: '$BARBICAN_PASS'" >> $VAULTFILE
echo "vault_barbican_kek: '$BARBICAN_KEK'" >> $VAULTFILE
echo -n "..." >> $VAULTFILE
head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8 > .vaultpass
ansible-vault encrypt $VAULTFILE

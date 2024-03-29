#!/bin/bash
if [ -f .vaultpass ]; then
	echo "Error) .vaultpass file exists. Remove it first."
	exit 1
fi
VAULTFILE="inventory/${MYSITE}/group_vars/all/vault.yml"

# Create vault file.
read -s -p "$USER password: " USERPASS; echo ""
read -s -p 'openstack admin password: ' OS_ADMIN_PASS; echo ""
CA_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
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
HEAT_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
MAGNUM_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
OCTAVIA_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
OCTAVIA_CERTS_KEY_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 32)
OCTAVIA_HEARTBEAT_KEY=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 32)
DESIGNATE_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
REDIS_PASS=$(head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8)
REDIS_SENTINEL_PASS=$REDIS_PASS

echo "---" > $VAULTFILE
echo "vault_ssh_password: '$USERPASS'" >> $VAULTFILE
echo "vault_sudo_password: '$USERPASS'" >> $VAULTFILE
echo "vault_openstack_admin_password: '$OS_ADMIN_PASS'" >> $VAULTFILE
echo "vault_ca_passphrase: '$CA_PASS'" >> $VAULTFILE
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
echo "vault_heat_password: '$HEAT_PASS'" >> $VAULTFILE
echo "vault_magnum_password: '$MAGNUM_PASS'" >> $VAULTFILE
echo "vault_octavia_password: '$OCTAVIA_PASS'" >> $VAULTFILE
echo "vault_octavia_certs_key_passphrase: '$OCTAVIA_CERTS_KEY_PASS'" >> $VAULTFILE
echo "vault_octavia_heartbeat_key: '$OCTAVIA_HEARTBEAT_KEY'" >> $VAULTFILE
echo "vault_designate_password: '$DESIGNATE_PASS'" >> $VAULTFILE
echo "vault_redis_password: '$REDIS_PASS'" >> $VAULTFILE
echo "vault_redis_sentinel_password: '$REDIS_SENTINEL_PASS'" >> $VAULTFILE
echo -n "..." >> $VAULTFILE
head /dev/urandom |tr -dc A-Za-z0-9 |head -c 8 > .vaultpass
chmod 0400 .vaultpass
sudo chattr +i .vaultpass
ansible-vault encrypt $VAULTFILE

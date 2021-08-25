pbos-ansible
================

This is a guide to install OpenStack on pure baremetal using ansible playbook.

Supported OS
----------------

* Debian 11 (bullseye)
* Ubuntu 20.04 (focal)
* Rocky Linux 8.x

Assumptions
-------------

* The first node in nodes group is the ansible deployer.
* Ansible user in every node has a sudo privilege without NOPASSWD option.
  We will use vault_sudo_pass in ansible vault.
* Ansible user in every node has the same password.
  We will use vault_ssh_pass in ansible vault.
* All node entries should be in /etc/hosts on every node.::

    $ cat /etc/hosts
    127.0.0.1	localhost
    192.168.21.211 pbos-0 # ROCKY Linux
    192.168.21.212 pbos-1 # ROCKY Linux
    192.168.21.213 pbos-2 # ROCKY Linux
    192.168.21.214 pbos-3 # ROCKY Linux
    192.168.21.215 pbos-4 # ROCKY Linux
    192.168.21.216 pbos-5 # ROCKY Linux


Install packages
------------------------

For Debian/Ubuntu::

   $ sudo apt update
   $ sudo apt install -y python3-venv sshpass

For Rocky Linux::

   $ sudo dnf -y install epel-release
   $ sudo dnf -y install python3 sshpass

Install ansible in virtual env
----------------------------------

Create virtual env.::

   $ python3 -m venv ~/.envs/pbos

Source the env.::

   $ source ~/.envs/pbos/bin/activate

Install ansible.::

   $ python -m pip install -U pip
   $ python -m pip install wheel
   $ python -m pip install ansible pymysql openstacksdk

Prepare
---------

Go to pbos-ansible directory.::

   $ cd pbos-ansible

Copy default inventory and create hosts file for your environment.::

   $ export MYSITE="mysite" # put your site name
   $ cp -a inventory/default inventory/$MYSITE
   $ vi inventory/$MYSITE/hosts
   pbos-0 ansible_host=192.168.21.170 ansible_port=22 ansible_user=pengrix ansible_conntion=local
   pbos-1 ansible_host=192.168.21.171 ansible_port=22 ansible_user=pengrix
   pbos-2 ansible_host=192.168.21.172 ansible_port=22 ansible_user=pengrix
   pbos-3 ansible_host=192.168.21.173 ansible_port=22 ansible_user=pengrix
   pbos-4 ansible_host=192.168.21.174 ansible_port=22 ansible_user=pengrix
   pbos-5 ansible_host=192.168.21.175 ansible_port=22 ansible_user=pengrix
   
   [controller]
   pbos-[0:2]
   
   [mariadb]
   pbos-[0:2]
   
   [rabbitmq]
   pbos-[0:2]
   
   [compute]
   pbos-[3:5]
   
   [nodes:children]
   controller
   compute

Modify hostname, ip, port, and user in hosts file for your environment.

Create and update ansible.cfg.::

   $ sed "s/MYSITE/$MYSITE/" ansible.cfg.sample > ansible.cfg

Create a vault file for user and openstack admin password.::

   $ ./vault.sh
   user password: 
   openstack admin password: 
   Encryption successful

Edit group_vars/all/vars.yml for your environment.::

   $ vi inventory/$MYSITE/group_vars/all/vars.yml
   ## custom variables
   # keepalived
   keepalived_interface: "eth1"
   keepalived_vip: "192.168.21.169"
   
   # openstack
   openstack_release: "wallaby"
   
   # openstack mariadb
   openstack_mariadb_acl_cidr:
     - "localhost"
     - "192.168.21.0/255.255.255.0"
   
   # neutron
   provider_interface: "eth2"
   overlay_interface: "eth3"
   
   # ceph
   ceph_public_network_iface: eth4
   ceph_rgw_service_iface: eth0
   ceph_public_network: 192.168.24.0/24
   ceph_cluster_network: 192.168.24.0/24
   ceph_replicas: 2
   ceph_mgr_pg_autoscaler: true
   ceph_osd_devices:
     - /dev/sdb
     - /dev/sdc
     - /dev/sdd

Check the connectivity to all nodes.::

   $ ansible -m ping all

Run
----

Get ansible roles to install pbos.::

   $ ansible-galaxy role install --force --role-file requirements.yml

Run ansible playbook.::

   $ ansible-playbook site.yml


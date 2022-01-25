pbos-ansible
================

This is a guide to install OpenStack on pure baremetal using ansible playbook.

Supported OS
----------------

* Debian 11 (bullseye): Not maintained
* Ubuntu 20.04 (focal): Not maintained
* Rocky Linux 8.x: Only supported OS currently

Assumptions
-------------

* The first node in controller group is the ansible deployer.
* Ansible user in every node has a sudo privilege.
  If the sudo privilege without NOPASSWD, 
  we will use vault_sudo_pass in ansible vault.
* Ansible user in every node has the same password.
  We will use vault_ssh_pass in ansible vault.
* All nodes should be in /etc/hosts on every node.::

    $ cat /etc/hosts
    127.0.0.1	localhost
    192.168.21.201 pbos-0 # ROCKY Linux
    192.168.21.202 pbos-1 # ROCKY Linux
    192.168.21.203 pbos-2 # ROCKY Linux
    192.168.21.204 pbos-3 # ROCKY Linux
    192.168.21.205 pbos-4 # ROCKY Linux
    192.168.21.206 pbos-5 # ROCKY Linux

* ansible inventory groups

    - controller: openstack controller and ceph mon/mgr/rgw
    - compute: openstack compute and ceph osd

Install packages
------------------------

For Debian/Ubuntu::

   $ sudo apt update
   $ sudo apt install -y python3-venv sshpass

For Rocky Linux::

   $ sudo dnf -y install epel-release
   $ sudo dnf -y install python3 sshpass python3-cryptography

* python3 is required to run PBOS playbook so install it on all nodes.
* sshpass is required for password-based ssh connection so install it 
  on the deployer node.
* python3-cryptography is required by ansible crypto collection so 
  install it on the deployer node.

Install ansible in virtual env
----------------------------------

Create virtual env.::

   $ python3 -m venv ~/.envs/pbos

Activate the virtual env.::

   $ source ~/.envs/pbos/bin/activate

Install ansible.::

   $ python -m pip install -U pip
   $ python -m pip install wheel
   $ python -m pip install ansible==4.10.0 pymysql openstacksdk

Prepare
---------

Go to pbos-ansible directory.::

   $ cd pbos-ansible

Copy default inventory and create hosts file for your environment.::

   $ export MYSITE="mysite" # put your site name
   $ cp -a inventory/default inventory/$MYSITE
   $ vi inventory/$MYSITE/hosts
   pbos-1 ansible_host=192.168.21.201 ansible_port=22 ansible_user=clex ansible_connection=local
   pbos-2 ansible_host=192.168.21.202 ansible_port=22 ansible_user=clex
   pbos-3 ansible_host=192.168.21.203 ansible_port=22 ansible_user=clex
   pbos-4 ansible_host=192.168.21.204 ansible_port=22 ansible_user=clex
   pbos-5 ansible_host=192.168.21.205 ansible_port=22 ansible_user=clex
   pbos-6 ansible_host=192.168.21.206 ansible_port=22 ansible_user=clex
   
   [controller]
   pbos-[1:3]
   
   [compute]
   pbos-[4:6]
   
   
   ###################################################
   ## Do not touch below if you are not an expert!!! #
   ###################################################
   
   [mariadb:children]
   controller
   
   [rabbitmq:children]
   controller
   
   [keystone:children]
   controller
   
   [glance:children]
   controller
   
   [placement:children]
   controller
   
   [cinder:children]
   controller
   
   [barbican:children]
   controller
   
   [openstack:children]
   controller
   compute
   
   [ceph_mon:children]
   controller
   
   [ceph_mgr:children]
   controller
   
   [ceph_rgw:children]
   controller
   
   [ceph_osd:children]
   compute
   
   [ceph:children]
   ceph_mon
   ceph_mgr
   ceph_rgw
   ceph_osd

Modify hostname, ip, port, and user for your environment.

Create and update ansible.cfg.::

   $ sed "s/MYSITE/$MYSITE/" ansible.cfg.sample > ansible.cfg

Create a vault file for several passwords.::

   $ ./vault.sh
   user password: 
   openstack admin password: 
   Encryption successful

Caveat) If you already ran a playbook, never run vault.sh script again.
Then, the passwords are newly created again so it will not match with the
already deployed passwords.

Edit group_vars/all/vars.yml for your environment.::

   $ vi inventory/$MYSITE/group_vars/all/vars.yml
   ---
   ## custom variables
   # keepalived on mgmt iface
   keepalived_interface: "eth1"
   keepalived_vip: "192.168.21.200"
   # keepalived on service iface
   # if the default gateway is on service iface, we should set this variables.
   keepalived_interface_svc: "eth0"
   keepalived_vip_svc: "192.168.20.200"
   
   # openstack
   openstack_release: "wallaby"
   
   # openstack mariadb
   openstack_mariadb_acl_cidr:
     - "localhost"
     - "192.168.21.0/255.255.255.0"
   
   # storage
   # storage backends: ceph, lvm, or both
   # ceph for production, lvm for demo/test.
   # Never use lvm for production since lvm creates and uses loopback device.
   # If there are multiple backends, the first one will be the default backend.
   storage_backends:
     - ceph
     - lvm
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
   
   # lvm size in GiB. Should be set it less than / partition available size.
   loopback_file: "/storage/pbos.lvm"
   lvm_size: 50G
   
   # neutron
   provider_interface: "eth2"
   overlay_interface: "eth3"
   
   ######################################################
   # Warn: Do not edit below if you are not an expert.  #
   ######################################################


Check the connectivity to all nodes.::

   $ ansible -m ping all

Run
----

Get ansible roles.::

   $ ansible-galaxy role install --force --role-file requirements.yml

Run a playbook.::

   $ ansible-playbook site.yml


Check
------

source .bashrc.::

    $ source ~/.bashrc

Check ceph status if ceph is installed.::

    $ sudo ceph -s

The output should show HEALTH_OK in cluster section and placement groups(pgs)
should be in active+clean state.

Check openstack services.::

    $ openstack service list

There should be 8 services. - barbican, cinderv2, glance, cinderv3, neutron,
nova, keystone, placement.

Check openstack compute service.::

    $ openstack compute service list

Every service should be enabled and up.

Check openstack volume service.::

    $ openstack volume service list

There should be lvm and/or ceph volume service.
Every service should be enabled and up.

Check openstack network agent list.::

    $ openstack network agent list

Every service should be alive (:-)) and up.

Horizon
----------

The horizon dashboard listens on tcp 8000 on controller nodes.

Open your browser. 

If keepalived_svc_vip is set, 
go to http://<keepalived_vip_svc>:8000/dashboard/

If keepalived_svc_ip is not set,
go to http://<keepalived_vip>:8000/dashboard/


Test
------

Run openstack-test.sh script.::

    $ ./scripts/openstack_test.sh

It

* Creates a private/provider network and subnet 
  When it creates provider network, it will ask address pool range.
* Creates a router
* Creates a cirros image
* Adds security group rules
* Creates a flavor
* Creates an instance
* Adds a floating ip to an instance
* Creates a volume
* Attaches a volume to an instance

If everything goes well, the output looks like this.::

   $ ./scripts/openstack_test.sh
   ...
   Creating provider network...
   Type the provider network address (e.g. 192.168.22.0/24): 192.168.22.0/24
   Okay. I got the provider network address: 192.168.22.0/24
   The first IP address to allocate (e.g. 192.168.22.100): 192.168.22.200
   The last IP address to allocate (e.g. 192.168.22.200): 192.168.22.210
   Okay. I got the last address of provider network pool: 192.168.22.210
   ...
   +------------------+------------------------------------------------+
   | Field            | Value                                          |
   +------------------+------------------------------------------------+
   | addresses        | private-net=172.30.1.30, 192.168.22.195        |
   | flavor           | m1.tiny (410f3140-3fb5-4efb-94e5-73d77d6242cf) |
   | image            | cirros (870cf94b-8d2b-43bd-b244-4bf7846ff39e)  |
   | name             | test                                           |
   | status           | ACTIVE                                         |
   | volumes_attached | id='2cf21340-b7d4-464f-a11b-22043cc2d3e6'      |
   +------------------+------------------------------------------------+

Connect to the instance via provider network ip using ssh on the machine
that has a provider network access.::

   (a node with provider network access) $ ssh cirros@192.168.22.195
   cirros@192.168.22.195's password: 
   $ ip address show dev eth0
   2: eth0:<BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc pfifo_fast qlen 1000
       link/ether fa:16:3e:ed:bc:7b brd ff:ff:ff:ff:ff:ff
       inet 172.30.1.30/24 brd 172.30.1.255 scope global eth0
          valid_lft forever preferred_lft forever
       inet6 fe80::f816:3eff:feed:bc7b/64 scope link 
          valid_lft forever preferred_lft forever

Password is the default cirros password (hint: password seems to be created
by someone who loves baseball, I think.)



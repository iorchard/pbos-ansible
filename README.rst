pbos-ansible
================

This is a guide to install OpenStack on pure baremetal using ansible playbook.

If you want to install PBOS in offline environment, read README-offline.rst.

Supported OS
----------------

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
    192.168.21.201 pbos-1 # ROCKY Linux
    192.168.21.202 pbos-2 # ROCKY Linux
    192.168.21.203 pbos-3 # ROCKY Linux

Networks
-----------

I assume there are 5 networks.

* service network: Public service network (e.g. 192.168.20.0/24)
* management network: Management and internal network (e.g. 192.168.21.0/24)
* provider network: OpenStack provider network (e.g. 192.168.22.0/24)
* overlay network: OpenStack overlay network (e.g. 192.168.23.0/24)
* storage network: Ceph public/cluster network (e.g. 192.168.24.0/24)

Install packages
------------------------

For Rocky Linux::

   $ sudo dnf -y install python3 python39 sshpass python3-cryptography

* python3 is required to run PBOS playbook so install it on all nodes.
* python39 is required for ansible environment so install it on the
  deployer node.
* sshpass is required for password-based ssh connection so install it 
  on the deployer node.
* python3-cryptography is required by ansible crypto collection so 
  install it on the deployer node.

Install ansible in virtual env
----------------------------------

Create virtual env.::

   $ python3.9 -m venv ~/.envs/pbos

Activate the virtual env.::

   $ source ~/.envs/pbos/bin/activate

Install ansible.::

   $ python -m pip install -U pip
   $ python -m pip install wheel
   $ python -m pip install ansible==5.10.0 pymysql openstacksdk netaddr

Prepare
---------

Put amphora image file in user's home directory.
It is used by octavia role.::

   $ curl -sLO http://192.168.151.110:8000/pbos/amphora-x64-haproxy.qcow2

Go to pbos-ansible directory.::

   $ cd pbos-ansible

Copy default inventory and create hosts file for your environment.::

   $ export MYSITE="mysite" # put your site name
   $ cp -a inventory/default inventory/$MYSITE
   $ vi inventory/$MYSITE/hosts
   pbos-controller-1 ansible_host=192.168.21.201 ansible_port=22 ansible_user=clex 
   ansible_connection=local
   pbos-controller-2 ansible_host=192.168.21.202 ansible_port=22 ansible_user=clex
   pbos-controller-3 ansible_host=192.168.21.203 ansible_port=22 ansible_user=clex
   pbos-compute-1 ansible_host=192.168.21.204 ansible_port=22 ansible_user=clex
   pbos-compute-2 ansible_host=192.168.21.205 ansible_port=22 ansible_user=clex
   pbos-storage-1 ansible_host=192.168.21.206 ansible_port=22 ansible_user=clex
   pbos-storage-2 ansible_host=192.168.21.207 ansible_port=22 ansible_user=clex
   pbos-storage-3 ansible_host=192.168.21.208 ansible_port=22 ansible_user=clex
   pbos-storage-4 ansible_host=192.168.21.209 ansible_port=22 ansible_user=clex
   
   [controller]
   pbos-controller-[1:3]
   
   [compute]
   pbos-compute-[1:2]
   
   [storage_controller]
   pbos-storage-[1:3]
   
   [storage]
   pbos-storage-[1:4]

   ###################################################
   ## Do not touch below if you are not an expert!!! #
   ###################################################

Modify hostname, ip, port, and user for your environment.

* controller group: openstack controller nodes
* compute group: openstack compute nodes
* storage_controller group: ceph controller(mon, mgr) nodes
* storage group: ceph osd nodes

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
   # set offline to true if there is no internet connection
   offline: false
   # set local repo url if offline is true
   # See https://github.com/iorchard/pbos_iso to set up local repo.
   #local_repo_url: http://192.168.21.3:8000
   # keepalived on mgmt iface
   keepalived_interface: "eth1"
   keepalived_vip: "192.168.21.210"
   # keepalived on service iface
   # if the default gateway is on service iface, we should set this variables.
   keepalived_interface_svc: "eth0"
   keepalived_vip_svc: "192.168.20.210"
   
   # common
   # deploy_ssh_key: (boolean) set true to create and deploy ssh keypair 
   # from the first controller to other nodes
   deploy_ssh_key: false
   
   # ntp
   ntp_allowed_cidr: "192.168.21.0/24"
    
   # openstack mariadb
   openstack_mariadb_acl_cidr:
     - "localhost"
     - "192.168.21.0/255.255.255.0"
   
   ## haproxy 
   # ha_mode: multi-master is the default mode.
   # set this to true if you want to use active-standby mode.
   force_active_standby: false
   # enable_public_svc: set to true for public service of mariadb, rabbitmq
   enable_public_svc: true
   
   # storage
   # storage backends: ceph, lvm, lightos
   # If there are multiple backends, the first one will be the default backend.
   storage_backends:
     - ceph
     - lvm
     - lightos
   
   ## ceph: set ceph configuration in group_vars/all/ceph.yml
   
   ## lvm: set lvm configuration in group_vars/all/lvm.yml
   
   ## lightos: set lightos configuration in group_vars/all/lightos.yml
   
   # neutron
   provider_interface: "eth2"
   overlay_interface: "eth3"
   
   ######################################################
   # Warn: Do not edit below if you are not an expert.  #
   ######################################################

* offline: set it to true if there is no internet connection
* local_repo_url: local rpm package repo for offline installation
* keepalived_interface: interface name on management network
* keepalived_vip: Virtual IP address on management network 
* keepalived_interface_svc: interface name on service network
* keepalived_vip_svc: Virtual IP address on service network

* deploy_ssh_key: create and deploy ssh keypair
* ntp_allowed_cidr: add management network cidr
* openstack_mariadb_acl_cidr: add management network cidr
* force_active_standby: set this true for haproxy active-standby mode
* enable_public_svc: expose mariadb/rabbitmq to the service network
* storage_backends: ceph, lvm, and lightos are supported.
  (set the configuration in each storage yaml file.)
* provider_interface: openstack provider network interface name
* overlay_interface: openstack overlay network interface name

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

The horizon dashboard listens on tcp 8800 on controller nodes.

Open your browser. 

If keepalived_svc_vip is set, 
go to http://<keepalived_vip_svc>:8800/dashboard/

If keepalived_svc_ip is not set,
go to http://<keepalived_vip>:8800/dashboard/


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


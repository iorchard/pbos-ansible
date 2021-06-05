pbos-ansible
================

This is a guide to install OpenStack on pure baremetal using ansible playbook.

Assumptions
-------------

* The first node in nodes group is the ansible deployer.
* Ansible user in every node has a sudo privilege without NOPASSWD option.
  We will use vault_sudo_pass in ansible vault.
* Ansible user in every node has the same password.
  We will use vault_ssh_pass in ansible vault.

Install ansible
-----------------

Install python3-venv.::

   $ sudo apt update
   $ sudo apt install -y python3-venv

Create virtual env.::

   $ python3 -m venv .envs/pbos

Source the env.::

   $ source .envs/pbos/bin/activate

Install ansible.::

   $ python -m pip install -U pip
   $ python -m pip install wheel
   $ python -m pip install ansible pymysql openstacksdk

Prepare
---------

Copy default inventory and create hosts file for your environment.::

   $ MYSITE="mysite" # put your kubernetes site name
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

Create a vault file for ssh and sudo password.::

   $ ./vault.sh
   ssh password: 
   sudo password: 
   Encryption successful

Check the connectivity to all nodes.::

   $ ansible -m ping all

Run
----

Get ansible roles to install pengrix kubernetes.::

   $ ansible-galaxy role install --force --role-file requirements.yml

Run ansible playbook.::

   $ ansible-playbook site.yml



#!/bin/bash

set -e -o pipefail

get_cirros_image () {
    local rel_url="http://download.cirros-cloud.net/version/released"
    IMG="/tmp/cirros.img"

    echo "Try to get cirros image from the internet..."
    if curl --connect-timeout 3 --silent --output /dev/null -I $rel_url;then
        echo "Yes, I can get cirros image. Download it."
        v=$(curl -s $rel_url)
        curl -sLo $IMG \
            http://download.cirros-cloud.net/${v}/cirros-${v}-x86_64-disk.img
    else
        echo "Fail to get cirros image from the internet."
        read -p 'Type the image path. (/path/to/imgfile): ' IMG
    fi
    # check the image file exists.
    if [ ! -f "$IMG" ]; then
        echo "Cannot find an image. Abort."
        exit 1
    fi

}
ask_public_net_settings () {
    
    while true; do
        read -p 'Type the provider network address (e.g. 192.168.22.0/24): ' PN
        # check if PN has the right format.
        if grep -P -q  "^\d+\.\d+\.\d+.\d+\/\d" <<<"$PN"; then
            echo "Okay. I got the provider network address: $PN"
            break
        fi
        echo "You typed the wrong subnet address format. Type again."
    done
    
    read -p 'The first IP address to allocate (e.g. 192.168.22.100): ' FIP
    read -p 'The last IP address to allocate (e.g. 192.168.22.200): ' LIP
}

echo "Creating private network..."
if ! openstack network show private-net >/dev/null 2>&1; then
    openstack network create private-net
    openstack subnet create \
        --network private-net \
        --subnet-range 172.30.1.0/24 \
        --dns-nameserver 8.8.8.8 \
        private-subnet
fi
echo "Done"

echo "Creating provider network..."
if ! openstack network show public-net >/dev/null 2>&1; then
    ask_public_net_settings
    openstack network create \
        --external \
        --share \
        --provider-network-type flat \
        --provider-physical-network provider \
        public-net
    openstack subnet create --network public-net \
        --subnet-range ${PN} \
        --allocation-pool start=${FIP},end=${LIP} \
        --dns-nameserver 8.8.8.8 public-subnet
fi
echo "Done"
echo "Creating router..."
if ! openstack router show admin-router >/dev/null 2>&1; then
    openstack router create admin-router
    openstack router add subnet admin-router private-subnet
    openstack router set --external-gateway public-net admin-router
    openstack router show admin-router
fi
echo "Done"

echo "Creating image..."
get_cirros_image
if ! openstack image show cirros >/dev/null 2>&1; then
    openstack image create \
        --disk-format qcow2 \
        --container-format bare \
        --file $IMG \
        --public \
        cirros
    openstack image show cirros
fi
echo "Done"

echo "Adding security group rules"
set +e +o pipefail
ADMIN_PROJECT=$(openstack project show -c id -f value admin)
ADMIN_SEC=$(openstack security group list --project $ADMIN_PROJECT -c ID -f value)
if ! (openstack security group rule list $ADMIN_SEC | grep -q tcp); then
    openstack security group rule create --protocol tcp --remote-ip 0.0.0.0/0 --dst-port 1:65535 --ingress  $ADMIN_SEC
fi
if ! (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*ingress'); then
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 $ADMIN_SEC
fi
if ! (openstack security group rule list $ADMIN_SEC | grep -q 'icmp.*egress'); then
    openstack security group rule create --protocol icmp --remote-ip 0.0.0.0/0 --egress $ADMIN_SEC
fi
echo "Done"

set -e -o pipefail
if openstack server show test >/dev/null 2>&1; then
    echo "Removing existing test VM..."
    openstack server delete test
    echo "Done"
fi

if ! openstack flavor show m1.tiny >/dev/null 2>&1; then
    echo "Create m1.tiny flavor."
    openstack flavor create --vcpus 1 --ram 1024 --disk 10 m1.tiny
    echo "Done"
fi

IMAGE=$(openstack image show cirros -f value -c id)
FLAVOR=$(openstack flavor show m1.tiny -f value -c id)
NETWORK=$(openstack network show private-net -f value -c id)

echo "Creating virtual machine..."
openstack server create \
    --image $IMAGE \
    --flavor $FLAVOR \
    --nic net-id=$NETWORK --wait \
    test >/dev/null
echo "Done"

echo "Adding floating ip to vm..."
FLOATING_IP=$(openstack floating ip create -c floating_ip_address -f value public-net)
openstack server add floating ip test $FLOATING_IP
echo "Done"

if openstack volume show test_vol >/dev/null 2>&1; then
  echo "Removing existing test volume.."
  openstack volume delete test_vol
  echo "Done"
fi

echo "Creating test volume..."
openstack volume create --size 5 --image $IMAGE test_vol >/dev/null
echo "Done"
i=0
VOLUME_STATUS=""
set +e +o pipefail
until [ x"${VOLUME_STATUS}" = x"available" ]
do
  echo "Waiting for test volume availability..."
  sleep 1
  VOLUME_STATUS=$(openstack volume show test_vol -f value -c status)
  if [ "$i" = "10" ]; then
    echo "Abort: Volume is not available at least 10 seconds so I give up."
    exit 1
  fi
  ((i++))
done

set -e -o pipefail
echo -n "Attaching volume to vm..."
openstack server add volume test test_vol
echo "Done"

echo "VM status"
openstack server show test -c name -c addresses -c flavor \
    -c status -c image -c volumes_attached

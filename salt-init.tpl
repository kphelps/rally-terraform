#!/bin/bash

ip=$(hostname --ip-address)
full_hostname="${hostname}-$${ip}"
coordinator_ip="$${coordinator_ip:-$ip}"

echo "$${coordinator_ip}" > /etc/rallyd-coordinator-ip
echo "127.0.0.1 $${full_hostname}" >> /etc/hosts
echo "$${full_hostname}" > /etc/hostname
hostname "$${full_hostname}"

mkdir -p /srv/salt
mkdir -p /srv/pillar

cat << 'EOF' >> /srv/pillar/top.sls
base:
  '*':
    - elasticsearch
EOF
cat << 'EOF' >> /srv/pillar/elasticsearch.sls
elasticsearch_host: ${elasticsearch_host}
EOF

sudo apt install -y git
git clone https://github.com/kphelps/rally-terraform.git
cp -r rally-terraform/salt /srv/salt
curl -L https://bootstrap.saltstack.com -o bootstrap_salt.sh
sudo sh bootstrap_salt.sh
sudo salt-call --local state.apply

#!/bin/bash

yum update -y

cat <<EOF > /etc/yum.repos.d/mongodb-org-6.0.repo
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-6.0.asc
EOF

yum install -y mongodb-org

systemctl enable mongod
systemctl start mongod

sed -i 's/^  bindIp: .*/  bindIp: 0.0.0.0/' /etc/mongod.conf

systemctl restart mongod

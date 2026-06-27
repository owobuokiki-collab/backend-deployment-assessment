#!/bin/bash

# Update system
yum update -y

# Install Git
yum install git -y

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install PM2
npm install -g pm2

# Clone the backend repository
cd /home/ec2-user
git clone https://github.com/owobuokiki-collab/backend-deployment-assessment.git

# Go to backend folder
cd backend-deployment-assessment/backend

# Install dependencies
npm install

# Create environment file
cat <<EOF > .env
PORT=8080
MONGODB_URI=mongodb://10.0.4.87:27017/startuptech
EOF

# Start application
pm2 start server.js --name startuptech-backend
pm2 save
pm2 startup systemd -u ec2-user --hp /home/ec2-user

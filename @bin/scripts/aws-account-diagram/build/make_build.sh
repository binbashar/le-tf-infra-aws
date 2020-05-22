#!/usr/bin/env bash

#
# Clone repo, build and push CloudMapper docker-image
#
git clone https://github.com/duo-labs/cloudmapper.git
cd cloudmapper
docker build -t cloudmapper .
docker tag cloudmapper binbash/cloudmapper:0.0.1
docker push binbash/cloudmapper:0.0.1

cd ..

#
# Clone repo, build and push AWS SecurityViz docker-image
#
git clone https://github.com/anaynayak/aws-security-viz.git
cp ./aws-security-viz/Dockerfile aws-security-viz/Dockerfile
cp ./aws-security-viz/generateSecurityGroup.sh aws-security-viz/
cd aws-security-viz
docker build -t aws-security-viz .
docker tag aws-security-viz binbash/aws-security-viz:0.0.1
docker push binbash/aws-security-viz:0.0.1

#
# Clean up post-step.
#
cd ..
rm -rf cloudmapper
rm -rf aws-security-viz








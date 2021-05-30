#!/bin/bash

# Script used to set up a new node inside an Elasticsearch cluster in AWS

sudo yum update -y

# Importing ES-GPG key

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Java 11 Installation

amazon-linux-extras install java-openjdk11 -y

# Elasticsearch 7.13.0 Installation

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.13.0-x86_64.rpm

sudo rpm --install elasticsearch-7.13.0-x86_64.rpm

echo ES_JAVA_OPTS="\"-Xms1g -Xmx1g\"" >> /etc/sysconfig/elasticsearch
echo MAX_LOCKED_MEMORY=unlimited >> /etc/sysconfig/elasticsearch

# Discovery EC2 plugin is used for the nodes to create the cluster in AWS
echo -e "yes\n" | /usr/share/elasticsearch/bin/elasticsearch-plugin install discovery-ec2

# Variable configuration

es_cluster_name="my-es-cluster"

# Shortest configuration for Elasticsearch nodes to find each other
echo "cloud.aws.region: eu-central-1" >> /etc/elasticsearch/elasticsearch.yml
echo "network.host: _ec2_" >> /etc/elasticsearch/elasticsearch.yml
echo "cluster.name: ${es_cluster_name}" >> /etc/elasticsearch/elasticsearch.yml
echo "discovery.seed_providers: ec2" >> /etc/elasticsearch/elasticsearch.yml
network.host: 0.0.0.0

### Executing systemctl commands

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch
sudo systemctl start elasticsearch

echo "Node setup finished!" > ~/terraform.txt

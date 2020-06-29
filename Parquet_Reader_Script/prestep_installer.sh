#!/bin/bash

#to install packages
sudo apt-get install software-properties-common
sudo add-apt-repository main
sudo add-apt-repository universe
sudo add-apt-repository restricted
sudo add-apt-repository multiverse
sudo apt-get update

sudo apt-get install python3.8			#Install Python
#sudo apt-get install python3-pip -y
sudo apt-get install python3-pandas -y 	#Install pandas
sudo apt install awscli -y  			#Install AWS CLI.









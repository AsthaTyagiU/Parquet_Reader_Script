#!/bin/bash

#installing R
sudo apt-get install software-properties-common
sudo add-apt-repository main
sudo add-apt-repository universe
sudo add-apt-repository restricted
sudo add-apt-repository multiverse
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libxml2-dev libcurl4-openssl-dev
sudo apt install r-base -y
sudo su - -c "R -e \"install.packages('ps', repos='http://cran.rstudio.com/')\""

#install required R packages and run R script to read parquet file
sudo Rscript Parquet_Reader.R $1 $2

echo "Exiting EC2 instance"
exit

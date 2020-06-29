#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
Sys.setenv(R_INSTALL_STAGED = FALSE) #for ps
  
message("Installing required R packages") 

r = getOption("repos")
r["CRAN"] = "http://cran.us.r-project.org"
options(repos = r)		   
install.packages('openssl') 
install.packages('curl')
install.packages('httr')
install.packages('xml2')
install.packages('aws.s3')
install.packages('arrow') #installing arrow to read parquet file
install.packages('aws.ec2metadata')

library(aws.s3)
library(arrow)
library(aws.ec2metadata)
library(aws.signature)

message(sprintf("Running R script to read parquet file: %s from bucket: %s", args[1], args[2]))
save_object(args[1], file = args[1], bucket = args[2])
df <- read_parquet(args[1])

# printing second row of dataframe of parquet file to standard error
for (item in 1:length(list)) {

	write(df[2,], stderr())

  }

q()

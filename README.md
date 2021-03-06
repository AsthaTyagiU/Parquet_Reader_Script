# Parquet_Reader_Script
Using R to read parquet file from AWS S3 bucket

Description:
1. Locally creates a Parquet file from excel file using python.
2. Creates an S3 bucket, and uploads the parquet file to the bucket
3. Creates an IAM Role and attach policies that gives Read & List access to the S3 bucket
4. Spins up an EC2 instance that has the above IAM Role attached by using instance profile
5. Install R on the EC2 instance
6. Copies a “Parquet_Reader” R Script to the EC2 instance
7. Runs the “Parquet_Reader” R Script which:
	- Use credentials via the Instance Profile associated to the IAM Role
	- Read the parquet file in the S3 bucket, and print out the second record in the parquet file to standard error
8. Disconnect and terminates the EC2 instance and delete all the created objects like S3 bucket and files, IAM roles, etc.


This script uses:
- Python: to create parquet file from excel file locally. 
- AWS CLI: to perform all the AWS related functions, like creating the S3 bucket, uploading file, etc.
- R: to read parquet file from EC2 instance.

You can change the variables like policy name, bucket name, file name, etc. by modifying declare_var() in main.sh. 


Instructions:
Assuming user is using Linux system. (I used Ubuntu)
1. Download and unzip the folder: 'Parquet_Reader_Script' to your home directory
2. cd Parquet_Reader_Script
3. Run prestep_installer.sh as a pre-step (optional).It installs: Python, panda and aws cli. You can skip this step if its already installed.
4. Run ./main.sh 

If time has allowed, would have loved to add below features:
- Try and catch method for error handling
- retry if ssh to EC2 instance fails
- check if EC2 instacne is up before ssh
- keeping the files which won't require any user attaention (like policy document, etc.) in seprate folder.

Possible errors and resolution:
- Error: [Errno 13] Permission denied: '/home/xxxx/.aws/credentials'.
  Reason: your .aws file doesn't has read/write permissions, due to which aws configure command is failing.
  Resolution: chmod u=rw .aws/credentials  (while running the command keep track of relative path, remember you are in Parquet_Reader_Script folder)

- Error: make_bucket failed: s3://mybucket An error occurred (InvalidBucketName) when calling the CreateBucket operation: The specified bucket is not valid.
  Reason and Resolution: Bucket name should be unique. Before passing a bucket name in the variable, please go through for more rules:    https://forums.aws.amazon.com/message.jspa?messageID=315883

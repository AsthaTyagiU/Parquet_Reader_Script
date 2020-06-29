#!/bin/bash

main(){
declare_var						#declaring variables
echo "Converting xlsx to parquet using Python"
./xlsx_to_parquet.py var_excel_file var_parquet_file	#python file to convert excel file (xlsx) to parquet file locally
aws_config						#configure AWS
create_s3_bucket					#create s3 bucket and upload local parquet file to the bucket
create_iam_role_policies				#create IAM role and policies, and attach policies to the role
create_instance_profile					#create instance profile and add role to it
create_keypair						#create key pair
create_security_grp					#create security group and add required rules to it
launch_ec2_instacne					#launch ec2 instance
login_ec2_inst						#connect to ec2 instance
echo "Back to local command"
terminate_cleanup					#disconnect and terminate instance, and delete all the created objects
}

declare_var(){
echo "Declaring variables"
#declaring variables. In case of file path,if required, add path relative to home directory
{
var_rolename=test_s3readonlyrole
var_trustpolicy_doc=trust_readonly_policy.json #
var_iampolicy=passrole
var_iampolicy_doc_template=iam_passrole_template.json
var_iampolicy_doc=iam_passrole.json
var_instance_profile=test_s3inst_profile
var_key_pair=test_ubuntu_ec2accesskey8
var_security_grp=test_secgrp-ec2-s3
var_ec2_tag_key=Name
var_ec2_tag_value=test_ec2_ubuntu_inst
var_bucket=test270108-mybucket 			#don't use '.' in the bucket name (supported by aws but not by R)
var_arn_policy=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
var_excel_file=Financial_Sample.xlsx  
var_parquet_file=Financial_Sample.parquet
var_ec2ami=ami-0ffac660dd0cb2973 #ub 20  
var_ec2inst_type=t2.micro
}> /dev/null
}

aws_config(){
#configuring aws
echo "Please enter requested details to configure aws"
aws configure
}

create_s3_bucket(){
echo "Creating s3 bucket: $var_bucket and uploading $var_parquet_file to it"
{
# Create bucket
aws s3 mb s3://$var_bucket

#uploading file to S3 bucket
aws s3 cp $var_parquet_file s3://$var_bucket/
}> /dev/null
}

create_iam_role_policies(){
#creating role
echo "Creating IAM role:$var_rolename"
{
aws iam create-role --role-name $var_rolename --assume-role-policy-document file://$var_trustpolicy_doc

#getting account_id to create iam passrole policy document
var_account_id=`aws sts get-caller-identity --query Account --output text`

#creating iam passrole policy document
sed "s/var_account_id/$var_account_id/g"  $var_iampolicy_doc_template > $var_iampolicy_doc
}> /dev/null

echo "Attaching policies:$var_arn_policy,$var_iampolicy to IAM role:$var_rolename"
{
#attaching passrole policy
aws iam put-role-policy --role-name $var_rolename --policy-name $var_iampolicy --policy-document file://$var_iampolicy_doc
#attaching AmazonS3ReadOnlyAccess policy
aws iam attach-role-policy --policy-arn $var_arn_policy --role-name $var_rolename
}> /dev/null
}

create_instance_profile(){
#creating instance profile
echo "creating an instance profile: $var_instance_profile"
{
aws iam create-instance-profile --instance-profile-name $var_instance_profile
#adding role to instance profile
aws iam add-role-to-instance-profile --role-name $var_rolename  --instance-profile-name $var_instance_profile
}
}> /dev/null

create_keypair(){
echo "Creating a key pair: $var_key_pair"
{
#Create a key pair
aws ec2 create-key-pair --key-name $var_key_pair --query 'KeyMaterial' --output text > $var_key_pair.pem
#changing mode to avoid accidental overwrite
chmod 400 $var_key_pair.pem
}> /dev/null
}

create_security_grp(){
echo "Creating a security group: $var_security_grp"
{
#create security group
aws ec2 create-security-group --group-name $var_security_grp --description "security group for ubntu ec2 access" 

#to get public ip
var_ip=`curl -s https://checkip.amazonaws.com`
#adding rules to security group
#for ssh
aws ec2 authorize-security-group-ingress --group-name $var_security_grp --protocol tcp --port 22   --cidr $var_ip/32 --output text
#for data transfer over remote desktop connection
aws ec2 authorize-security-group-ingress --group-name $var_security_grp --protocol tcp --port 3389 --cidr $var_ip/32 --output text
#https
aws ec2 authorize-security-group-ingress --group-name $var_security_grp --protocol tcp --port 443 --cidr $var_ip/32 --output text
}> /dev/null
}

launch_ec2_instacne(){
echo "Waiting for EC2 instance to launch."
{
#Launch EC2 instance
var_ec2_instance_id=`aws ec2 run-instances --image-id $var_ec2ami --count 1 --instance-type $var_ec2inst_type --key-name $var_key_pair --security-groups $var_security_grp  --iam-instance-profile Name=$var_instance_profile --query 'Instances[0].InstanceId' --output text`

sleep 120 #wait 
#create tags
aws ec2 create-tags --resources $var_ec2_instance_id --tags Key=$var_ec2_tag_key,Value=$var_ec2_tag_value

#get public dns
var_public_dns=`aws ec2 describe-instances --instance-ids $var_ec2_instance_id --query 'Reservations[*].Instances[*].PublicDnsName' --output text`

#copying R script files to EC2 instance
scp -i $var_key_pair.pem install_R.sh ubuntu@$var_public_dns:~
scp -i $var_key_pair.pem Parquet_Reader.R ubuntu@$var_public_dns:~
 
sleep 2s	#wait for 2 secs
}> /dev/null
}

login_ec2_inst(){
echo "Connecting to ec2 instance"
{
#login to ec2 instance
ssh -i $var_key_pair.pem ubuntu@$var_public_dns "bash install_R.sh $var_parquet_file $var_bucket"
}
}


terminate_cleanup(){
echo "Exiting the connected ec2 instance" 

echo "Terminating ec2 instance"
#terminate ec2 instance
aws ec2 terminate-instances --instance-ids $var_ec2_instance_id > /dev/null

echo "Deleting key pair, security group, IAM role, policy, bucket, instance profile!" 
{
#Delete key-pair
aws ec2 delete-key-pair --key-name $var_key_pair

#Delete security group
aws ec2 delete-security-group --group-name $var_security_grp

#Delete policies attached to role
aws iam delete-role-policy --role-name $var_rolename --policy-name $var_iampolicy
aws iam delete-policy --policy-arn $var_arn_policy

#Delete IAM role
aws iam delete-role --role-name $var_rolename

#Delete s3 bucket and file
aws s3 rm s3://$var_bucket/$var_parquet_file
aws s3api delete-bucket --bucket $var_bucket

#Delete instance profile
aws iam delete-instance-profile --instance-profile-name $var_instance_profile

}> /dev/null
echo "The End!"
}

main











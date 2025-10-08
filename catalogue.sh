#!/bin/bash

userid=$(id -u)
mongodb="mongodb.surekhadevops.biz"
script_dir=$PWD

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $userid -ne 0 ]; then
    echo "Please run this script with root privilege"
    exit 1
fi

log_folder="/var/log/shell-roboshop"
script_name="$( echo $0 | cut -d "." -f1)"
log_file="$log_folder/$script_name.log"

mkdir -p $log_folder
echo "script started executed at: $(date)" | tee -a $log_file

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R Failure $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 ... $G Success $N" | tee -a $log_file
    fi
}

dnf module disable nodejs -y &>>$log_file
validate $? "Disable NodeJs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enabling NodeJs"

dnf install nodejs -y &>>$log_file
validate $? "Install NodeJs"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Roboshop User Created"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app 
validate $? "Make Directory" 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
validate $? "Downloading Catalogue Zip File"

cd /app  
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/catalogue.zip &>>$log_file
validate $? "unzip catalogue"

npm install &>>$log_file
validate $? "Install dependencies"

cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copy systemctl service"

systemctl daemon-reload &>>$log_file
systemctl enable catalogue &>>$log_file
systemctl start catalogue &>>$log_file
validate $? "Enable and Start catalogue"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Copy mongo repo"

dnf install mongodb-mongosh -y &>>$log_file
validate $? "Install MongoDB client"

INDEX=$(mongosh $mongodb --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $mongodb </app/db/master-data.js &>>$log_file
    validate $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
validate $? "Restarted catalogue"
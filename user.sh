#!/bin/bash

userid=$(id -u)
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
START_TIME=$(date +%s)

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
validate $? "Disable Nodejs"

dnf module enable nodejs:20 -y &>>$log_file
validate $? "Enable Nodejs"

dnf install nodejs -y &>>$log_file
validate $? "Installing Nodejs"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "Creating System User - Roboshop"
else
    echo -e "Roboshop System User Already Exit ... $Y Skip $N" | tee -a $log_file
fi

mkdir -p /app 
validate $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$log_file
validate $? "Downloading user application"

cd /app 
validate $? "Changing to app directory"

rm -rf /app/*
validate $? "Removing existing code"

unzip /tmp/user.zip &>>$log_file
validate $? "Unzip user files"

npm install &>>$log_file
validate $? "NPM Install"

cp $script_dir/user.service /etc/systemd/system/user.service &>>$log_file
validate $? "Copy user service"

systemctl daemon-reload

systemctl enable user  &>>$log_file
validate $? "User Enable"

systemctl start user &>>$log_file
validate $? "User Start"
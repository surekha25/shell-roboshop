#!/bin/bash

userid=$(id -u)

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

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$log_file
validate $? "Copy Mongo Repo"

dnf install mongodb-org -y &>>$log_file
validate $? "Install Mongodb"

systemctl enable mongod &>>$log_file
validate $? "System Enable MongoDB"

systemctl start mongod &>>$log_file
validate $? "System Start MongoDB"

sed -i "s/127.0.0.1/0.0.0.0/g" /etc/mongod.conf &>>$log_file
validate $? "Change Default Port No"

systemctl restart mongod &>>$log_file
validate $? "Restart MongoDB "
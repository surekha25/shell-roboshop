#!/bin/bash

userid=$(id -u)
script_dir=$PWD
mysql="mysql.surekhadevops.biz"

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

dnf install python3 gcc python3-devel -y &>>$log_file
validate $? "Install Python3"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    validate $? "System User Added"
else
    echo "System User Alread Exit ... $Y Skipping $N" | tee -a $log_file
fi

mkdir -p /app 

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
validate $? "Download Payment File"

cd /app 

rm -rf /app/* &>>$log_file
validate $? "Remove existing files"

unzip /tmp/payment.zip &>>$log_file
validate $? "unzip Payment File"

pip3 install -r requirements.txt &>>$log_file
validate $? "Install Dependencies"

cp $script_dir/payment.service /etc/systemd/system/payment.service &>>$log_file 
validate $? "Copy payment service"

systemctl daemon-reload

systemctl enable payment &>>$log_file
validate $? "Enable Payment"

systemctl restart payment &>>$log_file
validate $? "Restart Payment"
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

dnf module disable redis -y &>>$log_file
dnf module enable redis:7 -y &>>$log_file
validate $? "Redis Enable"


dnf install redis -y &>>$log_file
validate $? "Installed Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>$log_file
validate $? "Change Port Number and Protected-Mode to No"

systemctl enable redis 
systemctl start redis &>>$log_file
validate $? "Start Redis"

END_TIME=$(date +%s)
Total_time=$(( $END_TIME - $START_TIME ))
echo -e "Script Executed in: $Y $Total_time seconds $N"

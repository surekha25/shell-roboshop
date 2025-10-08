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

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$log_file
validate $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y &>>$log_file
validate $? "Installing RabbitMq Server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server &>>$log_file
validate $? "Start RabbitMQ"

rabbitmqctl add_user roboshop roboshop123 &>>$log_file
validate $? "Adding User"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$log_file
validate $? "Setting up permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
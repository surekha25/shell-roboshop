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

dnf module disable nginx -y &>>$log_file
validate $? "Disable Nginx"

dnf module enable nginx:1.24 -y &>>$log_file
validate $? "Enable Nginx"

dnf install nginx -y &>>$log_file
validate $? "Install Nginx"

systemctl enable nginx &>>$log_file
systemctl start nginx
validate $? "Enable and Start Nginx"

rm -rf /usr/share/nginx/html/* &>>$log_file
validate $? "Remove Default Files in html folder"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$log_file
validate $? "Downloading Frontend Files"

cd /usr/share/nginx/html 
validate $? "Change Directory to /usr/share/nginx/html"

unzip /tmp/frontend.zip
validate $? "Unzip Frontend Files"

cp $script_dir/nginx.conf /etc/nginx/nginx.conf &>>$log_file
validate $? "Copy nginx.conf to /etc/nginx/nginx.conf"

systemctl restart nginx &>>$log_file
validate $? "System Restart Nginx"

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

dnf install maven -y &>>$log_file
validate $? "Installing Maven"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    validate $? "Creating System User"
else
    echo "System User Already Exit" | tee -a $log_file
fi

mkdir -p /app &>>$log_file
validate $? "Make Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
validate $? "Download shipping file"

cd /app 

rm -rf /app/* &>>$log_file
validate $? "Removing Existing Files"

unzip /tmp/shipping.zip &>>$log_file
validate $? "Unzip shipping file"

mvn clean package &>>$log_file 
validate $? "Clean Maven"

mv target/shipping-1.0.jar shipping.jar &>>$log_file
validate $? "move shipping.jar"

cp $script_dir/shipping.service /etc/systemd/system/shipping.service
systemctl daemon-reload

systemctl enable shipping  &>>$log_file
validate $? "Enable Shipping"

systemctl start shipping &>>$log_file
validate $? "Start Shipping"

dnf install mysql -y &>>$log_file
validate $? "Installing MySQL"

mysql -h $mysql -uroot -pRoboShop@1 -e 'use cities' &>>$log_file
if [ $? -ne 0 ]; then
    mysql -h $mysql -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
    mysql -h $mysql -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$log_file
    mysql -h $mysql -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$log_file
validate $? "Restart Shipping"
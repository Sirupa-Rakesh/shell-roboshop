#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/mongodb.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N"
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGS_FILE
VALIDATE $? "Copying Mongo Repo"

dnf clean all &>>$LOGS_FILE
dnf makecache &>>$LOGS_FILE

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing MongoDB server"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enable MongoDB"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Start MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systemctl restart mongod &>>$LOGS_FILE
VALIDATE $? "Restarted MongoDB"

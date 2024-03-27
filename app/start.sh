#! /bin/bash 

echo "Running a system check..."
lsblk -o NAME,HCTL,SIZE,MOUNTPOINT > /data/app/todolist/static/files/task3.log

pip install -r requirements.txt
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8080

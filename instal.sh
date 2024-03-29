#!/bin/bash

WorkingDirectory="/home/dikanom/myapp"
AppName="myapp" 
ServerName="mansion288.my.id"
ServerPort="80"
ServerIP="0.0.0.0"
sudo apt-get update
sudo apt-get -y upgrade 
sudo apt-get -y install python3 python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools
sudo apt -y autoremove
sudo apt-get -y install python3-venv
sudo apt-get -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
mkdir $WorkingDirectory
cd $WorkingDirectory
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install gunicorn flask
printf "from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello():
    return 'Welcome to Flask Application named $AppName!'
if __name__ == '__main__':
    app.run(host='127.0.0.1')" >> $AppName.py
printf "from $AppName import app
if __name__ == '__main__':
    app.run()" >> wsgi.py
sudo mkdir /var/log/gunicorn/
sudo bash -c "printf \"[Unit]
Description=Gunicorn instance to serve Flask
After=network.target
[Service]
User=root
Group=www-data
WorkingDirectory=$WorkingDirectory
Environment=\"PATH=$WorkingDirectory/venv/bin\"
ExecStart=$WorkingDirectory/venv/bin/gunicorn --bind 127.0.0.1:5000 wsgi:app --error-logfile /var/log/gunicorn/access.log --capture-output --log-level info
[Install]
WantedBy=multi-user.target\" >> /etc/systemd/system/flask.service"
sudo rm -fR /etc/nginx/sites-enabled/default
sudo systemctl daemon-reload
sudo systemctl start flask
sudo systemctl enable flask
sudo rm /etc/nginx/conf.d/flask.conf 
sudo bash -c "printf \"server {
    listen $ServerPort;
    server_name $ServerName;
    location / {
        include proxy_params;
        proxy_pass  http://0.0.0.0:5000;
    }
}\" >> /etc/nginx/conf.d/flask.conf"
 
sudo nginx -t
 
sudo systemctl stop flask.service
sudo systemctl daemon-reload
sudo systemctl start flask.service
sudo systemctl restart nginx

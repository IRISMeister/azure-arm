#!/bin/bash +e
sudo apt update
sudo apt install -y python2
sudo update-alternatives --remove-all python   # エラーが出ても構わない
sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1
python --version

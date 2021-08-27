
sudo apt-get update && sudo apt-get install -y libappindicator1 fonts-liberation && apt-get --fix-broken install
cd /home && mkdir chrome-headless && cd  chrome-headless
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome*.deb
wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip && unzip chromedriver_linux64.zip
apt --fix-broken install && apt install unzip
sudo apt install python3-pip && pip3 install selenium
cd /home/chrome-headless && upzip chromedriver_linux64.zip

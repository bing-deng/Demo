#coding=utf-8
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
import requests

chrome_opt = Options()  # 创建参数设置对象.
chrome_opt.add_argument('--headless')  # 无界面化.
chrome_opt.add_argument('--disable-gpu')  # 配合上面的无界面化.
chrome_opt.add_argument('--window-size=1366,768')  # 设置窗口大小, 窗口大小会有$
chrome_opt.add_argument("--no-sandbox") #使用沙盒模式运行
# 创建Chrome对象并传入设置信息.



while True:
    urls =  requests.get("https://raw.githubusercontent.com/bing-deng/Demo/master/pr.json").json()

    for url in urls['urls']:

        print(url)        
        browser = webdriver.Chrome(chrome_options=chrome_opt,executable_path='/home/chrome-headless/chromedriver')
        #first page -------------------------------------------------
        browser.get(url)
        browser.maximize_window() # 窗口最大化
        time.sleep(2)
        r = browser.execute_script('return document.querySelector("#containerInformationCompany > li:nth-child(1) > span.body-information > a").href')
        print(r)

        browser.execute_script('document.querySelector("#containerInformationCompany > li:nth-child(1) > span.body-information > a").click()')
        time.sleep(2)
        browser.quit()

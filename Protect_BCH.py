#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
交易 自动平仓  
"""
import configparser
from HuobiDMService import HuobiDM
from pprint import pprint
import time
import calendar
import datetime
from pygrape import pygrape
import os
from Echo import Echo
import requests
import click
import json
import sys
import redis
import math

URL = "https://api.hbdm.com"

class NewContract:

    def __init__(self,account, symbol):

        self.account = account

        self.pool = redis.ConnectionPool(host='localhost', port=6379, decode_responses=True)
        self.r = redis.Redis(connection_pool=self.pool)

        self.ticker_cw = {}
        self.ticker_nw = {}
        self.ticker_cq = {}
        self.echo = Echo()
        # 当前合约的类型 只限下一种单的情况
        self.contract_code = ""
        self.hold_position = 0
        config = configparser.ConfigParser()
        config.read('config.ini')
        self.rate_nagative = float(config.get(account, 'rate_nagative'))
        self.rate_positive = float(config.get(account, 'rate_positive'))
        
        ACCESS_KEY = config.get(account, 'key')
        SECRET_KEY = config.get(account, 'sec')
        # self.symbol = config.get(account, 'symbol')
        self.symbol = symbol
        self.price_spread = config.getfloat(account, "price_spead")
        self.pankou_jiacha = config.getfloat(account, "pankou_jiacha")
        self.max_pankou_jiacha = config.getfloat(account, "max_pankou_jiacha")
        self.dm = HuobiDM(URL, ACCESS_KEY, SECRET_KEY)
        self.order_id = 0
        # 获取合约号
        self.is_hold_position()

        #存如价格容器
        self.price_list = []
    def close_order(self,direction, volume, lever_rate, offset, order_id,take_profit_price):
        
        # 获取持仓和持仓合约类型
        self.is_hold_position()

        print(self.price)
        offset_name = ""
        if offset == "close":
            offset_name = "平"
        else:
            offset_name = "开"
        # 持仓信息
        balance = self.dm.get_contract_account_info()
        btc_balance = "%.4f"  % balance["data"][0]["margin_balance"]

        msg = "Protect_BCH 账户:{0} 策略方向:{1} 张数:{2} AND:{3} 价格:{4} 倍数:{5} 订单号:{6} 合约号:{7} 余额： {8}".format( self.account, direction,volume,offset_name,self.price,lever_rate,order_id, self.contract_code, btc_balance)
        # self.alarm(msg)
        # print(account, direction,volume,offset,price,lever_rate,order_id, self.get_friday())
        # print(msg)
        print (u' 合约下单 ')
        # TEST
        # dic = {"status":"ok","data":{"order_id":88},"ts":158797866555}
        # return dic

        # :order_price_type  必填   "limit"限价， "opponent" 对手价 订单报价类型 "limit":限价 "opponent":对手价 "post_only":只做maker单,post only下单只受用户持仓数量限制


        info = self.dm.send_contract_order(symbol=self.symbol, contract_type='quarter', contract_code=self.contract_code, 
                            client_order_id=order_id, price=take_profit_price, volume=volume, direction=direction,
                            offset=offset, lever_rate=lever_rate, order_price_type='limit')
        if "status" in info and info["status"] == "error":
            e_m = self.error_msg(str(info["err_code"]))
            # print(e_m)
            self.echo.alarm(e_m)
        else :
            self.echo.alarm(msg)
            
        # print(info)
        return info

    def place_order(self,direction, volume, lever_rate, offset, order_id,take_profit_price):
        
        # 获取持仓和持仓合约类型
        self.is_hold_position()

        print(self.price)
        offset_name = ""
        if offset == "close":
            offset_name = "平"
        else:
            offset_name = "开"
        # 持仓信息
        balance = self.dm.get_contract_account_info()
        btc_balance = "%.4f"  % balance["data"][0]["margin_balance"]

        msg = "Protect_BCH 账户:{0} 策略方向:{1} 张数:{2} AND:{3} 价格:{4} 倍数:{5} 订单号:{6} 合约号:{7} 余额： {8}".format( self.account, direction,volume,offset_name,self.price,lever_rate,order_id, self.contract_code, btc_balance)
        # self.alarm(msg)
        # print(account, direction,volume,offset,price,lever_rate,order_id, self.get_friday())
        # print(msg)
        print (u' 合约下单 ')
        # TEST
        # dic = {"status":"ok","data":{"order_id":88},"ts":158797866555}
        # return dic

        # :order_price_type  必填   "limit"限价， "opponent" 对手价 订单报价类型 "limit":限价 "opponent":对手价 "post_only":只做maker单,post only下单只受用户持仓数量限制


        info = self.dm.send_contract_order(symbol=self.symbol, contract_type='quarter', contract_code=self.contract_code, 
                            client_order_id=order_id, price=take_profit_price, volume=volume, direction=direction,
                            offset=offset, lever_rate=lever_rate, order_price_type='post_only')
        if "status" in info and info["status"] == "error":
            e_m = self.error_msg(str(info["err_code"]))
            # print(e_m)
            self.echo.alarm(e_m)
        else :
            self.echo.alarm(msg)
            
        # print(info)
        return info
    
    def get_order_detail(self, order_id):
        # test
        # return True
        # 正式
        try:
            # {'status': 'ok', 'data': [{'symbol': self.symbol, 'contract_code': 'BTC190531', 'contract_type': 'next_week', 'volume': 23, 'price': 8618.91, 'order_price_type': 'limit', 'order_type': 1, 'direction': 'sell', 'offset': 'open', 'lever_rate': 5, 'order_id': 2715696613, 'client_order_id': None, 'created_at': 1559239639528, 'trade_volume': 23, 'trade_turnover': 2300.0, 'fee': -8.0017990193024e-05, 'trade_avg_price': 8623.060868381392, 'margin_frozen': 0.0, 'profit': 0, 'status': 6, 'order_source': 'ios'}], 'ts': 1559267687384}
            '''
                data 是数组 
            todo 成交 部分成交 全部成交
            '''
            o = self.dm.get_contract_order_info(symbol=self.symbol, order_id=order_id)
            # print(o)
            if "err_code" in o:
                self.error_msg(str(o["err_code"]))
            else:
                
                 # balance
                balance = self.dm.get_contract_account_info()
                # btc 余额
                btc_balance = balance["data"][0]["margin_balance"]
                print("订单交易成功 余额 : %f" % btc_balance)
                if len(o["data"]) > 0 and o["data"][0]["status"] == 4:
                    print("订单部分成交交易成功")
                return len(o["data"]) > 0 and o["data"][0]["status"] == 6
        except Exception as e :
            print("监测订单状态异常")
            print(e)
    # 是否持仓
    def is_hold_position(self):
        hold = self.dm.get_contract_position_info(self.symbol)
        if "status" in hold and hold["status"] == "ok" and len(hold["data"]) > 0:
            self.contract_code = hold["data"][0]["contract_code"]
            # print(hold)
            # print(self.contract_code)
            return True
        else:
            
            self.contract_code = self.dm.get_contract_info(symbol=self.symbol, contract_type="quarter")["data"][0]["contract_code"]
        return False

    # 获取订单号 和吃单判断
    def get_order_id_lastet(self):
        try:
            biggest = 0
            order_list = self.dm.get_contract_history_orders(symbol=self.symbol, trade_type=0, type=1, status=0, create_date=7)
            lastest_order = order_list["data"]["orders"]

            order_id = lastest_order[0]["order_id"]
            i = lastest_order[0]
            # msg = " 方向：%s 价格%.2f 成交量:%d " %( i["price"], i["amount"], i["direction"])
            if self.order_id != 0 and self.order_id < order_id:
                # {"order_id": 6145284074, "contract_code": "BTC190816", "symbol": "BTC", "lever_rate": 20, "direction": "buy", "offset": "open", "
                #volume": 100, "price": 11243, "create_date": 1565658426370, "order_source": "web", "order_price_type": 1, "order_type": 1, "margin_frozen": 0, "profit": 0, "
                #contract_type": "next_week", 
                #"trade_volume": 0, "trade_turnover": 0, "fee": 0, "trade_avg_price": 0, "status": 3}
                open_close = ''
                if lastest_order[0]["offset"] == 'open':
                    open_close = "开"
                else:
                    open_close = '平'
                # (1准备提交 2准备提交 3已提交 4部分成交 5部分成交已撤单 6全部成交 7已撤单 11撤单中)
                if lastest_order[0]["direction"] == 'buy':
                    open_close += "多"
                else:
                    open_close += '空'

                if lastest_order[0]["status"] == 3:
                    open_close += " 限价委托单 "
                elif lastest_order[0]["status"] == 6:
                    open_close += " 全部成交 "


                msg = "%s 张数:%d 方向:%s 价格:%0.2f  合约类型:%s 操作平台:%s\n" %(open_close, lastest_order[0]["volume"] ,lastest_order[0]["direction"], lastest_order[0]["price"], lastest_order[0]["contract_type"] , lastest_order[0]["order_source"] )
                # self.echo.alarm(msg + json.dumps(lastest_order[0]))
                self.echo.alarm(msg)
            self.order_id = order_id
            return self.order_id
        except Exception as e:
            print(e)
            return 0
    
    def defalut_radis_valuses(self):
        # 持仓和信号 止盈 都变为0
        self.r.set(self.symbol + "_" + "1min" + "_TRIX_5_18_SPREAD_PRE_1MIN",0)
        self.r.set(self.symbol + "_HOLD_POSITION_NUM", 0)
        self.r.set(self.symbol + "_" + "1min" "_TRIX_5_18_PROFIT_ORDER_DONE", 0)
        self.r.set(self.symbol + "_EARN_ORDER_ID",0)
        self.r.set(self.account + "_" +self.symbol + "_UNREAL_PROFIT",0)
        # 相反方向单 危险信号
        self.r.set(self.symbol + "_" + "1min" + "_TRIX_5_18_REVERSE", 0)
        #恢复止盈
        self.r.set(self.symbol + "_1min_" + "EARN_RATE",0.06)

    # 下止盈单
    def place_profit_order(self,direction, volume, lever_rate, offset, order_id_close,take_profit_price):
        # 止盈比率
        earn_rate = self.r.get(self.symbol + "_1min_" + "EARN_RATE")
        if earn_rate == None:
            earn_rate = 0.06
        else:
            earn_rate = float(earn_rate)
        if direction == "buy":
            direction = "sell"
            take_profit_price = math.floor(float(take_profit_price)*(earn_rate /20 + 1)*1000)/1000
        else:
            direction = "buy"
            take_profit_price = math.floor(float(take_profit_price)*(1-earn_rate /20 )*1000)/1000
        
        # 下止盈单
        print("止盈价格",take_profit_price)
        info = self.place_order(direction, volume, lever_rate, offset, order_id_close,take_profit_price)
        info["data"]["order_id"]
        # 止盈订单di
        self.r.set(self.symbol + "_EARN_ORDER_ID",info["data"]["order_id"])
    
    # 判断损益 大于-25%平仓
    def get_profit_rate(self):

        try:
            # click.clear()
            btc_hold = self.dm.get_contract_position_info(self.symbol)
            # 没有成交单 返回结果 {'status': 'ok', 'data': [], 'ts': 1580178512962}
            # 止盈单下好的标志
            profit_order_status = self.r.get(self.symbol + "_" + "1min" + "_TRIX_5_18_PROFIT_ORDER_DONE")
            if profit_order_status == None:
                profit_order_status = 0
            if len(btc_hold["data"]) == 0 and int(profit_order_status) == 1:
                self.defalut_radis_valuses()
                # 取消所有订单
                self.cancel_all_order()

                print("持仓和信号都变为0")
            else:
                print("持仓和信号不用变2")

            if "status" in btc_hold and btc_hold["status"] == 'ok' and len(btc_hold["data"]) > 0 :
                self.get_ticker()
                order_len = len(btc_hold["data"])
                
                order_info_positave = ''
                order_info_nagtive = ''
                order_info = ''
                self.coin_tag = 0
                balance = self.dm.get_contract_account_info()
                for index,i in enumerate(balance["data"]):
                    if i["symbol"] == self.symbol:
                        coin_info = i
                        self.coin_tag = index
                        break
                # print(btc_hold)
                for i in btc_hold["data"]:

                    # balance
                    # btc 余额
                    btc_balance = balance["data"][6]["margin_balance"]
                    profit_rate = i["profit_rate"]
                    # 未实现盈亏
                    profit_rate = i["profit_unreal"]
                    
                    # 收益存起来 给持仓中的反向单用
                    self.r.set(self.account + "_" +self.symbol + "_UNREAL_PROFIT",profit_rate)

                    # 持仓量
                    volume = int(i["volume"])
                    available = int(i["available"])
                    # available 可平仓数量
                    lever_rate = i["lever_rate"]
                    direction = i["direction"]
                    offset = "close"
                    order_id_close = int(self.get_order_id_lastet()) + 1
                    take_profit_price = i["cost_hold"]
                    print(take_profit_price)
                   
                    # ticker
                    self.get_ticker()
                    
                    self.price = 0
                    if direction == 'sell':
                        self.price = self.ticker_cq["bid"] + 0.1
                    else:
                        self.price = self.ticker_cq["ask"] - 0.1
                    
                    # 持仓数量
                    redis_hold_position = self.r.get(self.symbol + "_HOLD_POSITION_NUM")
                    if redis_hold_position == None:
                        redis_hold_position = 0

                    print("张数",volume,redis_hold_position,"available",available)
                    
                    reverse_flag =  self.r.get(self.symbol + "_" + "1min" + "_TRIX_5_18_REVERSE")
                    # 相反信号出现马上平仓
                    if reverse_flag != None and int(reverse_flag) == 1:
                        # 相反单信号出现 盈利下平仓
                        profit_order_id = self.r.get(self.symbol + "_EARN_ORDER_ID")

                        self.cancel_all_order()
                        time.sleep(2)
                        print(direction, volume, lever_rate, offset, order_id_close,self.price)
                        if direction == 'sell':
                            direction = 'buy'
                        else:
                            direction = 'sell'

                        if direction == 'sell':
                            self.price = self.ticker_cq["bid"] - 0.1
                        else:
                            self.price = self.ticker_cq["ask"] + 0.1

                        self.price = round(self.price,3)

                        info = self.close_order(direction, volume, lever_rate, offset, order_id_close,self.price)
                        print(info)
                        self.echo.alarm_with_tag("相反信号果断平仓","EXCEPTION")
                        time.sleep(10)
                        return
                        
                    # 有新单加入 重新生成止盈
                    if available > 0:

                        profit_order_id = self.r.get(self.symbol + "_EARN_ORDER_ID")
                        
                        if profit_order_id != None and int(profit_order_id) != 0 and volume > 19000:
                            self.cancel_single_order(profit_order_id)
                            time.sleep(2)
                            # 3000张加仓就 降低止盈
                            self.r.set(self.symbol + "_1min_" + "EARN_RATE",0.06)
                            self.echo.alarm_with_tag("3000张加仓就降低止盈","EXCEPTION")
                        elif profit_order_id != None and int(profit_order_id) != 0:
                            self.cancel_single_order(profit_order_id)

                        print("下止盈单",take_profit_price)
                        self.place_profit_order(direction, volume, lever_rate, offset, order_id_close,take_profit_price)
                        # 下单张数
                        self.r.set(self.symbol + "_HOLD_POSITION_NUM",volume)
                        
                        # 止盈单已经下好 标志
                        self.r.set(self.symbol + "_" + "1min" + "_TRIX_5_18_PROFIT_ORDER_DONE",1)
                        
                    else:
                        print("不用下止盈单")
                    

        except Exception as e:
            self.echo.alarm(str(e))
            print(e)

    def get_volume():
        result = dm.get_contract_position_info(symbol=self.symbol)
        print(result)

    def get_ticker(self):
        try:
            
            cw = self.dm.get_contract_market_merged(self.symbol+'_CW')
            self.ticker_cw["bid"] = cw["tick"]["bid"][0]
            self.ticker_cw["ask"] = cw["tick"]["ask"][0]
            self.ticker_cw["type"] = self.symbol+"_CW"
            self.ticker_cw_price = (cw["tick"]["bid"][0] + cw["tick"]["ask"][0])/2

            nw = self.dm.get_contract_market_merged(self.symbol+'_NW')
            self.ticker_nw["bid"] = nw["tick"]["bid"][0]
            self.ticker_nw["ask"] = nw["tick"]["ask"][0]
            self.ticker_nw["type"] = self.symbol+"_NW"
            self.ticker_nw_price = (nw["tick"]["bid"][0] + nw["tick"]["ask"][0])/2

            cq = self.dm.get_contract_market_merged(self.symbol+'_CQ')
            self.ticker_cq["bid"] = cq["tick"]["bid"][0]
            self.ticker_cq["ask"] = cq["tick"]["ask"][0]
            self.ticker_cq["type"] = self.symbol+"_CQ"
            self.ticker_cq_price = (cq["tick"]["bid"][0] + cq["tick"]["ask"][0])/2
            # print(self.ticker_cw)
        except Exception as e:
            print(e)


    def alarm(self,msg):
        # https://api.telegram.org/bot920560356:AAFBFHBquz9L-4-Rymrj8i_lHsCLEAfgvZQ/sendMessage?chat_id=652348565&text=test
        config_dict = {"telegram": {
    "token": "920560356:AAFBFHBquz9L-4-Rymrj8i_lHsCLEAfgvZQ", "chat_id": "652348565"}}
        # msg = str(msg)
        try:
            localtime = time.asctime(time.localtime(time.time()))
            msg = " %s" % (msg)
            url = "https://api.telegram.org/bot%s/sendMessage" % (
                config_dict["telegram"]["token"])
            param = {"chat_id": config_dict["telegram"]["chat_id"], "text": msg, }
            result = requests.get(url, param, timeout=20)
        except Exception as e:
            print('send_telegram_msg get exception:', e)

    def error_msg(self, code):
        # 错误代码 https://github.com/huobiapi/API_Docs/wiki/Resf_error_code_derivatives
        dic = {"403 ":"无效身份","1000":"系统异常","1001":"系统未准备就绪","1002":"查询异常","1003":"操作redis异常","1010":"用户不存在","1011":"用户会话不存在","1012":"用户账户不存在","1013":"合约品种不存在","1014":"合约不存在","1015":"指数价格不存在","1016":"对手价不存在","1017":"查询订单不存在","1030":"输入错误","1031":"非法的报单来源","1032":"访问次数超出限制","1033":"合约周期字段值错误","1034":"报单价格类型字段值错误","1035":"报单方向字段值错误","1036":"报单开平字段值错误","1037":"杠杆倍数不符合要求","1038":"报单价格不符合最小变动价","1039":"报单价格超出限制","1040":"报单数量不合法","1041":"报单数量超出限制","1042":"超出多头持仓限制","1043":"超出多头持仓限制","1044":"超出平台持仓限制","1045":"杠杆倍数与所持有仓位的杠杆不符合","1046":"持仓未初始化","1047":"可用保证金不足","1048":"持仓量不足","1050":"客户报单号重复","1051":"没有可撤订单","1052":"超出批量数目限制","1053":"无法获取合约的最新价格区间","1054":"无法获取合约的最新价","1055":"平仓时权益不足","1056":"结算中无法下单和撤单","1057":"暂停交易中无法下单和撤单","1058":"停牌中无法下单和撤单","1059":"交割中无法下单和撤单","1060":"此合约在非交易状态中，无法下单和撤单","1061":"订单不存在，无法撤单","1062":"撤单中，无法重复撤单","1063":"订单已成交，无法撤单","1064":"报单主键冲突","1065":"客户报单号不是整数","1066":"字段不能为空","1067":"字段不合法","1068":"导出错误","1069":"报单价格不合法","1100":"用户没有开仓权限","1101":"用户没有平仓权限","1102":"用户没有入金权限","1103":"用户没有出金权限","1104":"合约交易权限,当前禁止交易","1105":"合约交易权限,当前只能平仓","1200":"登录错误","1220":"用户尚未开通合约交易","1221":"开户资金不足","1222":"开户天数不足","1223":"开户VIP等级不足","1224":"开户国家限制","1225":"开户不成功","1250":"无法获取HT_token","1251":"BTC折合资产无法获取","1252":"现货资产无法获取","1077":"交割结算中，当前品种资金查询失败","1078":"交割结算中，部分品种资金查询失败","1079":"交割结算中，当前品种持仓查询失败","1080":"交割结算中，部分品种持仓查询失败"}
        if code in dic:
            m = self.account + " "+  dic[code]
            print(m)
            self.echo.alarm(m)
        else:
            self.echo.alarm(self.account + " : "+ code)
            print("请更新状态码:" + code)
    def has_hold_position_num(self):
        try:

            info = self.dm.get_contract_position_info(self.symbol)
            if "data" in info:
                if len(info["data"]) > 0:
                    self.hold_position = 0
                    # click.echo(click.style("获取用户用户持仓 %d"  % (info["data"][0]["available"]), fg='green'),nl=False)

                    # print(info)
                    for l in info["data"]:
                        self.hold_position = self.hold_position + l["available"]
                return len(info["data"]) > 0
            else:
                if "err_code" in info:
                    self.error_msg(str(info["err_code"]))
        except Exception as e:
            return 0
            print(e)
    def cancel_all_order(self):

        print (u' 批量全部撤单 ')
        info = self.dm.cancel_all_contract_order(symbol=self.symbol)
        print(info)
    def cancel_single_order(self, oid):

        print (u' 批量单个撤单 ')
        info = self.dm.cancel_contract_order(self.symbol,oid,"")
        print(info)
        
if __name__ == "__main__":

    accounts = ["DENG"]
    c = NewContract(accounts[0], "ETH")
    try:
       while True:
            
            hold_position = 0
            first_lauthed = False
            # 开启自动下单后 
            place_disable = c.r.get(c.symbol + "_" + "1min" + "_DISABLE_PLACE_ORDER")
            place_disable = 1
            if place_disable == None:
                pass
            elif int(place_disable) == 1:
                c.is_hold_position()
                c.get_profit_rate()
            time.sleep(10)

    except Exception as e:
        print(c.echo.alarm("NewControct:" + str(e)))
        print(str(e))

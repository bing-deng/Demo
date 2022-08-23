#!/bin/bash
# shadowsocks/ssä¸€é”®å®‰è£…è„šæœ¬
# Author: æ¢¯å­åšå®¢<https://tizi.blog>


RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

BASE=`pwd`
OS=`hostnamectl | grep -i system | cut -d: -f2`

NAME="shadowsocks-libev"
CONFIG_FILE="/etc/${NAME}/config.json"
SERVICE_FILE="/etc/systemd/system/${NAME}.service"

V6_PROXY=""
IP=`curl -sL -4 ip.sb`
if [[ "$?" != "0" ]]; then
    IP=`curl -sL -6 ip.sb`
    V6_PROXY="https://gh.hijk.art/"
fi

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

checkSystem() {
    result=$(id | awk '{print $1}')
    if [[ $result != "uid=0(root)" ]]; then
        colorEcho $RED " è¯·ä»¥rootèº«ä»½æ‰§è¡Œè¯¥è„šæœ¬"
        exit 1
    fi

    res=`which yum 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        res=`which apt 2>/dev/null`
        if [[ "$?" != "0" ]]; then
            colorEcho $RED " ä¸å—æ”¯æŒçš„Linuxç³»ç»Ÿ"
            exit 1
        fi
        PMT="apt"
        CMD_INSTALL="apt install -y "
        CMD_REMOVE="apt remove -y "
        CMD_UPGRADE="apt update; apt upgrade -y; apt autoremove -y"
    else
        PMT="yum"
        CMD_INSTALL="yum install -y "
        CMD_REMOVE="yum remove -y "
        CMD_UPGRADE="yum update -y"
    fi
    res=`which systemctl 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        colorEcho $RED " ç³»ç»Ÿç‰ˆæœ¬è¿‡ä½Žï¼Œè¯·å‡çº§åˆ°æœ€æ–°ç‰ˆæœ¬"
        exit 1
    fi
}

status() {
    export PATH=/usr/local/bin:$PATH
    cmd="$(command -v ss-server)"
    if [[ "$cmd" = "" ]]; then
        echo 0
        return
    fi
    if [[ ! -f $CONFIG_FILE ]]; then
        echo 1
        return
    fi
    port=`grep server_port $CONFIG_FILE|cut -d: -f2| tr -d \",' '`
    res=`ss -ntlp| grep ${port} | grep ss-server`
    if [[ -z "$res" ]]; then
        echo 2
    else
        echo 3
    fi
}

statusText() {
    res=`status`
    case $res in
        2)
            echo -e ${GREEN}å·²å®‰è£…${PLAIN} ${RED}æœªè¿è¡Œ${PLAIN}
            ;;
        3)
            echo -e ${GREEN}å·²å®‰è£…${PLAIN} ${GREEN}æ­£åœ¨è¿è¡Œ${PLAIN}
            ;;
        *)
            echo -e ${RED}æœªå®‰è£…${PLAIN}
            ;;
    esac
}

getData() {
    echo ""
    read -p " è¯·è®¾ç½®SSçš„å¯†ç ï¼ˆä¸è¾“å…¥åˆ™éšæœºç”Ÿæˆï¼‰:" PASSWORD
    [[ -z "$PASSWORD" ]] && PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1`
    echo ""
    colorEcho $BLUE " å¯†ç ï¼š $PASSWORD"

    echo ""
    while true
    do
        read -p " è¯·è®¾ç½®SSçš„ç«¯å£å·[1025-65535]:" PORT
        [[ -z "$PORT" ]] && PORT=`shuf -i1025-65000 -n1`
        if [[ "${PORT:0:1}" = "0" ]]; then
            echo -e " ${RED}ç«¯å£ä¸èƒ½ä»¥0å¼€å¤´${PLAIN}"
            exit 1
        fi
        expr $PORT + 0 &>/dev/null
        if [[ $? -eq 0 ]]; then
            if [[ $PORT -ge 1025 ]] && [[ $PORT -le 65535 ]]; then
                echo ""
                colorEcho $BLUE " ç«¯å£å·ï¼š $PORT"
                echo ""
                break
            else
                colorEcho $RED " è¾“å…¥é”™è¯¯ï¼Œç«¯å£å·ä¸º1025-65535çš„æ•°å­—"
            fi
        else
            colorEcho $RED " è¾“å…¥é”™è¯¯ï¼Œç«¯å£å·ä¸º1025-65535çš„æ•°å­—"
        fi
    done
    colorEcho $RED " è¯·é€‰æ‹©åŠ å¯†æ–¹å¼:" 
    echo "  1)aes-256-gcm"
    echo "  2)aes-192-gcm"
    echo "  3)aes-128-gcm"
    echo "  4)aes-256-ctr"
    echo "  5)aes-192-ctr"
    echo "  6)aes-128-ctr"
    echo "  7)aes-256-cfb"
    echo "  8)aes-192-cfb"
    echo "  9)aes-128-cfb"
    echo "  10)camellia-128-cfb"
    echo "  11)camellia-192-cfb"
    echo "  12)camellia-256-cfb"
    echo "  13)chacha20-ietf"
    echo "  14)chacha20-ietf-poly1305"
    echo "  15)xchacha20-ietf-poly1305"
    read -p " è¯·é€‰æ‹©ï¼ˆé»˜è®¤aes-256-gcmï¼‰" answer
    if [[ -z "$answer" ]]; then
        METHOD="aes-256-gcm"
    else
        case $answer in
        1)
            METHOD="aes-256-gcm"
            ;;
        2)
            METHOD="aes-192-gcm"
            ;;
        3)
            METHOD="aes-128-gcm"
            ;;
        4)
            METHOD="aes-256-ctr"
            ;;
        5)
            METHOD="aes-192-ctr"
            ;;
        6)
            METHOD="aes-128-ctr"
            ;;
        7)
            METHOD="aes-256-cfb"
            ;;
        8)
            METHOD="aes-192-cfb"
            ;;
        9)
            METHOD="aes-128-cfb"
            ;;
        10)
            METHOD="camellia-128-cfb"
            ;;
        11)
            METHOD="camellia-192-cfb"
            ;;
        12)
            METHOD="camellia-256-cfb"
            ;;
        13)
            METHOD="chacha20-ietf"
            ;;
        14)
            METHOD="chacha20-ietf-poly1305"
            ;;
        15)
            METHOD="xchacha20-ietf-poly1305"
            ;;
        *)
            colorEcho $RED " æ— æ•ˆçš„é€‰æ‹©ï¼Œä½¿ç”¨é»˜è®¤çš„aes-256-gcm"
            METHOD="aes-256-gcm"
        esac
    fi
    echo ""
    colorEcho $BLUE "åŠ å¯†æ–¹å¼ï¼š $METHOD"
}

preinstall() {
    $PMT clean all
    #echo $CMD_UPGRADE | bash
    [[ "$PMT" = "apt" ]] && $PMT update

    echo ""
    colorEcho $BULE " å®‰è£…å¿…è¦è½¯ä»¶"
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL epel-release
    fi
    $CMD_INSTALL wget vim net-tools unzip tar qrencode
    $CMD_INSTALL openssl gettext gcc autoconf libtool automake make asciidoc xmlto
    if [[ "$PMT" = "yum" ]]; then
        $CMD_INSTALL openssl-devel udns-devel libev-devel pcre pcre-devel mbedtls mbedtls-devel libsodium libsodium-devel c-ares c-ares-devel
    else
        $CMD_INSTALL libssl-dev libudns-dev libev-dev libpcre3 libpcre3-dev libmbedtls-dev libc-ares2 libc-ares-dev g++
        $CMD_INSTALL libsodium*
    fi
    res=`which wget 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL wget
    res=`which netstat 2>/dev/null`
    [[ "$?" != "0" ]] && $CMD_INSTALL net-tools

    if [[ -s /etc/selinux/config ]] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "${1:1}"
            ;;
            *)
                echo "$1"
            ;;
        esac
    else
        echo ""
    fi
}

installNewVer() {
    new_ver=$1
    if ! wget "${V6_PROXY}https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${new_ver}/shadowsocks-libev-${new_ver}.tar.gz" -O ${NAME}.tar.gz; then
        colorEcho $RED " ä¸‹è½½å®‰è£…æ–‡ä»¶å¤±è´¥ï¼"
        exit 1
    fi
    tar zxf ${NAME}.tar.gz
    cd shadowsocks-libev-${new_ver}
    ./configure
    make && make install
    if [[ $? -ne 0 ]]; then
        echo
        echo -e " [${RED}é”™è¯¯${PLAIN}]: $OS Shadowsocks-libev å®‰è£…å¤±è´¥ï¼ è¯·æ‰“å¼€ https://tizi.blog åé¦ˆ"
        cd ${BASE} && rm -rf shadowsocks-libev*
        exit 1
    fi
    ssPath=`which ss-server 2>/dev/null`
    [[ "$ssPath" != "" ]] || {
        cd ${BASE} && rm -rf shadowsocks-libev*
        colorEcho $RED " SSå®‰è£…å¤±è´¥ï¼Œè¯·åˆ° https://tizi.blog åé¦ˆ"
        exit 1
    }
    cat > $SERVICE_FILE <<-EOF
[Unit]
Description=shadowsocks
Documentation=https://tizi.blog
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
PIDFile=/var/run/${NAME}.pid
LimitNOFILE=32768
ExecStart=$ssPath -c $CONFIG_FILE -f /var/run/${NAME}.pid
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s TERM \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable ${NAME}
    cd ${BASE} && rm -rf shadowsocks-libev*

    colorEcho $BLUE " å®‰è£…æˆåŠŸ!"
}

installSS() {
    echo ""
    colorEcho $BLUE " å®‰è£…æœ€æ–°ç‰ˆSS..."

    tag_url="${V6_PROXY}https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest"
    new_ver="$(normalizeVersion "$(curl -s "${tag_url}" --connect-timeout 10| grep 'tag_name' | cut -d\" -f4)")"
    export PATH=/usr/local/bin:$PATH
    ssPath=`which ss-server 2>/dev/null`
    if [[ "$?" != "0" ]]; then
        [[ "$new_ver" != "" ]] || new_ver="3.3.5"
        installNewVer $new_ver
    else
        ver=`ss-server -h | grep ${NAME} | grep -oE '[0-9+\.]+'`
        if [[ $ver != $new_ver ]]; then
            installNewVer $new_ver
        else
            colorEcho $YELLOW " å·²å®‰è£…æœ€æ–°ç‰ˆSS"
        fi
    fi
}

configSS(){
    interface="0.0.0.0"
    if [[ "$V6_PROXY" != "" ]]; then
        interface="::"
    fi

    mkdir -p /etc/${NAME}
    cat > $CONFIG_FILE<<-EOF
{
    "server":"$interface",
    "server_port":${PORT},
    "local_port":1080,
    "password":"${PASSWORD}",
    "timeout":600,
    "method":"${METHOD}",
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "fast_open":false
}
EOF
}

installBBR() {
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBRæ¨¡å—å·²å®‰è£…"
        INSTALL_BBR=false
        return
    fi
    res=`hostnamectl | grep -i openvz`
    if [ "$res" != "" ]; then
        colorEcho $YELLOW " openvzæœºå™¨ï¼Œè·³è¿‡å®‰è£…"
        INSTALL_BBR=false
        return
    fi
    
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    result=$(lsmod | grep bbr)
    if [[ "$result" != "" ]]; then
        colorEcho $GREEN " BBRæ¨¡å—å·²å¯ç”¨"
        INSTALL_BBR=false
        return
    fi

    echo ""
    colorEcho $BLUE " å®‰è£…BBRæ¨¡å—..."
    if [[ "$PMT" = "yum" ]]; then
        if [[ "${V6_PROXY}" = "" ]]; then
            rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
            rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
            $CMD_INSTALL --enablerepo=elrepo-kernel kernel-ml
            $CMD_REMOVE kernel-3.*
            grub2-set-default 0
            echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
            INSTALL_BBR=true
        fi
    else
        $CMD_INSTALL --install-recommends linux-generic-hwe-16.04
        grub-set-default 0
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        INSTALL_BBR=true
    fi
}

setFirewall() {
    res=`which firewall-cmd 2>/dev/null`
    if [[ $? -eq 0 ]]; then
        systemctl status firewalld > /dev/null 2>&1
        if [[ $? -eq 0 ]];then
            firewall-cmd --permanent --add-port=${PORT}/tcp
            firewall-cmd --permanent --add-port=${PORT}/udp
            firewall-cmd --reload
        else
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        fi
    else
        res=`which iptables 2>/dev/null`
        if [[ $? -eq 0 ]]; then
            nl=`iptables -nL | nl | grep FORWARD | awk '{print $1}'`
            if [[ "$nl" != "3" ]]; then
                iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT
                iptables -I INPUT -p udp --dport ${PORT} -j ACCEPT
            fi
        else
            res=`which ufw 2>/dev/null`
            if [[ $? -eq 0 ]]; then
                res=`ufw status | grep -i inactive`
                if [[ "$res" = "" ]]; then
                    ufw allow ${PORT}/tcp
                    ufw allow ${PORT}/udp
                fi
            fi
        fi
    fi
}

showInfo() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi

    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep 'ss-server'`
    [[ -z "$res" ]] && status="${RED}å·²åœæ­¢${PLAIN}" || status="${GREEN}æ­£åœ¨è¿è¡Œ${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    res=`echo -n "${method}:${password}@${IP}:${port}" | base64 -w 0`
    link="ss://${res}"

    echo ============================================
    echo -e " ${BLUE}ssè¿è¡ŒçŠ¶æ€${PLAIN}ï¼š${status}"
    echo -e " ${BLUE}ssé…ç½®æ–‡ä»¶ï¼š${PLAIN}${RED}$CONFIG_FILE${PLAIN}"
    echo ""
    echo -e " ${RED}ssé…ç½®ä¿¡æ¯ï¼š${PLAIN}"
    echo -e "  ${BLUE}IP(address):${PLAIN}  ${RED}${IP}${PLAIN}"
    echo -e "  ${BLUE}ç«¯å£(port)ï¼š${PLAIN}${RED}${port}${PLAIN}"
    echo -e "  ${BLUE}å¯†ç (password)ï¼š${PLAIN}${RED}${password}${PLAIN}"
    echo -e "  ${BLUE}åŠ å¯†æ–¹å¼(method)ï¼š${PLAIN} ${RED}${method}${PLAIN}"
    echo
    echo -e " ${BLUE}ssé“¾æŽ¥${PLAIN}ï¼š ${link}"
    #qrencode -o - -t utf8 ${link}
}

showQR() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi

    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`netstat -nltp | grep ${port} | grep 'ss-server'`
    [[ -z "$res" ]] && status="${RED}å·²åœæ­¢${PLAIN}" || status="${GREEN}æ­£åœ¨è¿è¡Œ${PLAIN}"
    password=`grep password $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    method=`grep method $CONFIG_FILE| cut -d: -f2 | tr -d \",' '`
    
    res=`echo -n "${method}:${password}@${IP}:${port}" | base64 -w 0`
    link="ss://${res}"
    qrencode -o - -t utf8 ${link}
}

function bbrReboot() {
    if [ "${INSTALL_BBR}" == "true" ]; then
        echo  
        colorEcho $BLUE " ä¸ºä½¿BBRæ¨¡å—ç”Ÿæ•ˆï¼Œç³»ç»Ÿå°†åœ¨30ç§’åŽé‡å¯"
        echo  
        echo -e " æ‚¨å¯ä»¥æŒ‰ ctrl + c å–æ¶ˆé‡å¯ï¼Œç¨åŽè¾“å…¥ ${RED}reboot${PLAIN} é‡å¯ç³»ç»Ÿ"
        sleep 30
        reboot
    fi
}

install() {
    getData

    preinstall
    installSS
    configSS
    installBBR
    setFirewall

    start
    showInfo

    bbrReboot
}

reconfig() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi
    getData
    configSS
    restart
    setFirewall

    showInfo
}

update() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi
    installSS
    restart
}

start() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi
    systemctl restart ${NAME}
    sleep 2
    port=`grep server_port $CONFIG_FILE | cut -d: -f2 | tr -d \",' '`
    res=`ss -nltp | grep ${port} | grep ss-server`
    if [[ "$res" = "" ]]; then
        colorEcho $RED " SSå¯åŠ¨å¤±è´¥ï¼Œè¯·æ£€æŸ¥ç«¯å£æ˜¯å¦è¢«å ç”¨ï¼"
    else
        colorEcho $BLUE " SSå¯åŠ¨æˆåŠŸï¼"
    fi
}

restart() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi

    stop
    start
}

stop() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi
    systemctl stop ${NAME}
    colorEcho $BLUE " SSåœæ­¢æˆåŠŸ"
}

uninstall() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi

    echo ""
    read -p " ç¡®å®šå¸è½½SSå—ï¼Ÿ(y/n)" answer
    [[ -z ${answer} ]] && answer="n"

    if [[ "${answer}" == "y" ]] || [[ "${answer}" == "Y" ]]; then
        systemctl stop ${NAME} && systemctl disable ${NAME}
        rm -rf $SERVICE_FILE
        cd /usr/local/bin && rm -rf ss-local ss-manager ss-nat ss-redir ss-server ss-tunnel
        rm -rf /usr/lib64/libshadowsocks-libev*
        rm -rf /usr/share/doc/shadowsocks-libev*
        rm -rf /usr/share/man/man1/ss-*.gz
        rm -rf /usr/share/man/man8/shadowsocks-libev*
        colorEcho $GREEN " SSå¸è½½æˆåŠŸ"
    fi
}

showLog() {
    res=`status`
    if [[ $res -lt 2 ]]; then
        echo -e " ${RED}SSæœªå®‰è£…ï¼Œè¯·å…ˆå®‰è£…ï¼${PLAIN}"
        return
    fi
    journalctl -xen --no-pager -u ${NAME}
}

menu() {
    clear
    echo "#############################################################"
    echo -e "#              ${RED}Shadowsocks/SS ä¸€é”®å®‰è£…è„šæœ¬${PLAIN}                #"
    echo -e "# ${GREEN}ä½œè€…${PLAIN}: æ¢¯å­åšå®¢                                        #"
    echo -e "# ${GREEN}ç½‘å€${PLAIN}: https://tizi.blog                                    #"
    echo -e "# ${GREEN}è®ºå›${PLAIN}: https://tizi.blog                                   #"
    echo "#############################################################"
    echo ""

    echo -e "  ${GREEN}1.${PLAIN}  å®‰è£…SS"
    echo -e "  ${GREEN}2.${PLAIN}  æ›´æ–°SS"
    echo -e "  ${GREEN}3.  ${RED}å¸è½½SS${PLAIN}"
    echo " -------------"
    echo -e "  ${GREEN}4.${PLAIN}  å¯åŠ¨SS"
    echo -e "  ${GREEN}5.${PLAIN}  é‡å¯SS"
    echo -e "  ${GREEN}6.${PLAIN}  åœæ­¢SS"
    echo " -------------"
    echo -e "  ${GREEN}7.${PLAIN}  æŸ¥çœ‹SSé…ç½®"
    echo -e "  ${GREEN}8.${PLAIN}  æŸ¥çœ‹é…ç½®äºŒç»´ç "
    echo -e "  ${GREEN}9.  ${RED}ä¿®æ”¹SSé…ç½®${PLAIN}"
    echo -e "  ${GREEN}10.${PLAIN} æŸ¥çœ‹SSæ—¥å¿—"
    echo " -------------"
    echo -e "  ${GREEN}0.${PLAIN} é€€å‡º"
    echo 
    echo -n " å½“å‰çŠ¶æ€ï¼š"
    statusText
    echo 

    read -p " è¯·é€‰æ‹©æ“ä½œ[0-10]ï¼š" answer
    case $answer in
        0)
            exit 0
            ;;
        1)
            install
            ;;
        2)
            update
            ;;
        3)
            uninstall
            ;;
        4)
            start
            ;;
        5)
            restart
            ;;
        6)
            stop
            ;;
        7)
            showInfo
            ;;
        8)
            showQR
            ;;
        9)
            reconfig
            ;;
        10)
            showLog
            ;;
        *)
            echo -e "$RED è¯·é€‰æ‹©æ­£ç¡®çš„æ“ä½œï¼${PLAIN}"
            exit 1
            ;;
    esac
}

checkSystem

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
    menu|install|update|uninstall|start|restart|stop|showInfo|showQR|showLog)
        ${action}
        ;;
    *)
        echo " å‚æ•°é”™è¯¯"
        echo " ç”¨æ³•: `basename $0` [menu|install|update|uninstall|start|restart|stop|showInfo|showQR|showLog]"
        ;;
esac

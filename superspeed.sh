#!/usr/bin/env bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE="\033[0;35m"
CYAN='\033[0;36m'
PLAIN='\033[0m'

checkroot(){
	[[ $EUID -ne 0 ]] && echo -e "${RED}请使用 root 用户运行本脚本！${PLAIN}" && exit 1
}

checksystem() {
	if [ -f /etc/redhat-release ]; then
	    release="centos"
	elif cat /etc/issue | grep -Eqi "debian"; then
	    release="debian"
	elif cat /etc/issue | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	elif cat /proc/version | grep -Eqi "debian"; then
	    release="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
	    release="ubuntu"
	elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
	    release="centos"
	else
	    if command -v apt-get > /dev/null 2>&1; then
	        release="debian"
	    elif command -v yum > /dev/null 2>&1; then
	        release="centos"
	    else
	        echo -e "${RED}不支持的系统，脚本可能无法正常工作${PLAIN}"
	        release="unknown"
	    fi
	fi
}

checkpython() {
	if  [ ! -e '/usr/bin/python3' ]; then
		echo "正在安装 Python3"
		if [ "${release}" == "centos" ]; then
			yum update > /dev/null 2>&1
			yum -y install python3 > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install python3 > /dev/null 2>&1
		fi
	fi
}

checkcurl() {
	if  [ ! -e '/usr/bin/curl' ]; then
		echo "正在安装 Curl"
		if [ "${release}" == "centos" ]; then
			yum update > /dev/null 2>&1
			yum -y install curl > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install curl > /dev/null 2>&1
		fi
	fi
}

checkwget() {
	if  [ ! -e '/usr/bin/wget' ]; then
		echo "正在安装 Wget"
		if [ "${release}" == "centos" ]; then
			yum update > /dev/null 2>&1
			yum -y install wget > /dev/null 2>&1
		else
			apt-get update > /dev/null 2>&1
			apt-get -y install wget > /dev/null 2>&1
		fi
	fi
}

checkspeedtest() {
	if  [ ! -e './speedtest-cli/speedtest' ]; then
		echo "正在安装 Speedtest-cli"
		mkdir -p speedtest-cli
		case $(uname -m) in
			i?86) arch="i386" ;;
			x86_64) arch="x86_64" ;;
			armv5*) arch="armel" ;;
			armv6*|armv7*) arch="armhf" ;;
			aarch64) arch="aarch64" ;;
			*) arch="x86_64" ;;
		esac
		wget --no-check-certificate -qO speedtest.tgz "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${arch}.tgz"
		tar zxvf speedtest.tgz -C ./speedtest-cli/ > /dev/null 2>&1 && chmod a+rx ./speedtest-cli/speedtest
	fi
}

speed_test(){
	speedLog="./speedtest.log"
	log="./superspeed.log"
	true > "$speedLog"
	speedtest-cli/speedtest -p no -s "$1" --accept-license --accept-gdpr > "$speedLog" 2>&1
	is_upload=$(cat "$speedLog" | grep 'Upload')
	if [[ ${is_upload} ]]; then
		local REDownload=$(cat "$speedLog" | awk -F ' ' '/Download/{print $3}')
		local reupload=$(cat "$speedLog" | awk -F ' ' '/Upload/{print $3}')
		local relatency=$(cat "$speedLog" | grep 'Latency:' | awk -F 'Latency: ' '{print $2}' | awk -F ' ' '{print $1}' | tr -d 'ms' | tr -d ',')
		
		local nodeID=$1
		local nodeLocation=$2
		local nodeISP=$3
		
		strnodeLocation="${nodeLocation}　　　　　　"
		
		temp=$(echo "${REDownload}" | LANG=C awk -F ' ' '{print $1}')
		if [[ $(awk -v num1="${temp}" -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
			printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${CYAN}%s%-10s${BLUE}%s%-10s${PURPLE}%-8s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "↑ " "${reupload}" "↓ " "${REDownload}" "${relatency}" | tee -a "$log"
		else
			printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${RED}%-20s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "[ERROR] Speed test failed" | tee -a "$log"
		fi
	else
		local nodeID=$1
		local nodeLocation=$2
		local nodeISP=$3
		strnodeLocation="${nodeLocation}　　　　　　"
		printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${RED}%-20s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "[ERROR] Connection failed" | tee -a "$log"
	fi
}

show_result() {
	echo "——————————————————————————————————————————————————————————"
	if [[ $time -gt 60 ]]; then
		min=$(expr $time / 60)
		sec=$(expr $time % 60)
		echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
	else
		echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
	fi
	echo -ne "\n  当前时间: "
	echo $(date +%Y-%m-%d" "%H:%M:%S)
}

preinfo() {
	echo "———————————————————SuperSpeed 全面测速版———————————————————"
	echo "       作者:  hello-yunshu"
	echo "       项目:  https://github.com/hello-yunshu"
	echo "       节点更新: 2026/04/24  | 脚本更新: 2026/04/24"
	echo "       ${RED}注意: 请勿频繁测试，避免被限制！${PLAIN}"
	echo "——————————————————————————————————————————————————————————"
}

selecttest() {
	echo -e "  测速类型:    ${GREEN}1.${PLAIN}  三网测速    ${GREEN}2.${PLAIN}  电信节点    ${GREEN}3.${PLAIN}  联通节点"
	echo -ne "               ${GREEN}4.${PLAIN}  移动节点    ${GREEN}5.${PLAIN}  取消测速    ${GREEN}6.${PLAIN}  清理下载文件"
	while :; do echo
			read -p "  请输入数字选择测速类型: " selection
			if [[ ! $selection =~ ^[1-6]$ ]]; then
					echo -ne "  ${RED}输入错误${PLAIN}, 请输入正确的数字!"
			else
					break   
			fi
	done
}

runtest() {
	[[ ${selection} == 5 ]] && exit 1

	if [[ ${selection} == 1 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '5396' '江苏苏州５Ｇ' '电信'
	 speed_test '36663' '江苏镇江５Ｇ' '电信'
	 speed_test '59387' '浙江宁波' '电信'
	 speed_test '7509' '浙江杭州' '电信'
	 speed_test '3973' '甘肃兰州' '电信'
	 speed_test '6592' '重庆' '电信'
	 speed_test '4624' '四川成都' '电信'
	 speed_test '5274' '江苏苏州' '电信'
	 speed_test '4433' '安徽合肥' '电信'
	 speed_test '6345' '江西南昌' '电信'
	 speed_test '4595' '河南郑州' '电信'
	 speed_test '4672' '广东广州' '电信'
	 speed_test '5081' '广东深圳' '电信'
		#***
		 speed_test '24447' '上海５Ｇ' '联通'
		 speed_test '43752' '北京' '联通'
		 speed_test '5145' '北京' '联通'
		 speed_test '2461' '四川成都' '联通'
		 speed_test '4870' '湖南长沙' '联通'
		 speed_test '5039' '山东济南' '联通'
		 speed_test '5724' '安徽合肥' '联通'
		 speed_test '6245' '浙江宁波' '联通'
		 speed_test '5300' '浙江杭州' '联通'
		 speed_test '5485' '湖北武汉' '联通'
		 speed_test '4863' '陕西西安' '联通'
		 speed_test '5509' '宁夏银川' '联通'
		 speed_test '5103' '云南昆明' '联通'
		#***
		 speed_test '4665' '上海' '移动'
		 speed_test '25858' '北京' '移动'
		 speed_test '4713' '北京' '移动'
		 speed_test '3927' '江苏苏州' '移动'
		 speed_test '5122' '江苏无锡' '移动'
		 speed_test '6715' '浙江宁波' '移动'
		 speed_test '4647' '浙江杭州' '移动'
		 speed_test '4377' '安徽合肥' '移动'
		 speed_test '4486' '河南郑州' '移动'
		 speed_test '4575' '四川成都' '移动'
		 speed_test '4672' '广东广州' '移动'
		 speed_test '4515' '广东深圳' '移动'
		 speed_test '4525' '黑龙江哈尔滨' '移动'
		 speed_test '4504' '甘肃兰州' '移动'

		end=$(date +%s)  
		rm -f speedtest.tgz speedtest.log && rm -rf speedtest-cli
		time=$(( $end - $start ))
		show_result
		echo -e "  ${GREEN}# 三网测速中为避免节点数不均及测试过久，每部分未使用所${PLAIN}"
		echo -e "  ${GREEN}# 有节点，如果需要使用全部节点，可分别选择三网节点检测${PLAIN}"
	fi

	if [[ ${selection} == 2 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '5396' '江苏苏州５Ｇ' '电信'
	 speed_test '36663' '江苏镇江５Ｇ' '电信'
	 speed_test '59387' '浙江宁波' '电信'
	 speed_test '7509' '浙江杭州' '电信'
	 speed_test '3973' '甘肃兰州' '电信'
	 speed_test '6592' '重庆' '电信'
	 speed_test '4624' '四川成都' '电信'
	 speed_test '5274' '江苏苏州' '电信'
	 speed_test '4433' '安徽合肥' '电信'
	 speed_test '6345' '江西南昌' '电信'
	 speed_test '4595' '河南郑州' '电信'
	 speed_test '4672' '广东广州' '电信'
	 speed_test '5081' '广东深圳' '电信'
	 speed_test '4589' '北京' '电信'
	 speed_test '4751' '北京' '电信'
	 speed_test '6714' '天津' '电信'
	 speed_test '6132' '湖南长沙' '电信'
	 speed_test '6435' '湖北襄阳' '电信'
	 speed_test '5674' '广西南宁' '电信'

		end=$(date +%s)  
		rm -f speedtest.tgz speedtest.log && rm -rf speedtest-cli
		time=$(( $end - $start ))
		show_result
	fi

	if [[ ${selection} == 3 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '24447' '上海５Ｇ' '联通'
		 speed_test '43752' '北京' '联通'
		 speed_test '5145' '北京' '联通'
		 speed_test '5475' '天津' '联通'
		 speed_test '2461' '四川成都' '联通'
		 speed_test '5726' '重庆' '联通'
		 speed_test '4870' '湖南长沙' '联通'
		 speed_test '5039' '山东济南' '联通'
		 speed_test '5724' '安徽合肥' '联通'
		 speed_test '6245' '浙江宁波' '联通'
		 speed_test '5300' '浙江杭州' '联通'
		 speed_test '5485' '湖北武汉' '联通'
		 speed_test '4863' '陕西西安' '联通'
		 speed_test '5509' '宁夏银川' '联通'
		 speed_test '5103' '云南昆明' '联通'
		 speed_test '4884' '福建福州' '联通'
		 speed_test '5506' '福建厦门' '联通'
		 speed_test '5017' '辽宁沈阳' '联通'
		 speed_test '9484' '吉林长春' '联通'
		 speed_test '5460' '黑龙江哈尔滨' '联通'
		 speed_test '5985' '海南海口' '联通'
		 speed_test '4690' '甘肃兰州' '联通'
		 speed_test '5674' '广西南宁' '联通'
		 speed_test '16192' '广东深圳' '联通'
		 speed_test '26678' '广东广州５Ｇ' '联通'
		 speed_test '13704' '江苏南京' '联通'

		end=$(date +%s)  
		rm -f speedtest.tgz speedtest.log && rm -rf speedtest-cli
		time=$(( $end - $start ))
		show_result
	fi

	if [[ ${selection} == 4 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '4665' '上海' '移动'
		 speed_test '25858' '北京' '移动'
		 speed_test '4713' '北京' '移动'
		 speed_test '17184' '天津５Ｇ' '移动'
		 speed_test '3927' '江苏苏州' '移动'
		 speed_test '5122' '江苏无锡' '移动'
		 speed_test '6715' '浙江宁波' '移动'
		 speed_test '4647' '浙江杭州' '移动'
		 speed_test '4377' '安徽合肥' '移动'
		 speed_test '4486' '河南郑州' '移动'
		 speed_test '4575' '四川成都' '移动'
		 speed_test '17584' '重庆' '移动'
		 speed_test '4672' '广东广州' '移动'
		 speed_test '4515' '广东深圳' '移动'
		 speed_test '4525' '黑龙江哈尔滨' '移动'
		 speed_test '4504' '甘肃兰州' '移动'
		 speed_test '16375' '吉林长春' '移动'
		 speed_test '25728' '辽宁大连' '移动'
		 speed_test '16167' '辽宁沈阳' '移动'
		 speed_test '16171' '福建福州' '移动'
		 speed_test '16398' '贵州贵阳' '移动'
		 speed_test '16503' '海南海口' '移动'
		 speed_test '15863' '广西南宁' '移动'
		 speed_test '26728' '云南昆明' '移动'
		 speed_test '18444' '西藏拉萨' '移动'
		 speed_test '26380' '陕西西安' '移动'
		 speed_test '29083' '青海西宁５Ｇ' '移动'
		 speed_test '26940' '宁夏银川' '移动'
		 speed_test '31815' '宁夏银川' '移动'
		 speed_test '16858' '新疆乌鲁木齐' '移动'
		 speed_test '27019' '内蒙古呼和浩特' '移动'
		 speed_test '30232' '内蒙呼和浩特５Ｇ' '移动'
		 speed_test '30293' '内蒙古通辽５Ｇ' '移动'
		 speed_test '17223' '河北石家庄' '移动'
		 speed_test '26501' '山西太原５Ｇ' '移动'
		 speed_test '25881' '山东济南５Ｇ' '移动'
		 speed_test '27100' '山东青岛５Ｇ' '移动'
		 speed_test '27151' '山东临沂５Ｇ' '移动'
		 speed_test '24337' '四川成都' '移动'
		 speed_test '27249' '江苏南京５Ｇ' '移动'
		 speed_test '21845' '江苏常州５Ｇ' '移动'
		 speed_test '26850' '江苏无锡５Ｇ' '移动'
		 speed_test '17320' '江苏镇江５Ｇ' '移动'
		 speed_test '26404' '安徽合肥５Ｇ' '移动'
		 speed_test '25883' '江西南昌５Ｇ' '移动'
		 speed_test '28491' '湖南长沙５Ｇ' '移动'
		 speed_test '26331' '河南郑州５Ｇ' '移动'
		 speed_test '16145' '甘肃兰州' '移动'
		 speed_test '29105' '陕西西安５Ｇ' '移动'
		 speed_test '26656' '黑龙江哈尔滨' '移动'
		 speed_test '31520' '广东中山' '移动'
		 speed_test '6611' '广东广州' '移动'
		 speed_test '26938' '新疆乌鲁木齐５Ｇ' '移动'
		 speed_test '17227' '新疆和田' '移动'
		 speed_test '17245' '新疆喀什' '移动'
		 speed_test '17222' '新疆阿勒泰' '移动'
		 speed_test '25637' '上海５Ｇ' '移动'

		end=$(date +%s)  
		rm -f speedtest.tgz speedtest.log && rm -rf speedtest-cli
		time=$(( $end - $start ))
		show_result
	fi

	if [[ ${selection} == 6 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "  正在清理下载文件..."
		rm -f speedtest.tgz speedtest.log && rm -rf speedtest-cli
		rm -f ./superspeed.log
		echo -e "  ${GREEN}清理完成！${PLAIN}"
		echo "——————————————————————————————————————————————————————————"
	fi
}

runall() {
	checkroot;
	checksystem;
	checkpython;
	checkcurl;
	checkwget;
	checkspeedtest;
	clear
	preinfo;
	selecttest;
	runtest;
}

runall


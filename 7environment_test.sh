#!/bin/bash
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#yum源的检测函数
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#第一种情况,光盘未挂载,检测yum源可用情况,搭载网络yum源
function yum_build(){
echo -e "\e[1m正在检测您当前的\e[96myum源\e[0m\e[1m可用情况\n这可能需要\e[91m几十秒\e[0m\e[1m请耐心等待..\e[0m"
    [ -d /media/cdrom ] || mkdir -p /media/cdrom
    umount /dev/sr0 &> /dev/null
    mount /dev/sr0 /media/cdrom &> /dev/null
    if [ $? -ne 0 ];then
		echo -e "\e[1m当前光盘\e[91m未挂载\e[0m\e[1m,正在寻求其他解决方案..\e[0m"
		if [ -n $(rpm -qa | grep "^zip") ];then
	    	rpm -e zip  &>/dev/null
		fi
		yum -y install zip &>/dev/null
		if [ $? -eq 0 ];then
	    	return 0
		fi
		echo -e "\e[1m当前yum源不可用,正在为您组建\e[96m网络yum源\e[0m\e[1m,这可能需要一段时间,请稍等..\e[0m"
	    	if [ -z "$(rpm -qa | grep wget)" ];then
				if [ -z "$(which curl)" ];then
					echo -e "\e[1m当前系统中\e[96mwget|curl\e[0m\e[1m不存在,yum源检测失败\e[0m"
					return 1
	    		fi
			fi
			ping -c 2 -w 0.3 www.baidu.com &> /dev/null
			if [ $? -ne 0 ];then
		    	echo -e "\e[1m当前网络连接\e[91m异常！\e[0m"
		    	return 1
			fi
		echo -e "\e[1m当前网络\e[92m通畅\e[0m\e[1m,开始组建网络yum源..\e[0m"
			[ -d /etc/yum.repos.d ] || mkdir -p /etc/yum.repos.d
			mv -f /etc/yum.repos.d/* /tmp

		wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
		if [ $? -ne 0 ];then
			curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
		fi
	    echo -e "\e[1m正在清理缓存..\e[0m"
	    yum clean all &> /dev/null
	    echo -e "\e[1m正在重建缓存..\e[0m"
	    yum makecache 
		if [ -n $(rpm -qa | grep "^zip") ];then
		    rpm -e zip &>/dev/null
		fi
		yum -y install zip &> /dev/null
		if [ $? -eq 0 ];then
		    return 0
		else
		    echo -e "\e[96m网络yum源\e[0m\e[1m搭建过程发生错误,请重试或重启虚拟机\e[0m"
		    return 1
		fi
	fi
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#第二种情况,光盘挂载，检测yum是否可用，搭载本地yum源
	echo -e "\e[1m当前光盘\e[96m已挂载\e[0m\e[1m,下一步检测进行\e[0m"
	    if [ -n $(rpm -qa | grep "^zip") ];then
			rpm -e zip &>/dev/null
	    fi
	    yum -y install zip &> /dev/null
	    if [ $? -eq 0 ];then
			return 0
	    fi
	[ -d /etc/yum.repos.d ] || mkdir -p /etc/yum.repos.d
	mv -f /etc/yum.repos.d/* /tmp &> /dev/null
	cat >> /etc/yum.repos.d/local.repo << END
[local]
name=localyum
gpgcheck=0
enable=1
baseurl=file:///media/cdrom
END
	yum clean all &> /dev/null
	yum makecache &> /dev/null
	if [ -n $(rpm -qa | grep "^zip") ];then
	    rpm -e zip &>/dev/null
	fi
	yum -y install zip &> /dev/null
	if [ $? -eq 0 ];then
	    return 0
	fi
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#第三种情况,mount挂载成功但是本地yum未搭建成功,检测wget和ping网络
	echo -e "\e[1m检测到当前光盘\e[96m已挂载\e[0m\e[1m,但\e[96m本地yum源\e[91m部署失败\e[0m\e[1m,正在寻求其他解决方案..\e[0m"
ping -c 2 -w 0.3 www.baidu.com &> /dev/null
    if [ $? -ne 0 ];then
	echo -e "\e[1m当前网络\e[91m连接异常！\e[0m\e[1m请重试\e[0m"
	return 1
    fi
    echo -e "\e[1m当前网络\e[92m通畅\e[0m"
	if [ -z "$(rpm -qa | grep wget)" ];then
	    rpm -ivh $(ls $(mount | grep /dev/sr0 | awk '{print $3}')/Packages | grep "^wget")
		if [ $? -ne 0 ];then
		    echo -e "\e[1m\e[96mwget\e[0m\e[1m安装失败,当前状态:\e[96m挂载成功但本地yum搭建失败..\e[0m"
		    return 1
		fi
	fi
	echo -e "\e[1m正在尝试搭建\e[96m网络yum源\e[0m\e[1m这可能需要一段时间,请耐心等待..\e[0m"
	mv -f /etc/yum.repos.d/* /tmp
	wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
	 echo -e "\e[1m正在清理缓存..\e[0m"
	 yum clean all &> /dev/null
	 echo -e "\e[1m正在重建缓存..\e[0m"
	 yum makecache 
		if [ -n $(rpm -qa | grep "^zip") ];then
		    rpm -e zip &>/dev/null
		fi
		yum -y install zip &> /dev/null
		if [ $? -eq 0 ];then
		    return 0
		else
		    echo -e "\e[96m网络yum源\e[0m\e[1m搭建过程发生错误,请重试\e[0m"
		    return 1
		fi
}



#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function environment_test(){
yum_build
if [ $? -ne 0 ];then
    echo -e "\e[91m当前yum源不可用\e[0m"
    exit
fi
if [ -n $(rpm -qa | grep "^zip") ];then
    rpm -e zip &>/dev/null
fi
    yum -y install zip &> /dev/null
    if [ $? -ne 0 ];then
	echo -e "\e[1m最终测试结果为:\e[91myum源不可用\e[0m"
	exit
    fi
echo -e "\e[1m最终测试结果为:\e[92myum源可用\e[0m"
sleep 0.5
systemctl stop firewalld &> /dev/null
    if [ $? -ne 0 ];then
	echo -e "\e[1m\e[91m防火墙\e[0m\e[1m关闭失败！\e[0m"
	exit
    fi
    echo -e "\e[1m\e[91m防火墙\e[92m关闭成功！\e[0m"
systemctl disable firewalld &> /dev/null
sed -i '/SELINUX=enforcing/s/enforcing/disabled/' /etc/selinux/config &> /dev/null
    if [ $? -ne 0 ];then
	echo -e "\e[91mSElinux\e[0m关闭失败！"
	exit
    fi
    echo -e "\e[1m\e[91mSElinux\e[92m关闭成功！\e[0m"
    echo -e "\e[1m当前环境检测\e[92m完成\e[0m\e[1m,正在进行下一步..\e[0m"
    sleep 0.5
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
function test_package(){
if [ -z "$(rpm -qa | grep "^$1")" ];then
    yum -y install $1 
	if [ $? -ne 0 ];then
	    echo -e "\e[96m$1\e[91m安装失败\e[0m"
	    sleep 1
	    return 1
	fi
return 0
fi
}



# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -    
environment_test

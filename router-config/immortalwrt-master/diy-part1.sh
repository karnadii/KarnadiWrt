#!/bin/bash
#========================================================================================================================
# Description: Automatically Build ImmortalWrt for Amlogic ARMv8
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt.git / Branch: 21.02
#========================================================================================================================


#================================
# Konfigurasi Setting
#================================
# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Modify default theme（FROM uci-theme-bootstrap CHANGE TO luci-theme-argon）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-openwrt-2020/luci-theme-argon/g' package/ext-rooter-basic/Makefile

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.31.4）
sed -i 's/192.168.1.1/11.11.1.1/g' package/base-files/files/bin/config_generate

# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# Set ssid
sed -i "s/ImmortalWrt/KarnadiWrt/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh

# Set timezone
sed -i -e "s/CST-8/WIB-7/g" -e "s/Shanghai/Jakarta/g" package/emortal/default-settings/files/99-default-settings-chinese

# Set hostname
sed -i "s/ImmortalWrt/KarnadiWrt/g" package/base-files/files/bin/config_generate

# Set Interface
sed -i "9 i\uci set network.wana=interface\nuci set network.wana.proto='3g'\nuci set network.wana.device='/dev/ttyUSB1'\nuci set network.wana.service='LTE'\nuci set network.wana.apn='internet'\nuci set network.wana.ipv6=auto'\nuci set network.wanb=interface\nuci set network.wanb.proto='dhcp'\nuci set network.wanb.device='eth0.10'\nuci set network.wanc=interface\nuci set network.wanc.proto='dhcp'\nuci set network.wanc.device='usb0'\nuci set network.@device[0].ports='eth0' 'eth0.100' 'eth0.200' 'eth0.300'\nuci commit network" package/emortal/default-settings/files/99-default-settings
sed -i "23 i\uci add_list firewall.@zone[1].network='wana'\nuci add_list firewall.@zone[1].network='wanb'\nuci add_list firewall.@zone[1].network='wanc'\nuci commit firewall\n" package/emortal/default-settings/files/99-default-settings

# Set shell zsh
sed -i "s/\/bin\/ash/\/usr\/bin\/zsh/g" package/base-files/files/etc/passwd

# Set php7 max_size
sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" -e "s/post_max_size = 8M/post_max_size = 1024M/g" feeds/packages/lang/php7/files/php.ini

# Delete duplicate package
rm -rf feeds/luci/applications/luci-app-netdata

#=================================
# Utility App
#=================================
# Add luci-app-amlogic
svn co https://github.com/lynxnexy/luci-app-amlogic/trunk package/luci-app-amlogic

# Add p7zip
svn co https://github.com/hubutui/p7zip-lede/trunk package/p7zip

# Add luci-app-tinyfilemanager
svn co https://github.com/lynxnexy/luci-app-tinyfilemanager/trunk package/luci-app-tinyfilemanager

# Add luci-app-adguardhome
svn co https://github.com/rufengsuixing/luci-app-adguardhome/trunk package/luci-app-adguardhome

# Set adguardhome-core
mkdir -p files/usr/bin/AdGuardHome
AGH_CORE=$(curl -sL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases | grep /AdGuardHome_linux_arm64 | awk -F '"' '{print $4}' | sed -n '1p')
wget -qO- $AGH_CORE | tar xOvz > files/usr/bin/AdGuardHome/AdGuardHome
chmod +x files/usr/bin/AdGuardHome/AdGuardHome

# Set yt-dlp
mkdir -p files/bin
curl -sL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o files/bin/yt-dlp
chmod +x files/bin/yt-dlp

# Set speedtest
mkdir -p files/bin
wget -qO- https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz | tar xOvz > files/bin/speedtest
chmod +x files/bin/speedtest

# Shutdown button
git clone --depth 1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff


#================================
# Injek/Vpn/Bypass App
#================================
# Add luci-app-openclash
rm -rf feeds/luci/applications/luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash
pushd package/luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# Set clash-core
mkdir -p files/etc/openclash/core
# VERNESONG_CORE=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/Clash | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
# VERNESONG_TUN=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/TUN-Premium | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
# VERNESONG_GAME=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/TUN | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
DREAMACRO_CORE=$(curl -sL https://api.github.com/repos/Dreamacro/clash/releases | grep /clash-linux-armv8 | awk -F '"' '{print $4}' | sed -n '1p')
DREAMACRO_TUN=$(curl -sL https://api.github.com/repos/Dreamacro/clash/releases/tags/premium | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
META_CORE=$(curl -sL https://api.github.com/repos/MetaCubeX/Clash.Meta/releases | grep /Clash.Meta-linux-arm64-v | awk -F '"' '{print $4}' | sed -n '1p')
# wget -qO- $VERNESONG_CORE | tar xOvz > files/etc/openclash/core/clash_vernesong
# wget -qO- $VERNESONG_TUN | gunzip -c > files/etc/openclash/core/clash_tun_vernesong
# wget -qO- $VERNESONG_GAME | tar xOvz > files/etc/openclash/core/clash_game_vernesong
wget -qO- $DREAMACRO_CORE | gunzip -c > files/etc/openclash/core/clash
wget -qO- $DREAMACRO_TUN | gunzip -c > files/etc/openclash/core/clash_tun
wget -qO- $META_CORE | gunzip -c > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash*

# Set v2ray-rules-dat
mkdir -p files/etc/openclash
curl -sL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o files/etc/openclash/GeoSite.dat
curl -sL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o files/etc/openclash/GeoIP.dat

# Libernet
# svn co https://github.com/r3yr3/reyre-package/trunk/luci-app-libernet package/luci-app-libernet

#================================
# Themes
#================================
# git clone --depth 1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
# git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

#================================
# Monitoring
#================================
# User online cek
svn co https://github.com/haiibo/openwrt-packages/trunk/luci-app-onliner package/luci-app-onliner
# Wrtbwmon
svn co https://github.com/brvphoenix/luci-app-wrtbwmon/trunk/luci-app-wrtbwmon package/luci-app-wrtbwmon
svn co https://github.com/brvphoenix/wrtbwmon/trunk/wrtbwmon package/wrtbwmon
# netdata
git clone --depth 1 https://github.com/karnadii/luci-app-netdata package/luci-app-netdata

#================================
## Modem Tool
#================================
# Rooter Support untuk modem rakitan
svn co https://github.com/karnadii/rooter/trunk/package/rooter-builds/0protocols/luci-proto-3x package/luci-proto-3x
svn co https://github.com/karnadii/rooter/trunk/package/rooter-builds/0protocols/luci-proto-mbim package/luci-proto-mbim
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0drivers/rmbim package/rmbim
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0drivers/rqmi package/rqmi
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0basicsupport/ext-sms package/ext-sms
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0basicsupport/ext-buttons package/ext-buttons
svn co https://github.com/karnadii/rooter/trunk/package/rooter/ext-rooter-basic package/ext-rooter-basic
# Add luci-app-3ginfo
svn co https://github.com/lynxnexy/luci-app-3ginfo/trunk package/luci-app-3ginfo
# Add luci-app-atinout-mod
svn co https://github.com/lynxnexy/luci-app-atinout-mod/trunk package/luci-app-atinout-mod
  
#================================
## MISC
#================================
# Set oh-my-zsh
mkdir -p files/root
pushd files/root
git clone https://github.com/robbyrussell/oh-my-zsh ./.oh-my-zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions
cp $GITHUB_WORKSPACE/amlogic/common/patches/zsh/.zshrc .
cp $GITHUB_WORKSPACE/amlogic/common/patches/zsh/example.zsh ./.oh-my-zsh/custom/example.zsh
popd

# Set modemmanager to disable
mkdir -p feeds/luci/protocols/luci-proto-modemmanager/root/etc/uci-defaults
cat << EOF > feeds/luci/protocols/luci-proto-modemmanager/root/etc/uci-defaults/70-modemmanager
[ -f /etc/init.d/modemmanager ] && /etc/init.d/modemmanager disable
exit 0
EOF
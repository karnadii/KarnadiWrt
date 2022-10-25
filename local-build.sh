git clone https://github.com/immortalwrt/immortalwrt.git openwrt
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
../router-config/immortalwrt-master/diy-part1.sh
../router-config/immortalwrt-master/diy-part2.sh
cp ../router-config/immortalwrt-master/.config .config
make menuconfig
make -j8 download V=s
make -j8 V=s

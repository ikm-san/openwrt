```

docker run -it --name oak_build_env cdfa34bfa368
cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/

cd /tmp
wget https://github.com/ikm-san/openwrt/raw/main/icwmp/iopsys-devel.zip -O iopsys-devel.zip
unzip iopsys-devel.zip -d iopsys


mkdir -p /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/icwmp
mv iopsys/iopsys-devel/icwmp/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/icwmp/

mkdir -p /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/bbfdm
mv iopsys/iopsys-devel/bbfdm/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/bbfdm/


cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/
./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig

./scripts/feeds install icwmp
./scripts/feeds install bbfdm

make package/icwmp/compile V=s
make package/icwmp/compile V=s -j1




```

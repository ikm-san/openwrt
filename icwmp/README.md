```
docker stop oak_build_env
docker rm oak_build_env
docker run -it --name oak_build_env cdfa34bfa368
cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/

apt-get update
apt-get install -y build-essential git libncurses5-dev gawk gcc-multilib flex gettext libssl-dev unzip


cd /tmp
wget https://github.com/ikm-san/openwrt/raw/main/icwmp/iopsys-devel.zip -O iopsys-devel.zip
unzip iopsys-devel.zip -d iopsys
wget https://github.com/ikm-san/openwrt/raw/main/icwmp/bbfdm-devel.zip -O bbfdm-devel.zip
unzip bbfdm-devel.zip -d bbfdm




mkdir -p /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/icwmp
mkdir -p /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/libbbfdm-api

mv iopsys/iopsys-devel/icwmp/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/icwmp/
mv bbfdm/bbfdm-devel/libbbfdm-api/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/libbbfdm-api/

cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/
./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig

./scripts/feeds install icwmp
./scripts/feeds install bbfdm

make package/icwmp/compile V=s
make package/icwmp/compile V=s -j1




```

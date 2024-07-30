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
mv iopsys/iopsys-devel/icwmp/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/icwmp/

mv iopsys/iopsys-devel/bbfdm /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/
cp -r bbfdm/bbfdm-devel/* /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/bbfdm/

cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/
./scripts/feeds update -a
./scripts/feeds install -a

make menuconfig

./scripts/feeds install icwmp
./scripts/feeds install bbfdm

make package/icwmp/compile V=s
make package/icwmp/compile V=s -j1




```


```
vi /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/build_dir/target-arm/bbfdm-1.9.13/libbbfdm/dmtree/tr181/deviceinfo.c
410行目
json_object_object_add(obj, "FaultCode", json_object_new_uint64(fault_code));を
json_object_object_add(obj, "FaultCode", json_object_new_int((int)fault_code));に変更

vi /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/build_dir/target-arm/bbfdm-1.9.13/bbfdmd/ubus/get_helper.c
int64_t rem = uloop_timeout_remaining64(&g_current_trans.trans_timeout);　を
int rem = uloop_timeout_remaining(&g_current_trans.trans_timeout);　に変更
とりあえずエラーがでなくなる
make package/bbfdm/compile V=s -j1

```


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

いるのかいらないのかわからない
echo "src-link bbfdm /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/package/bbfdm" >> feeds.conf.default

ソースコードの修正
cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/build_dir/target-arm/icwmp-9.8.4/src
vi cwmp.c
#include <sys/stat.h> // 追加
cd /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk
make package/icwmp/compile V=s

ls -l /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/
scp /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/icwmp_9.8.4_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/

ssh root@192.168.10.1
opkg install /tmp/icwmp_9.8.4_arm_cortex-a7_neon-vfpv4.ipk

dockerからファイルの取り出し
docker cp 736c0280a1a6:/home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/icwmp_9.8.4_arm_cortex-a7_neon-vfpv4.ipk /mnt/c/temp/

opkg update
opkg install mxml

scp /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/bbf_configmngr_1.9.13_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/
scp /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/bbfdmd_1.9.13_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/
scp /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/libbbfdm-api1.0_1.9.13_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/
scp /home/openwrt/downloads/LinksysRouter/working/qca-networking-2022-spf-12-2_qca_oem-r12.2.r4_00015.0/qsdk/bin/packages/arm_cortex-a7_neon-vfpv4/base/libbbfdm_1.9.13_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/

opkg install libbbfdm-api1.0_1.9.13_arm_cortex-a7_neon-vfpv4.ipk
opkg install libbbfdm_1.9.13_arm_cortex-a7_neon-vfpv4.ipk
opkg install bbf_configmngr_1.9.13_arm_cortex-a7_neon-vfpv4.ipk
opkg install bbf_configmngr_1.9.13_arm_cortex-a7_neon-vfpv4.ipk
opkg install bbfdmd_1.9.13_arm_cortex-a7_neon-vfpv4.ipk
opkg install libwolfssl

mkdir -p /etc/bbfdm/json/
wget -O /etc/bbfdm/json/CWMPManagementServer.json https://raw.githubusercontent.com/ikm-san/openwrt/main/icwmp/CWMPManagementServer.json


```

required config settings
```
wget -O /etc/config/cwmp https://raw.githubusercontent.com/ikm-san/openwrt/main/icwmp/cwmp_config
https://dev.iopsys.eu/bbf/icwmp/-/blob/devel/docs/api/uci/cwmp.md?ref_type=heads
https://dev.iopsys.eu/bbf/bbfdm/-/blob/devel/docs/api/uci/bbfdm.md?ref_type=heads
```
https
```
https://dev.iopsys.eu/bbf/icwmp/-/blob/devel/docs/guide/https_config.md
```

error
```
root@OpenWrt:/tmp# opkg install icwmp_9.8.4_arm_cortex-a7_neon-vfpv4.ipk
Installing icwmp (9.8.4) to root...
Configuring icwmp.
//usr/lib/opkg/info/icwmp.postinst: /etc/uci-defaults/85-cwmp-set-userid: line 10: db: not found
//usr/lib/opkg/info/icwmp.postinst: /etc/uci-defaults/85-cwmp-set-userid: line 18: db: not found
//usr/lib/opkg/info/icwmp.postinst: /etc/uci-defaults/95-set-random-inform-time: line 14: arithmetic syntax error

```

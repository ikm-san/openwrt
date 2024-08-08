

ビルド済みのインストール手順
```
curl -o /tmp/easycwmp_1.6.0_arm_cortex-a7_neon-vfpv4.ipk https://github.com/ikm-san/openwrt/raw/main/easycwmp/easycwmp_1.6.0_arm_cortex-a7_neon-vfpv4.ipk
curl -o /tmp/libmicroxml_2015-03-18_arm_cortex-a7_neon-vfpv4.ipk https://github.com/ikm-san/openwrt/raw/main/easycwmp/libmicroxml_2015-03-18_arm_cortex-a7_neon-vfpv4.ipk
opkg install /tmp/libmicroxml_2015-03-18_arm_cortex-a7_neon-vfpv4.ipk
opkg install /tmp/easycwmp_1.6.0_arm_cortex-a7_neon-vfpv4.ipk
```

ダウンロードできない場合、C:\tempからscpするのも良いかも
```
scp C:\temp\libmicroxml_2015-03-18_arm_cortex-a7_neon-vfpv4.ipk root@192.168.10.1:/tmp/
opkg install /tmp/libmicroxml_2015-03-18_arm_cortex-a7_neon-vfpv4.ipk
```

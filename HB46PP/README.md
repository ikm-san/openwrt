# HB46PP Get Rule OpenWrt対応PJ

本体はgistにあります。こちらはアーカイブです。  
https://gist.github.com/ikm-san/ca6fdbfe7666feba7441d6b802c4ec2e  

OpenWrtルーターでHB46PP日本国内向け標準プロビ方式で各種パラメーターを取得できるモジュール開発を目指します。  
専用FQDN(4over6.info）に問い合わせを行い、DNSよりmap rule等のサーバー情報を取得し、その情報を用いて、IPv6接続に必要な各種データを専用のルールサーバーより取得します。
ここまで対応できれば、応用展開可能になります。

## 対応VNE
- BIGLOBE
- ASAHIネット  
※そのほかのVNEは現状対応しておらず非公開です。

## 規格リファレンス
[IPv6マイグレーョン技術の国内標準プロビジョニング方式](https://github.com/v6pc/v6mig-prov/blob/1.1/spec.md)

## 参照先
https://gist.github.com/stkchp/4daea9158439c32d7a70a255d51e568b#file-get-dslite-aftr-in-asahinet-md

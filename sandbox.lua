-- 以下はLuaCryptoの使用例です（仮のコードで、ライブラリのインストールが必要です）
local crypto = require("crypto")
local key = "Linksys"
local data = "APIキーなどのセンシティブなデータ"

-- 暗号化
local encryptedData = crypto.evp.encrypt(data, key, "aes-256-cbc")

-- 復号化（必要な場合）
local decryptedData = crypto.evp.decrypt(encryptedData, key, "aes-256-cbc")

print("暗号化されたデータ: ", encryptedData)
print("復号化されたデータ: ", decryptedData)
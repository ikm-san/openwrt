local openssl = require("openssl")

-- 暗号化されたデータ（16進数文字列）
local hexEncryptedData = "bf502ae10c4b83e034891e62626c01d4b70f48e5e361eb75fcb4fc0d2fa774ea4a331c285cb59d9f5a11c46b0a0368ca1253283d891df54962778c225d79fd25ae9d688614ebef0a30e961e1153ad5ca"

-- 16進数の文字列をバイナリデータに変換する関数
local function hex_to_binary(hex)
    return (hex:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

-- 暗号化に使ったキー
local key = "Linksys"

-- 暗号化のためのキーを適切な長さに調整
local key = openssl.digest.digest("sha256", key, true)

-- 暗号化されたデータをバイナリ形式に変換
local encryptedData = hex_to_binary(hexEncryptedData)

-- 復号化に使用するcipherの準備
local cipher = openssl.cipher.get("aes-256-cbc")

-- 復号化
local decryptedData, err = cipher:decrypt(encryptedData, key)
assert(decryptedData, err)

print("復号化されたデータ: ", decryptedData)

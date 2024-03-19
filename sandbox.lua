local openssl = require("openssl")
local cipher = openssl.cipher.get("aes-256-cbc")
local key = "Linksys"

-- 暗号化のためのキーを適切な長さに調整
local key = openssl.digest.digest("sha256", key, true)

local data = "bf502ae10c4b83e034891e62626c01d4b70f48e5e361eb75fcb4fc0d2fa774ea4a331c285cb59d9f5a11c46b0a0368ca1253283d891df54962778c225d79fd25ae9d688614ebef0a30e961e1153ad5ca"

-- 暗号化
-- local encryptedData, err = cipher:encrypt(data, key)
-- assert(encryptedData, err)

-- 復号化
local decryptedData, err = cipher:decrypt(data, key)
assert(data, err)

-- print("暗号化されたデータ: ", openssl.hex(encryptedData))
print("復号化されたデータ: ", decryptedData)

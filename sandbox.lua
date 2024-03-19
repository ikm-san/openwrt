local openssl = require("openssl")
local cipher = openssl.cipher.get("aes-256-cbc")
local key = "Linksys"

-- 暗号化のためのキーを適切な長さに調整
local key = openssl.digest.digest("sha256", key, true)

local data = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"

-- 暗号化
local encryptedData, err = cipher:encrypt(data, key)
assert(encryptedData, err)

-- 復号化
local decryptedData, err = cipher:decrypt(encryptedData, key)
assert(decryptedData, err)

print("暗号化されたデータ: ", openssl.hex(encryptedData))
print("復号化されたデータ: ", decryptedData)

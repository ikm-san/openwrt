local fs = require "nixio.fs"
local http = require "luci.http"
local jsonc = require "luci.jsonc"

local m, s, btn

m = SimpleForm("fetchdata", "Fetch Data")
m.reset = false
m.submit = false

function fetch_data()
    local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local response, code = http.request(url)
    if code ~= 200 then
        return nil, "HTTP request failed"
    end
    
    local jsonStr = response:match("%((.+)%)") -- JSONP response parsing
    if not jsonStr then
        return nil, "Failed to extract JSON"
    end
    
    local status, data = pcall(jsonc.parse, jsonStr)
    if not status then
        return nil, "JSON parsing failed"
    end
    
    return data, nil
end

btn = m:field(Button, "fetch", "Fetch Data", "Click to fetch data")
btn.inputstyle = "reload"
function btn.write()
    local data, err = fetch_data()
    if data then
        m.message = "Data fetched successfully: " .. jsonc.stringify(data)
    else
        m.message = "Error fetching data: " .. err
    end
end

return m

local iputils = require "resty.iputils"
local http = require "resty.http"

local ngx = ngx

local whitelist_m = {
    _VERSION = '0.1-0'
}

whitelist_m.__index = whitelist_m

local validation_message =
    "[lua-resty-whitelist] whitelist URL must be either a non-empty string or table of non-empty strings."

local function istable(t)
    return type(t) == 'table'
end

local function is_empty(s)
    return s == nil or s == ''
end

local function fetch_whitelist(url)
    iputils.enable_lrucache()

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        method = "GET",
        ssl_verify = false,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
    })

    local status = res and res.status or nil
    local body = res and res.body or nil

    if (not res) or (not body) or (status and (status < 200 or status >= 300)) or err then
        ngx.log(ngx.ERR, "[lua-resty-whitelist] failed to fetch whitelist => url: " .. url .. ", status: " .. status ..
            ", body: " .. body, err)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local whitelist = body .. " "
    local whitelist_array = {}

    -- Extract CIRDs
    for ip in string.gmatch(whitelist, "((%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)/(%d%d?))") do
        table.insert(whitelist_array, ip)
    end

    -- local whitelist_concat = table.concat(whitelist_array, ", ")
    -- ngx.log(ngx.ERR, "[lua-resty-whitelist] CIRDs: " .. whitelist_concat)

    -- TODO: Extract normal IPs as well

    -- -- Extract IPs
    -- for ip in string.gmatch(whitelist, "((%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$)") do
    --     table.insert(whitelist_array, string.sub(ip, 1, -2))
    -- end

    -- whitelist_concat = table.concat(whitelist_array, ", ")
    -- ngx.log(ngx.ERR, "[lua-resty-whitelist] whitelist_concat: " .. whitelist_concat)

    return whitelist_array
end

local function match_ip_whitelist(ip, whitelist_array)
    local whitelist = iputils.parse_cidrs(whitelist_array)
    if not iputils.ip_in_cidrs(ip, whitelist) then
        return ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

function whitelist_m.new(url)

    if is_empty(url) then
        ngx.log(ngx.ERR, validation_message)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local whitelist_array = {}

    if istable(url) then
        for _, u in ipairs(url) do
            if is_empty(u) then
                ngx.log(ngx.ERR, validation_message)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end

            for _, v in ipairs(fetch_whitelist(u)) do
                table.insert(whitelist_array, v)
            end
        end
    else
        whitelist_array = fetch_whitelist(url)
    end

    match_ip_whitelist(ngx.var.remote_addr, whitelist_array)
end

return whitelist_m

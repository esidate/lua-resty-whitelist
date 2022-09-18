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

    if not res then
        ngx.log(ngx.ERR, "[lua-resty-whitelist] failed to request whitelist endpoint: response is empty, URL: ", url)
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end
    if is_empty(res.body) or res.status < 200 or res.status > 299 then
        ngx.log(ngx.ERR,
            "[lua-resty-whitelist] failed to request whitelist endpoint: status code is not success, URL: ", url)
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local body = res.body

    local whitelist_body = " " .. body .. " "

    -- Extract all CIDRs from whitelist
    local cidrs_regex =
        "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\/(3[0-6]|[1-2][0-9]|[0-9])))"
    local whitelist_cidrs = {}
    for cidr in ngx.re.gmatch(whitelist_body, cidrs_regex, "o") do
        table.insert(whitelist_cidrs, cidr[0])
    end

    -- Extract all IPs from whitelist
    local ip_regex =
        "((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))"
    local whitelist_ips = {}
    for ip in ngx.re.gmatch(whitelist_body, ip_regex, "o") do
        table.insert(whitelist_ips, ip[0])
    end

    -- Parse CIDRs
    local whitelist_cidrs_parsed = {}
    if istable(whitelist_cidrs) and #whitelist_ips > 0 then
        whitelist_cidrs_parsed, err = iputils.parse_cidrs(whitelist_cidrs)
        if err then
            ngx.log(ngx.ERR, "[lua-resty-whitelist] failed to parse CIDRs, URL: " .. url .. ", err: " .. err)
            ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
        end
    end

    -- For each IP verify that there is no CIDR that contains it (sort of a clean up)
    local clean_whitelist_ips = {}
    for _, ip in ipairs(whitelist_ips) do
        if not iputils.ip_in_cidrs(ip, whitelist_cidrs_parsed) then
            table.insert(clean_whitelist_ips, ip)
        end
    end

    return clean_whitelist_ips, whitelist_cidrs_parsed, whitelist_cidrs
end

local function match_ip_whitelist(ip, full_whitelist_ips, full_whitelist_cidrs_parsed)
    if iputils.ip_in_cidrs(ip, full_whitelist_cidrs_parsed) then
        return true
    end

    for _, v in ipairs(full_whitelist_ips) do
        if v == ip then
            return true
        end
    end

    return ngx.exit(ngx.HTTP_FORBIDDEN)
end

function whitelist_m.new(url)

    if is_empty(url) then
        ngx.log(ngx.ERR, validation_message)
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    end

    local full_whitelist_cidrs_parsed = {}
    local full_whitelist_cidrs_unparsed = {}
    local full_whitelist_ips = {}

    if istable(url) then
        -- Iterate over the table url as it is a list of URLs
        for _, v in ipairs(url) do
            if is_empty(v) then
                ngx.log(ngx.ERR, validation_message)
                ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
            end

            local whitelist_ips, whitelist_cidrs_parsed, whitelist_cidrs_unparsed = fetch_whitelist(v)

            for _, ip in ipairs(whitelist_ips) do
                table.insert(full_whitelist_ips, ip)
            end

            for _, cidr in ipairs(whitelist_cidrs_parsed) do
                table.insert(full_whitelist_cidrs_parsed, cidr)
            end

            for _, cidr in ipairs(whitelist_cidrs_unparsed) do
                table.insert(full_whitelist_cidrs_unparsed, cidr)
            end
        end
    else
        -- Get clean_whitelist_ips, whitelist_cidrs_parsed from fetch_whitelist(url)
        full_whitelist_ips, full_whitelist_cidrs_parsed, full_whitelist_cidrs_unparsed = fetch_whitelist(url)
    end

    ngx.log(ngx.ALERT, "Whitelist IPs: " .. table.concat(full_whitelist_ips, ", "))
    ngx.log(ngx.ALERT, "Whitelist CIDRs: " .. table.concat(full_whitelist_cidrs_unparsed, ", "))

    match_ip_whitelist(ngx.var.remote_addr, full_whitelist_ips, full_whitelist_cidrs_parsed)
end

return whitelist_m

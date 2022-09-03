package = "lua-resty-whitelist"
version = "0.0.0"

source = {
  url = "git+https://github.com/esidate/lua-resty-whitelist",
  tag = "v0.0.0",
}

description = {
  summary = "Lua NGINX dynamic allowlist based on ngx_lua module and OpenResty",
  license = "MIT",
}

dependencies = {
  "lua >= 5.1",
  "resty.iputils => 0.3.0"
}

build = {
  type = "builtin",
  modules = {
    ["resty.whitelist"] = "lib/resty/whitelist.lua",
  },
}

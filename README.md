# Lua Resty Whitelist

Dynamic whitelist in Lua based on ngx_lua for NGINX and OpenResty

:warning: Under construction

## Publish to LuaRocks

```sh
# Upload to LuaRocks
luarocks upload lua-resty-whitelist-*.rockspec

# Create a source rock
luarocks pack lua-resty-whitelist-*.rockspec
```

## Running the demo

```sh
cd demo
docker-compose up
# Visit openresty at localhost:80, You should get a 503 error as the whitelist endpoint is not up yet

# Run a local mockup server to serve the dynamic IP whitelist
# Depending on the configuration, the server is genereally accessible inside the openrest docker container at 172.18.0.1
python -m http.server 9001
# Now visiting openresty at localhost:80 should return a 403 error as the IP is not whitelisted

# Add to and remove from the mockup server your client IP address or a CIDR that matches it such as 172.19.0.1/16 to test the configuration
# If your client IP is whitelisted, you should get the "Welcome to OpenResty!" page
```

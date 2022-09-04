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
docker-compose up # visit openresty at localhost:80
# Run a local server to serve the IP lists to simulate a dynamic IP whitelist
# Depending on the configuration, the server is genereally accessible inside the openrest docker container at 172.18.0.1
python -m http.server 9001
# Edit the IP list files to experiment with the configuration
```

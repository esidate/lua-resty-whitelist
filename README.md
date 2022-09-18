# Lua Resty Whitelist

This module can be used to implement a dynamic whitelist in NGINX/OpenResty. This is especially useful to allow access only to some SaaS and Cloud services with dynamic IP addresses, such as Cloudflare, AWS, Azure, etc. For example, some of them may offer security features such as DDOS protection, WAF, etc. but can be bypassed if the origin IP is leaked and the server allows access from any IP address.  
The module accepts any format of the whitelist (e.g JSON, YAML, plain text, etc.) as long as they contain IPs and/or CIDRs.

:warning: This project is still in beta. Use at your own risk.

## How to use

Installation:

```bash
luarocks install lua-resty-whitelist
```

Use it in your nginx configuration:

```nginx
server {
    listen 80;
    server_name localhost;

    # This is required for the module to make HTTP requests, you can use any DNS server
    resolver 1.1.1.1 ipv6=off;

    location / {
        lua_code_cache on;
        access_by_lua_block {
            local whitelist = require "resty.whitelist"

            local whitelist_urls = {
                "https://www.cloudflare.com/ips-v4", "https://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips"
            }
            whitelist.new(whitelist_urls)

            -- Or single URL

            local whitelist_url = "https://www.cloudflare.com/ips-v4"
            whitelist.new(whitelist_url)
        }
    }
}
```

## What's missing

- IPv6 support
- Caching of the whitelist and sharing it between workers
- Dockerize a production-ready version and publish it to Docker Hub
- Tests
- Better error handling and logging
- Better documentation

## Contrubuting

### Publish the package

#### Publish to LuaRocks

```bash
mv lua-resty-whitelist-*.rockspec lua-resty-whitelist-X.Y-Z.rockspec
sed -i -E 's/"([0-9]+\.[0-9]+-[0-9]+)"/"X.Y-Z"/g' lua-resty-whitelist-X.Y-Z.rockspec

git add .
git commit -m "Release X.Y-Z"
git push

git tag vX.Y-Z
git push origin vX.Y-Z

luarocks upload lua-resty-whitelist-X.Y-Z.rockspec
```

#### Publish to GitHub

- A `lua-resty-whitelist-X.Y-Z.src.rock` file will be created in the current directory after publishing to LuaRocks
- Visit <https://github.com/esidate/lua-resty-whitelist/tags> and click on the tag `vX.Y-Z`
- Click on "Create release from tag"
- Click on "Generate release notes" and upload the `lua-resty-whitelist-X.Y-Z.src.rock` file
- Publish the release

### Running the demo

The demo is also sort of the development environment.

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

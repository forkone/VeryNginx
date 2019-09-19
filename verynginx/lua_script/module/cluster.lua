--version 0.5.1  last update 20190918

local VeryNginxConfig = require "VeryNginxConfig"
local http = require("resty.http")
local dkjson = require "dkjson"
local json = require "json"

local ClusterConfig = VeryNginxConfig.configs["cluster"]
local master_path = "http://" .. ClusterConfig["cluster_peer_host"] .. VeryNginxConfig.configs["base_uri"]
local master_login_uri = master_path .. "/login"
local master_config_uri = master_path .. "/config"
local master_sysinfo_uri = master_path .. "/cluster/report_sysinfo"

local _M = {}

-------------------------------------------------------------------------------------------------------------------------
function _M.listen()
    local method = ngx.req.get_method()
    local uri = ngx.var.uri
    local base_uri = VeryNginxConfig.configs['base_uri'] .. "/cluster"

    local route_table = {
        { ['method'] = "GET",  ["path"] = "/report_sysinfo", ['handle'] = _M.report_sysinfo },
        { ['method'] = "POST",  ["path"] = "/api/", ['handle'] = _M.report_sysinfo },
        { ['method'] = "POST", ["path"] = "/api/v2", ['handle'] = cluster.listen }
    }

    --local path = string.sub( uri, string.len( base_uri ) + 1 )
    --for i,item in ipairs( route_table ) do
    --end

    if method == "GET" then
        
    end

    if method == "POST" then

    end
    
    
end


function _M.report_sysinfo()
    local sysinfo = {}

    if jit then
        local lua_version = jit.version
    else
        local lua_version = _VERSION
    end

    sysinfo["nginx_build_paras"] = ngx.config.nginx_configure()
    sysinfo["lua_version"] = lua_version
    sysinfo["ngx_lua_version"] = ngx.config.ngx_lua_version
    sysinfo["nginx_path"] = ngx.config.prefix()
    sysinfo["airwall_path"] = VeryNginxConfig.home_path()

    return json.encode(sysinfo)
end


--------------------------------------------------------------------------------------------------------------------------

function _M.request_for_login()

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri(master_login_uri,
        { method = "POST",
          body = "user=walladmin&password=walladmin@123",
          headers = {
            ["Host"] = ClusterConfig["cluster_peer_host"],
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["User-Agent"] = "lua-resty-http/0.14 (Lua) ngx_lua/10015 Airwall"
          }
        }
    )

    if not res or res.status ~= 200 then
        ngx.say("login request failed ", res.status, err)
        ngx.log(ngx.ERR,"login request failed ", res.status, err)
        return
    end

    local auth_info = dkjson.decode(res.body).cookies
    return auth_info

end


function _M.request_for_sysinfo()

    local auth_table = _M.request_for_login()
    local cookie = ""
    for k,v in pairs(auth_table) do
        cookie = cookie .. k .. "=" .. v .. "; "
    end

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri(master_sysinfo_uri,
        { method = "GET",
          headers = {
            ["Host"] = ClusterConfig["cluster_peer_host"],
            ["Cookie"] = cookie,
            ["User-Agent"] = "lua-resty-http/0.14 (Lua) ngx_lua/10015 Airwall"
          }
        }
    )

    if not res or res.status ~= 200 then
        ngx.say("config request failed ", res.status, err)
        ngx.log(ngx.ERR,"config request failed ", res.status, err)
        return
    end

    return res.body

end


function _M.request_for_config()

    local auth_table = _M.request_for_login()
    local cookie = ""
    for k,v in pairs(auth_table) do
        cookie = cookie .. k .. "=" .. v .. "; "
    end

    local http = require "resty.http"
    local httpc = http.new()
    local res, err = httpc:request_uri(master_config_uri,
        { method = "GET",
          headers = {
            ["Host"] = ClusterConfig["cluster_peer_host"],
            ["Cookie"] = cookie,
            ["User-Agent"] = "lua-resty-http/0.14 (Lua) ngx_lua/10015 Airwall"
          }
        }
    )

    if not res or res.status ~= 200 then
        ngx.say("config request failed ", res.status, err)
        ngx.log(ngx.ERR,"config request failed ", res.status, err)
        return
    end

    return res.body

end

function _M.request_for_ngconf()   
end

-------------------------------------------------------------------------------------------------------------------------------------

function _M.load_from_request() 
    local config_string = _M.request_for_config()
    VeryNginxConfig.load_from_data(config_string)
end


function _M.every_update()

    local interval = ClusterConfig['cluster_update_interval']
    local handler = _M.load_from_request
    
    if VeryNginxConfig.configs["cluster_enable"] == false then
        return
    end

    if 0 == ngx.worker.id() then
    	ngx.log(ngx.ERR, "start a timer to run VeryNginxConfig.load_from_request. interval: ", interval)
    	local ok, err = ngx.timer.every(interval, handler)
        if not ok then
            ngx.log(ngx.ERR, "fail to create the VeryNginxConfig.load_from_request timer! " ..err)
        end
    end
    
end

---------------------------------------------------------------------------------------------------------------------------------

return _M
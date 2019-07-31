-- -*- coding: utf-8 -*-
-- @Date    : 2019-07-24
-- @Disc    : ip blacklist filter

local VeryNginxConfig = require "VeryNginxConfig"
local myredis = require "redis_util"

local _M = {}

local BlackipConfig = VeryNginxConfig.configs["blackip"]
local remote_addr = ngx.var.remote_addr
local ngx_blackip = ngx.shared.blackip


function _M.filter()

    local res, err = ngx_blackip:get(remote_addr)
    if not res then
        ngx.log(ngx.DEBUG,"failed to get remote_addr: ", remote_addr, err);
        return true
    end

    if res == 1 then
        ngx.log(ngx.ERR,"request blocked for client ip in ngx_blacklist: "..  remote_addr);
        ngx.exit(403)
    end

end


function _M.report()
    local blackip_keys = ngx_blackip:get_keys()
    for k,v in ipairs(blackip_keys) do
        ngx.say(v.."        value        "..ngx_blackip:get(v))
    end
end


function _M.load_from_redis()

    local blackip_redis_key = BlackipConfig["blackip_redis_key"]

    local value = myredis.smembers(blackip_redis_key)
    if value or value = '' then
        ngx_blackip:flush_all()
        for index, item in ipairs(value) do
            blackip:set(item, 1)
        end
        ngx_blackip:add("last_update_time", ngx.localtime())
        ngx.log(ngx.ERR, "load_from_redis complete! ")
    else
        ngx.log(ngx.ERR, "load_from_redis failed! ")
    end

end


function _M.every_update()

    local delay = BlackipConfig["blackip_redis_delay"]
    local handler = _M.load_from_redis
    if 0 == ngx.worker.id() then
    	ngx.log(ngx.ERR, "start a timer to read redis set ngx_blackip.")
    	local ok, err = ngx.timer.every(delay, handler)
        if not ok then
            ngx.log(ngx.ERR, "fail to create the ngx_blackip timer! " ..err)
        end
    end
    
end


function _M.addip()
end


function _M.delip()
end


return _M

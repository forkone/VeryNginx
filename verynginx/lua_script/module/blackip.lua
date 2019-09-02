-- -*- coding: utf-8 -*-
-- @Date    : 2019-07-24
-- @Disc    : ip blacklist filter

local VeryNginxConfig = require "VeryNginxConfig"
local myredis = require "redis_util"
local json = require "json"

local _M = {}

local BlackipConfig = VeryNginxConfig.configs["blackip"]
local ngx_blackip = ngx.shared.blackip


function _M.filter()

    if not VeryNginxConfig.configs["blackip_enable"] then
        return
    end
    
    local remote_addr = ngx.var.remote_addr
    local res, err = ngx_blackip:get(remote_addr)
    if err then
        ngx.log(ngx.ERR, 'get from local dict failed: '..err)
        return
    end
    
    if res == 1 then
        ngx.log(ngx.ERR,"ip_blacklist_hit_and_block ");
        ngx.exit(403)
    end

end


function _M.report()

    local report = {}
    local blackip = {}

    local blackip_keys = ngx_blackip:get_keys(102400)
    table.remove(blackip_keys)
    for k,v in ipairs(blackip_keys) do
        blackip[v] = ngx_blackip:get(v)
    end

    report["last_update_time"] = ngx_blackip:get("last_update_time")
    report["capacity_Kbytes"] = ngx_blackip:capacity() / 1024
    report["free_space_Kbytes"] = ngx_blackip:free_space() / 1024
    report["blackip_counts"] = #blackip_keys
    report["blackip"] = blackip

    return json.encode( report )

end


function _M.load_from_redis()

    local blackip_redis_key = BlackipConfig["blackip_redis_key"]

    ngx_blackip:flush_all()
    local value = myredis.smembers(blackip_redis_key)
    if value or value == '' then
        for index, item in ipairs(value) do
            ngx_blackip:set(item, 1)
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
        ngx.log(ngx.ERR, "read redis set ngx_blackip first time.")
        local ok, err = ngx.timer.at(0, handler)
        if not ok then
            ngx.log(ngx.ERR, "fail to read redis set ngx_blackip first time! " ..err)
        end
    end
    
    if 0 == ngx.worker.id() then
    	ngx.log(ngx.ERR, "start a timer to read redis set ngx_blackip.")
    	local ok, err = ngx.timer.every(delay, handler)
        if not ok then
            ngx.log(ngx.ERR, "fail to create the ngx_blackip timer! " ..err)
        end
    end
    
end


function _M.clearip()
    ngx_blackip:flush_all()
    ngx_blackip:add("last_clear_time", ngx.localtime())
    ngx.log(ngx.ERR,"clear ip over, last_clear_time: ", ngx_blackip:get("last_clear_time"))
end


function _M.addip()
end


function _M.delip()
end


return _M

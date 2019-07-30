-- -*- coding: utf-8 -*-
-- @Date    : 2019-07-25
-- @Disc    : timer for upadte

local _M = {}

local redis = require "redis"

local redis_host = "127.0.0.1"
local redis_port = 6379
--connection timeout for redis in ms
local redis_connect_timeout = 100


function _M.check_blackip()
  
    local redis_key = "ngx_blackip"
    local ngx_blackip = ngx.shared.blackip
  
    local red = redis:new()
    red:set_timeout(redis_connect_timeout)
    local ok, err = red:connect(redis_host, redis_port)
    if not ok then 
        ngx.log(ngx.ERR, "redis connection error: " ..err)
    else
        local new_ngx_blackip, err = red:smembers(redis_key);
        if err then 
            ngx.log(ngx.ERR, "redis read error: " ..err)
        else
            ngx_blackip:flush_all()
            for index, item in ipairs(new_ngx_blackip) do
                ngx_blackip:set(item, 1)
            end
            ngx_blackip:add("last_update_time", ngx.localtime())
	    ngx.log(ngx.ERR, "check_blackip complete! ")
        end
    end
    local ok, err = red:close()
end


function _M.blackip()
    local delay = 20
    local handler = _M.check_blackip
    if 0 == ngx.worker.id() then
    	ngx.log(ngx.ERR, "start a timer to read redis set ngx_blackip.")
    	local ok, err = ngx.timer.every(delay, handler)
        if not ok then
            ngx.log(ngx.ERR, "fail to create the ngx_blackip timer! " ..err)
        end
    end
 end


return _M

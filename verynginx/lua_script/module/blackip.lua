-- -*- coding: utf-8 -*-
-- @Date    : 2019-07-24
-- @Disc    : ip blacklist filter

local _M = {}

local VeryNginxConfig = require "VeryNginxConfig"
local remote_addr = ngx.var.remote_addr
local ngx_blackip = ngx.shared.blackip
local last_update_time = ngx_blackip:get("last_update_time");


function _M.filter()

local res, err = ngx_blackip:get(remote_addr)
if not res then
    ngx.log(ngx.DEBUG,"failed to get remote_addr: ", remote_addr, err);
    return true
end
ngx.log(ngx.DEBUG,"get dict res is : " .. res);

if res == 1 then
    ngx.log(ngx.ERR,"request blocked for client ip in ngx_blacklist: "..  remote_addr);
    ngx.exit(403)
end

end


function _M.addip()
end

function _M.delip()
end

function _M.reportip()
end


return _M

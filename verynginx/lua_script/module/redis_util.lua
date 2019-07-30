local VeryNginxConfig = require "VeryNginxConfig"
local redis = require "redis"

local _M = {}

function _M.connect()
    local red = redis:new()
    red:set_timeout(1000)
    local captchaConfig = VeryNginxConfig.configs['captcha']
    local ok, err = red:connect(captchaConfig['redis_host'], captchaConfig['redis_port'])
    if not ok then
        ngx.log(ngx.ERR, 'Redis get connection failed: '..err)
        _M.close(red)
        return
    else
        return red
    end
end

function _M.close(red)
    if not red then
        return
    end

    -- 10s
    local pool_max_idle_time = 10000
    local poo_size = 100
    local ok, err = red:set_keepalive(pool_max_idle_time, poo_size)
    if not ok then
        ngx.log(ngx.ERR, 'Redis set keepalive failed: '..err)
    end
end

function _M.get(key)
    local red = _M.connect()
    if red then
        local res, err = red:get(key)
        ngx.log(ngx.ERR, res)
        ngx.log(ngx.ERR, err)
        if not res then
            ngx.log(ngx.ERR, 'get '..key..' from redis failed: '..err)
        elseif res == ngx.null then
            res = ''
        end
        _M.close(red)
        return res
    end
end

function _M.hgetall(key)
    local red = _M:connect()
    if red then
        local res, err = red:hgetall(key)
        if not res then
            ngx.log(ngx.ERR, 'hgetall '..key..' from redis failed.')
            ngx.log(ngx.ERR, err)
        end
        _M.close(red)
        return res
    end
end

function _M.hget(key, field)
    
end

return _M

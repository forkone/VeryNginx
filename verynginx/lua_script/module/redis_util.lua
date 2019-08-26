local VeryNginxConfig = require "VeryNginxConfig"
local redis = require "redis"

local RedisConfig = VeryNginxConfig.configs["redis"]
local redis_connect_timeout = 300

local _M = {}

function _M.connect()
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect(RedisConfig['redis_host'], RedisConfig['redis_port'])
    if not ok then
        ngx.log(ngx.ERR, 'Redis get connection failed: '..err)
        _M.close(red)
        return
    else
        local count
        count, err = red:get_reused_times()
        if 0 == count then
            ok, err = red:auth(RedisConfig['redis_passwd'])
            if not ok then
                ngx.log(ngx.ERR,"failed to auth: ", err)
                return
            end
        elseif err then
            ngx.log(ngx.ERR,"failed to get reused times: ", err)
            return
        end
        return red
    end
end

function _M.close(red)
    if not red then
        return
    end

    -- 10s
    local pool_max_idle_time = 10000
    local pool_size = 100
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    if not ok then
        ngx.log(ngx.ERR, 'Redis set keepalive failed: '..err)
    end
end

function _M.get(key)
    local red = _M.connect()
    if red then
        local res, err = red:get(key)
        if err then
            ngx.log(ngx.ERR, 'get '..key..' from redis failed: '..err)
        elseif res == null then
            res = ''
        end
        _M.close(red)
        return res
    end
end

function _M.smembers(key)
    local red = _M.connect()
    if red then
        local res, err = red:smembers(key)
        if err then
            ngx.log(ngx.ERR, 'smembers '..key..' from redis failed: '..err)
            return
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

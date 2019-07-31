
local VeryNginxConfig = require "VeryNginxConfig"
local myredis = require "redis_util"

local _M = {}

-- 本地缓存中的验证码 ID
local captcha = ngx.shared.captcha
-- 客户端 IP
local addr = ngx.var.remote_addr

-- 检查本地缓存
function _M.check()
    -- ngx.log(ngx.ERR, 'in check...')
    -- Cookie 中的验证码 ID
    local cookie_captchaid = ngx.var.cookie_captchaid
    local key = addr..'-'..ngx.var.host
    if not cookie_captchaid then
        -- ngx.log(ngx.ERR, "2. redirect."..type(cookie_captchaid))
        _M.redirectToCaptcha()
    else
        -- ngx.log(ngx.ERR, '3. check cookie captchaid: '..cookie_captchaid)
        local cache_captchaid = captcha:get(key)
        if not cache_captchaid then
            return _M.checkRedis()
        elseif cache_captchaid ~= cookie_captchaid then
            return _M.checkRedis()
        else
            return true
        end
    end

    return nil
end

-- 检查 redis: 数据结构: airwall:kaptcha:captchaid=remote_address
function _M.checkRedis()
    -- Cookie 中的验证码 ID
    local key = addr..'-'..ngx.var.host
    local cookie_captchaid = ngx.var.cookie_captchaid
    local result = nil
    
    -- ngx.log(ngx.ERR, "Get captcha from redis begin.")
    local value = myredis.get("airwall:kaptcha:"..cookie_captchaid)
    if value and value == addr then
        -- Redis 校验成功
        -- ngx.log(ngx.ERR, 'set captchaid cache '..key..'-'..cookie_captchaid)
        captcha:set(key, cookie_captchaid)
        result = true
    else 
        ngx.log(ngx.ERR, "Get captcha from redis fail: ")
        ngx.log(ngx.ERR, value)
    end

    return result
end

-- 频率限制
function _M.freqCheck(freqKey, time)
    -- local value = myredis.get('...')
    -- ngx.err(ngx.ERR, value)
    local key = addr..'-'..ngx.var.host
    ngx.log(ngx.ERR, key)
    -- Cookie 中的验证码 ID
    local cookie_captchaid = ngx.var.cookie_captchaid
    local cache_captchaid = captcha:get(key)
    ngx.log(ngx.ERR, cookie_captchaid)
    ngx.log(ngx.ERR, cache_captchaid)
    -- old captchaid
    if cookie_captchaid and cache_captchaid and cookie_captchaid == cache_captchaid then
        _M.redirectToCaptcha()
    end

    -- ngx.log(ngx.ERR, ".....check..............")
    local result = _M.check()
    if result then
        ngx.shared.frequency_limit:set( freqKey, 1, tonumber(time) )
    else
        -- ngx.log(ngx.ERR, "1. redirect.")
        _M.redirectToCaptcha()
    end
end

-- 跳转到验证码页面
function _M.redirectToCaptcha() 
    local ngx_var = ngx.var 
    local ngx_var_uri = ngx_var.uri
    local ngx_var_scheme = ngx_var.scheme
    local ngx_var_host = ngx_var.host
    local ngx_request_header = ngx.req.get_headers()

    ngx.log(ngx.ERR, '......'..tostring(ngx.var.hostname)..'........'..ngx.var.host..'.....'..ngx_var.request_uri..'......'..ngx_var.uri..'......'..ngx_request_header['Host'])
    
    -- 为什么 ngx.var.host 取的值没有端口??? 参考: http://nginx.org/en/docs/http/ngx_http_core_module.html#var_server_port, 跟它的取值顺序有关, 默认取的 hostname 而不是 request header 里的 Host
    -- captcha_url = ngx_var_scheme..'://'..ngx_var_host..VeryNginxConfig.configs["captcha_uri"]
    local CaptchaConfig = VeryNginxConfig.configs['captcha']
    local captcha_url = CaptchaConfig['captcha_uri']
    local current_url = ngx.escape_uri(ngx_var_scheme..'://'..ngx_request_header['Host']..ngx_var_uri)
    if ngx_var.args ~= nil then
        current_url = ngx.escape_uri(ngx_var_scheme..'://'..ngx_request_header['Host']..ngx_var_uri..'?'..ngx_var.args)
    end
    -- ngx.log(ngx.ERR, 'redirect to '.. captcha_url)
    ngx.redirect(captcha_url..'?redirectUrl='..current_url, ngx.HTTP_MOVED_TEMPORARILY)
end

return _M
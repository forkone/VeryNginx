
local VeryNginxConfig = require "VeryNginxConfig"
local myredis = require "redis_util"

local CaptchaConfig = VeryNginxConfig.configs['captcha']

--var in vn config: cookie_name rds_key_pre

local _M = {}

--check cookie to tell if captchaed before. check local cache first, if not then check redis
function _M.check()

    if VeryNginxConfig.configs["captcha_enable"] ~= true then
        return
    end

    --nginx local shared dict storage in memory remote_addr-http_host:captcha_id 
    local captcha = ngx.shared.captcha
    local remote_addr = ngx.var.remote_addr
    local http_host = ngx.var.http_host
    local cookie_captchaid = ngx.var.cookie_captchaid
    local ngx_key = remote_addr..'_'..http_host

    --fix redirect captcha url cyclely, but accept redirect url in filter module is better
    if string.find( ngx.var.request_uri, CaptchaConfig["captcha_uri"], 1, true ) == 1 then
        return false
    end

    if not cookie_captchaid then
        return _M.redirect_to_captcha()
    else
        local ngx_captchaid = captcha:get(ngx_key)
        if ngx_captchaid and ngx_captchaid == cookie_captchaid then
            ngx.log(ngx.ERR, "captchaid_exists_in_cache ",cookie_captchaid)
            return true
        else
            local rds_key = "airwall:kaptcha:"..cookie_captchaid
            local res = myredis.get(rds_key)
            if res and res == remote_addr then
                ngx.log(ngx.ERR, "captchaid_exists_in_redis ",cookie_captchaid)
                captcha:set(ngx_key, cookie_captchaid, CaptchaConfig["captcha_valid_time"])
                return true
            else
                ngx.log(ngx.ERR, "check_captchaid_failed ", cookie_captchaid, ngx_captchaid, res)
                return _M.redirect_to_captcha()
            end
        end
    end

end


function _M.check_with_freq(key, time)

    local result = _M.check()
    if result == true then
        ngx.shared.frequency_limit:set( key, 1, tonumber(time) )
        ngx.log(ngx.ERR,"freq_limit_unlock_by_captcha ")
    end
end

--redirect to captcha page
function _M.redirect_to_captcha()

    local ngx_var = ngx.var
    local current_uri = ngx_var.request_uri
    local current_scheme = ngx_var.scheme
    local current_host = ngx_var.http_host
    local current_header = ngx.req.get_headers()

    local current_url = current_scheme..'://'..current_host..current_uri
    local captcha_url = CaptchaConfig["captcha_uri"]

    return ngx.redirect(captcha_url..'?redirectUrl='..current_url, 302)

end

return _M
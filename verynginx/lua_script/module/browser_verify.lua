--version 0.5.1  last update 20190918

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local encrypt_seed = require "encrypt_seed"
local util = require "util"

local _M = {}

_M.verify_javascript_html = nil

local cookie_prefix = VeryNginxConfig.configs['cookie_prefix']

function _M.sign( mark )
    local ua = ngx.var.http_user_agent
    local forwarded  = ngx.var.http_x_forwarded_for
    
    if ua == nil then
        ua = ''
    end
    
    if forwarded == nil then
        forwarded = ''
    end

    local sign = ngx.md5( 'VN' .. ngx.var.remote_addr .. forwarded .. ua .. mark .. encrypt_seed.get_seed() )
    return sign 
end

function _M.verify_cookie()
    local sign = _M.sign('cookie')
    local cookie_name =  cookie_prefix .. "_sign_cookie"
    local COOKIE_VAR = "cookie_" .. cookie_name

    if ngx.var.[COOKIE_VAR] and ngx.var.[COOKIE_VAR] == sign then
        ngx.log(ngx.INFO,'verify_cookie_success ')
        return
    end

    ngx.log(ngx.ERR,'verify_cookie_fail , set cookie now')
    ngx.header["Set-Cookie"] =  cookie_name .. "=" .. sign

    if  ngx.var.request_method == "POST" then
        status = 307
    else
        status = 302
    end

    ngx.redirect( ngx.var.scheme.."://"..ngx.var.http_host..ngx.var.request_uri, status)

end

function _M.verify_javascript()
    local sign = _M.sign('javascript')
    local cookie_name =  cookie_prefix .. "_sign_javascript"
    local COOKIE_VAR = "cookie_" .. cookie_name

    if ngx.var.[COOKIE_VAR] and ngx.var.[COOKIE_VAR] == sign then
        ngx.log(ngx.INFO,'verify_javascript_success ')
        return
    end
    
    ngx.log(ngx.ERR,'verify_javascript_fail , verify js now')

    if _M.verify_javascript_html == nil then
        local path = VeryNginxConfig.home_path() .."/support/verify_javascript.html"
        f = io.open( path, 'r' )
        if f ~= nil then
            _M.verify_javascript_html = f:read("*all")
            f:close()
        end
    end

    local redirect_to = nil
    local html = _M.verify_javascript_html

    html = string.gsub( html,'INFOCOOKIE',sign )
    html = string.gsub( html,'COOKIEPREFIX',cookie_prefix )

    if  ngx.var.request_method == "POST" then
        status = 307
    else
        status = 302
    end
    
    redirect_to =  ngx.var.scheme.."://"..ngx.var.http_host..ngx.var.request_uri, status

    html = util.string_replace( html,'INFOURI',redirect_to, 1 )
    
    ngx.header.content_type = "text/html"
    ngx.header['cache-control'] = "no-cache, no-store, must-revalidate"
    ngx.header['pragma'] = "no-cache"
    ngx.header['expires'] = "0"
    ngx.header.charset = "utf-8"
    ngx.say( html )
    
    ngx.exit(200)
end

function _M.filter()
    if VeryNginxConfig.configs["browser_verify_enable"] ~= true then
        return
    end
    
    local matcher_list = VeryNginxConfig.configs['matcher']
    for i,rule in ipairs( VeryNginxConfig.configs["browser_verify_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            local verify_cookie,verify_javascript = false,false
            
            for idx,verify_type in ipairs( rule['type']) do
                if verify_type == 'cookie' then
                    verify_cookie = true
                elseif verify_type == 'javascript' then
                    verify_javascript = true
                end
            end

            if verify_cookie == true then
                _M.verify_cookie()
            end
            
            if verify_javascript == true then
                _M.verify_javascript()
            end

            return
        end
    end
end

return _M

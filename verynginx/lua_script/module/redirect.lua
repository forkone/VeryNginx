--version 0.5.1  last update 20190918
--request_uri vs uri ?

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"

local _M = {}

function _M.run()
    
    if VeryNginxConfig.configs["redirect_enable"] ~= true then
        return
    end
    
    local new_url = nil 
    local re_gsub = ngx.re.gsub
    local ngx_var = ngx.var 
    local ngx_redirect = ngx.redirect
    local ngx_var_uri = ngx_var.uri
    local ngx_var_scheme = ngx_var.scheme
    local ngx_var_host = ngx_var.http_host
    local matcher_list = VeryNginxConfig.configs['matcher']


    for i, rule in ipairs( VeryNginxConfig.configs["redirect_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            replace_re = rule['replace_re']
            if replace_re ~= nil and string.len( replace_re ) > 0  then
                new_url = re_gsub( ngx_var_uri, replace_re, rule['to_uri'] ) 
            else
                new_url = rule['to_uri']
            end

            if new_url ~= ngx_var_uri then

                if string.find( new_url, 'http') ~= 1 then
                    new_url = ngx_var_scheme.."://"..ngx_var_host..new_url
                end

                if  ngx_var.request_method == "POST" then
                    local status = 307
                else
                    local status = 302
                end

                if ngx_var.args ~= nil then
                    ngx_redirect( new_url.."?"..ngx_var.args , status)
                else
                    ngx_redirect( new_url , status)
                end
            end

            return
        end
    end

end

return _M

--version 0.5.1  last update 20190918


local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"

local _M = {}

function _M.scheme_judge()
    local ngx_re_find  = ngx.re.find
    local matcher_list = VeryNginxConfig.configs['matcher']

    for i, rule in ipairs( VeryNginxConfig.configs["scheme_lock_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ]
        if enable == true and request_tester.test( matcher ) == true then
            return rule['scheme']
        end
    end
    return 'none'
end

function _M.run()

    if VeryNginxConfig.configs["scheme_lock_enable"] ~= true then
        return
    end

    local ngx_var = ngx.var
    local scheme = _M.scheme_judge()
    if scheme == "none" or scheme == ngx_var.scheme then
        return
    end

    -- Used on VeryNginx behind Proxy situation
    if scheme == ngx.req.get_headers()["X-Forwarded-Proto"] then
        ngx.log(ngx.STDERR, "Compare the protocol from more frontend level proxy, ", ngx.req.get_headers()["X-Forwarded-Protol"])
        return
    end

    local current_url = scheme.."://"..ngx_var.http_host..ngx_var.request_uri

    --for POST request, code 302 will conduct that the browser use GET method to re-request 
    if  ngx_var.request_method == "POST" then
        local status = 307
    else
        local status = 302
    end

    return ngx.redirect( current_url, status )

end

return _M

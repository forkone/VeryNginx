--version 0.5.1  last update 20190918

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local captcha = require "captcha"

local _M = {}

function _M.filter()

    if VeryNginxConfig.configs["filter_enable"] ~= true then
        return
    end
    
    local matcher_list = VeryNginxConfig.configs['matcher']
    local response_list = VeryNginxConfig.configs['response']
    local response = nil

    for i,rule in ipairs( VeryNginxConfig.configs["filter_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            ngx.log(ngx.ERR,rule['matcher']..rule['action'],' ',rule['code'] or "captcha",' ',rule['response'] or "none")
            local action = rule['action']
            if action == 'accept' then
                return
            elseif action == 'captcha' then
                captcha.check()
                return
            elseif action == 'log' then
                return
            elseif action == 'block' then
                ngx.status = tonumber( rule['code'] )
                if rule['response'] ~= nil then
                    response = response_list[rule['response']]
                    if response ~= nil then
                        ngx.header.content_type = response['content_type']
                        ngx.say( response['body'] )
                        ngx.exit( ngx.HTTP_OK )
                    end
                else
                    ngx.exit( tonumber( rule['code'] ) )
                end
            end
        end
    end
end

return _M

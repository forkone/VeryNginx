-- -*- coding: utf-8 -*-
-- @Date    : 2016-01-02 00:46
-- @Author  : Alexa (AlexaZhou@163.com)
-- @Link    : 
-- @Disc    : filter request'uri maybe attack

local _M = {}

local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local captcha = require "captcha"


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
--          ngx.log(ngx.STDERR,rule['matcher'])
            local action = rule['action']
            if action == 'accept' then
--              ngx.log(ngx.STDERR,rule['matcher'],' ',rule['action'])
                return  
            elseif action == 'captcha' then
                captcha.check()
                return
            else
                ngx.status = tonumber( rule['code'] )
                if rule['response'] ~= nil then
                    response = response_list[rule['response']]
                    if response ~= nil then
                        ngx.header.content_type = response['content_type']
                        ngx.say( response['body'] )
                        ngx.log(ngx.STDERR,rule['matcher'],' ',rule['action'],' ',ngx.status,' ',rule['response'])
                        ngx.exit( ngx.HTTP_OK )
                    end
                else
                    ngx.log(ngx.STDERR,rule['matcher'],' ',rule['action'],' ',ngx.status,' none')
                    ngx.exit( tonumber( rule['code'] ) )
                end
            end
        end
    end
end

return _M

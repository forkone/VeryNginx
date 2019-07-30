-- -*- coding: utf-8 -*-
-- @Date    : 2016-04-20 23:13
-- @Author  : Alexa (AlexaZhou@163.com)
-- @Link    : 
-- @Disc    : request frequency limit

local _M = {}


local VeryNginxConfig = require "VeryNginxConfig"
local request_tester = require "request_tester"
local util = require "util"
local captcha = require "captcha"

local limit_dict = ngx.shared.frequency_limit

function _M.filter()

    if VeryNginxConfig.configs["frequency_limit_enable"] ~= true then
        return
    end

    local matcher_list = VeryNginxConfig.configs['matcher']
    local response_list = VeryNginxConfig.configs['response']
    local response = nil

    for i, rule in ipairs( VeryNginxConfig.configs["frequency_limit_rule"] ) do
        local enable = rule['enable']
        local matcher = matcher_list[ rule['matcher'] ] 
        if enable == true and request_tester.test( matcher ) == true then
            
            local key = i 
            if util.existed( rule['separate'], 'ip' ) then
                key = key..'-'..ngx.var.host..'-'..ngx.var.remote_addr
            end

            if util.existed( rule['separate'], 'uri' ) then
                key = key..'-'..ngx.var.host..'-'..ngx.var.uri
            end

            local time = rule['time']
            local count = rule['count']
            local code = rule['code']

            --ngx.log(ngx.STDERR,'-----');
            --ngx.log(ngx.STDERR,key);
            
            local count_now = limit_dict:get( key )
            --ngx.log(ngx.STDERR, tonumber(count_now) );
            
            if count_now == nil then
                limit_dict:set( key, 1, tonumber(time) )
                count_now = 0
            end
            
            limit_dict:incr( key, 1 )

            if count_now > tonumber(count) then
                ngx.log(ngx.ERR, "Action is "..rule['action'])
                if rule['action'] ~= 'captcha' then
                    if rule['response'] ~= nil then
                        ngx.status = tonumber( rule['code'] )
                        response = response_list[rule['response']]
                        if response ~= nil then
                            ngx.header.content_type = response['content_type']
                            ngx.say( response['body'] )
                        end
                    ngx.log(ngx.STDERR,rule['matcher'],' ',rule['action'],' ',rule['code'],' ',rule['response'])
                        ngx.exit( ngx.HTTP_OK )
                    else
                    ngx.log(ngx.STDERR,rule['matcher'],' ',rule['action'],' ',rule['code'],' ',rule['response'])
                        ngx.exit( tonumber( rule['code'] ) )
                    end
                else 
                    captcha.freqCheck(key, time)
                end
            end
            
            return
        end
    end
end

return _M

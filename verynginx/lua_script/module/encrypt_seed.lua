-- -*- coding: utf-8 -*-
-- -- @Date    : 2016-02-02 13:37
-- -- @Author  : Alexa (AlexaZhou@163.com)
-- -- @Link    : 
-- -- @Disc    : auto generate encrypt_seed

local VeryNginxConfig = require "VeryNginxConfig"
local dkjson = require "dkjson"


local _M = {}
_M.seed = nil

function _M.get_seed()

    --return seed from memory
    if _M.seed ~= nil then
        return _M.seed
    end
    
    --return saved seed
    local seed_path = VeryNginxConfig.home_path() .. "/configs/encrypt_seed.json"
    
    local file = io.open( seed_path, "r")
    if file ~= nil then
        local data = file:read("*all");
        file:close();
        local tmp = dkjson.decode( data )

        _M.seed = tmp['encrypt_seed']

        return _M.seed
    end


    --if no saved seed, generate a new seed and saved
--    _M.seed = ngx.md5( ngx.now() )
    _M.seed = _M.generate()
    local new_seed_json = dkjson.encode( { ["encrypt_seed"]= _M.seed }, {indent=true} )
    local file,err = io.open( seed_path, "w")
    
    if file ~= nil then
        file:write( new_seed_json )
        file:close()
        return _M.seed
    else
        ngx.log(ngx.STDERR, 'save encrypt_seed failed' )
        return ''
    end
        
end

function _M.generate()
    local template ="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    local d = io.open("/dev/urandom", "r"):read(4)
    math.randomseed(os.time() + d:byte(1) + (d:byte(4) * 256) + (d:byte(2) * 65536) + (d:byte(3) * 4294967296))
    local uuid=string.gsub(template, "x",
        function (c)
            local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
            return string.format("%x", v)
        end
    )
    return uuid
end

return _M

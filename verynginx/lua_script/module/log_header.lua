--version 0.5.1  last update 20190923
--todo: add switch for req_header read

local VeryNginxConfig = require "VeryNginxConfig"

local _M = {}

function _M.run()

    if VeryNginxConfig.configs["log_header_enable"] ~= true then
        return
    end

    local h = ngx.req.get_headers()
    for k, v in pairs(h) do
        if v == "table" then
            ngx.var.req_header_string = ngx.var.req_header_string ..k.."="
            for m,n in pairs(v) do
                ngx.var.req_header_string = ngx.var.req_header_string .. m.."="..n.." "
            end
        else
            ngx.var.req_header_string = ngx.var.req_header_string .. k.."="..v.." "
        end
    end

end

return _M
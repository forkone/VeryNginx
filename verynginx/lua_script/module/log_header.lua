--version 0.5.1  last update 20190923
--todo: add switch for req_header read

local VeryNginxConfig = require "VeryNginxConfig"

local _M = {}

function _M.run()

    local h = ngx.req.get_headers()
    for k, v in pairs(h) do
        if v == "table" then
            ngx.var.req_header = ngx.var.req_header ..k.."="
            for m,n in pairs(v) do
                ngx.var.req_header = ngx.var.req_header .. m.."="..n.." "
            end
        else
            ngx.var.req_header = ngx.var.req_header .. k.."="..v.." "
        end
    end

end

return _M
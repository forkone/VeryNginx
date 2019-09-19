--version 0.5.1  last update 20190911

local _M = {}

local balancer = require "ngx.balancer"

function _M.run()
    ngx.log(ngx.INFO, "balancer target: ",ngx.var.vn_proxy_host, ngx.var.vn_proxy_port)
    local ok, err = balancer.set_current_peer(ngx.var.vn_proxy_host, ngx.var.vn_proxy_port)
    if not ok then
        ngx.log(ngx.ERR, "failed to set the current peer: ", err)
        return ngx.exit(500)
    end

    return
end

_M.run()

return _M


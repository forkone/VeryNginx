#version 0.5.1  last update 20190923

set $vn_exec_flag '';       #set in router.lua and backend_static.lua/backend_proxy.lua, check in on_rewrite.lua and on_access.lua for skip filter
set $vn_ctx_dump '';        #transport ngx.ctx in ngx.var

#for proxy_pass backend
set $vn_proxy_scheme '';    #read in location @vn_proxy
set $vn_upstream_uri '';    #read in location @vn_proxy
set $vn_header_host '';     #read in location @vn_proxy
set $vn_proxy_host '';      #read in vn_upstream - on_banlance.lua - balancer.set_current_peer( ngx.var.vn_proxy_host , ngx.var.vn_proxy_port )
set $vn_proxy_port '';      #read in vn_upstream - on_banlance.lua - balancer.set_current_peer( ngx.var.vn_proxy_host , ngx.var.vn_proxy_port )

#for static file backend
set $vn_static_expires '1h';     #read in location @vn_static
set $vn_static_root '';          #read in location @vn_static


set $req_header "";
set $req_body "";
header_filter_by_lua_block {
    --read request header
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

    --read request post budy
    ngx.req.read_body()
    post_args, err = ngx.req.get_post_args()
    if post_args == nil then
        return
    end

    for k,v in pairs(post_args) do
        if v == "table" then
            ngx.var.req_body = ngx.var.req_body ..k.."="
            for m,n in pairs(v) do
                ngx.var.req_body = ngx.var.req_body .. m.."="..n.." "
            end
        else
            ngx.var.req_body = ngx.var.req_body .. k.."="..v.." "
        end
    end

}


location @vn_static {
    expires $vn_static_expires;
    root $vn_static_root;
}

location @vn_proxy {
    proxy_set_header Host $vn_header_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header User-Agent $http_user_agent;
    proxy_pass $vn_proxy_scheme://vn_upstream$vn_upstream_uri;
    proxy_ssl_verify off;
}



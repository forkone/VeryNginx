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


#access_log   logs/access_$http_host airlog04;
#error_log    logs/error_$http_host error;

set $req_header "";
#set $req_body "";


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



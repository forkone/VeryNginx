--version 0.5.1  last update 20190917

local util = require "util"
local VeryNginxConfig = require "VeryNginxConfig"
local scheme_lock = require "scheme_lock"
local redirect = require "redirect"
local uri_rewrite = require "uri_rewrite"

if ngx.var.vn_exec_flag and ngx.var.vn_exec_flag ~= '' then
    util.ngx_ctx_load()
    return
end

--At first , make sure every request use latest running config
--Actually execute VeryNginx load_from_file
VeryNginxConfig.update_config()

scheme_lock.run()
redirect.run()
uri_rewrite.run()

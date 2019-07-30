
local every_update = require "every_update"

ngx.log(ngx.ERR, "begin init worker lua file");

every_update.blackip()

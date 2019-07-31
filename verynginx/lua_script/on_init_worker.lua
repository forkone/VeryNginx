
local blackip = require "blackip"

ngx.log(ngx.ERR, "begin init worker lua file");

blackip.every_update()

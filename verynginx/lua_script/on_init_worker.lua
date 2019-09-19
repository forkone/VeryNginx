--version 0.5.1  last update 20190917

local VeryNginxConfig = require "VeryNginxConfig"
local blackip = require "blackip"

blackip.every_update()
VeryNginxConfig.every_update()

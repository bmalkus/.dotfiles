require("conf.opts")
require("conf.maps")
require("conf.autocmd")
require("conf.cmds")
pcall(require, "conf.local")

require("conf.lazy")

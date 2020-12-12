-- resty/lua/resp.lua

local cjson = require('cjson.safe')
cjson.encode_empty_table_as_object(false)

local M = {}

function M.fail(msg, detail, status)
  if status then ngx.status = status end
  ngx.say(cjson.encode({ msg = msg, detail = detail }))
  if status then ngx.exit(status) end
end

return M
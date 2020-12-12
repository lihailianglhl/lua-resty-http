-- resty/lua/requests.lua

local http = require('resty.http')
local cjson = require('cjson.safe')
cjson.encode_empty_table_as_object(false)

local errors = {
  UNAVAILABLE = 'upstream-unavailable',
  QUERY_ERROR = 'query-failed'
}

local M = { errors = errors }

local function request(method)
  return function(url, payload, headers)
    headers = headers or {}
    headers['Content-Type'] = 'application/json'
    local httpc = http.new()
    local params = { headers = headers, method = method }
    if method == 'GET' then params.query = payload
    else params.body = payload end
    local res, err = httpc:request_uri(url, params)
    ngx.say(err)
    if err then
      ngx.log(ngx.ERR, table.concat(
        {method .. ' fail', url, payload}, '|'
      ))
      return nil, nil, errors.UNAVAILABLE
    else
      if res.status >= 400 then
        ngx.log(ngx.ERR, table.concat({
          method .. ' fail code', url, res.status, res.body,
        }, '|'))
        return res.status, res.body, errors.QUERY_ERROR
      else
        return res.status, res.body, nil
      end
    end
  end
end

M.jget = request('GET')
M.jput = request('PUT')
M.jpost = request('POST')

return M
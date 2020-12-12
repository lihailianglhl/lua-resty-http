-- resty/lua/oauth.lua

local cjson = require('cjson.safe')
local resp = require('resty.resp')
local requests = require('resty.request')
cjson.encode_empty_table_as_object(false)

local M = {}
local _conf = nil

local function code_url()
  local params = ngx.encode_args({
    client_id = _conf.client_id,
    redirect_uri = _conf.redirect_uri,
    scope = _conf.scope,
  })
  return _conf.code_endpoint .. '?' .. params
end


local function get_token(code)
  local payload = {
    client_id = _conf.client_id,
    client_secret = _conf.client_secret,
    code = code,
  }
  local status, body, err = requests.jpost(_conf.token_endpoint, cjson.encode(payload))
  if not status then resp.fail(err, _conf.token_endpoint, ngx.HTTP_SERVICE_UNAVAILABLE)
  else
      if status ~= 200 then resp.fail(err, cjson.decode(body), status)
      else return ngx.decode_args(body).access_token end
  end
end

local function get_profile(token)
  local status, body, err = requests.jget(
    _conf.profile_endpoint, '',
    { Authorization = 'token ' .. token })
  if not status then resp.fail(err, _conf.profile_endpoint, ngx.HTTP_SERVICE_UNAVAILABLE)
  else
      if status ~= 200 then resp.fail(err, cjson.decode(body), status)
      else return cjson.decode(body) end
  end
end



function M.get_code()
  return ngx.redirect(code_url())
end

function M.get_profile(code)
  local token = get_token(code)
  local profile = get_profile(token)
  ngx.say(cjson.encode(profile))
  return cjson.encode(profile)
end




function M.init(conf)
  _conf = conf
end

return M
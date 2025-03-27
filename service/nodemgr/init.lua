local skynet = require "skynet"
local s = require "service"

s.rep.newservice = function(source, name, ...)
    local srv = skynet.newservice(name, ...)
    skynet.error("Created new service: ", srv)
    -- 确保 srv 是有效的服务地址
    assert(srv, "Failed to create new service")
    return srv
end

s.start(...)

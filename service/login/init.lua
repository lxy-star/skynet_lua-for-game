local skynet = require "skynet"
-- local runconfig = require "runconfig"
local service = require "service"

service.client = {}
service.rep.client = function(source, fd, cmd, msg)
    if not service.client[cmd] then
        skynet.error("login's client haven't the cmd: " .. cmd)
    else
        local ret_msg = service.client[cmd](fd, msg, source)
        skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
    end

end

service.client.login = function(fd, msg, source)
    local playerid = tonumber(msg[2])
    local pw = tonumber(msg[3])
    local gate = source
    node = skynet.getenv("node")
    if pw ~= 123 then
        return {"login", 1, "密码错误"}
    end
    -- agentmgr来仲裁
    local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
    if not isok then
        return {"login", 1, "请求agentmgr失败"}
    end
    -- 成功回应gateway
    local isok = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
    if not isok then
        return {"login", 1, "gateway 网关注册失败"}
    end
    skynet.error("login succ " .. playerid)
    return {"login", "0", "登录成功"}
end

service.start(...)

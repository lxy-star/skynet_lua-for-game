local skynet = require "skynet"
local service = require "service"

service.client = {}
service.gateway = nil

require "scene"

service.rep.client = function(source, cmd, msg)
    service.gateway = source
    if service.client[cmd] then
        local ret_msg = service.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", service.id, ret_msg)
        end
    else
        skynet.error("service.rep.client fail", cmd)
    end
end

service.client.work = function(msg, source)
    service.data.coin = service.data.coin + 1
    return {"work", service.data.coin}
end

service.rep.kick = function(source)
    service.leave_scene()
	--在此处保存角色数据
    skynet.sleep(200)
end

service.rep.exit = function(source)
    skynet.exit()
end

service.rep.send = function(source, msg)
    skynet.send(service.gateway, "lua", "send", service.id, msg)
end

service.init = function()
    --playerid = s.id
	--在此处加载角色数据
    skynet.sleep(100)
    service.data = {
        coin = 100,
        hp = 200
    }
end

service.start(...)

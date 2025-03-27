local service = require "service"
local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"

local shutdown_gateway = function()
    for k, v in pairs(runconfig.cluster) do
        for i, j in pairs(runconfig[k].gateway or {}) do
            local gateway = "gateway" .. i
            service.call(k, gateway, "shutdown")
        end
    end
end

local shutdown_agent = function()
    local anode = runconfig.agentmgr.node
    while true do
        local online_num = service.call(anode, "agentmgr", "shutdown", 1)
        if online_num <= 0 then
            break
        end
        skynet.sleep(100)
    end
end

local stop = function()
    shutdown_gateway()
    shutdown_agent()
    skynet.abort()
    return "ok"
end

local connect = function(fd, addr)
    print("new connect form addr: " .. tostring(addr) .. " fd: " .. fd)
    socket.start(fd)
    socket.write(fd, "Please enter cmd\r\n")
    local cmd = socket.readline(fd, "\r\n")
    if cmd == "stop" then
        stop()
    else
        -- ......
    end
end

service.init = function()
    local listenfd = socket.listen("127.0.0.1", 8888)
    socket.start(listenfd, connect)
end

service.start(...)

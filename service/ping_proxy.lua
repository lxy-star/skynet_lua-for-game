local skynet = require "skynet"
local cluster = require "skynet.cluster"
local mynode = skynet.getenv("node")

local CMD = {}

-- 启动时获取目标服务的代理
function CMD.start(source, target_node, target_name)
    -- 创建远程服务代理（node2 的 pong 服务）
    local target_proxy = cluster.proxy(target_node, target_name)
    -- 通过代理直接调用方法
    target_proxy.ping(mynode, skynet.self(), 1)
end

-- 处理 Ping 消息
function CMD.ping(source, source_node, source_srv, count)
    local id = skynet.self()
    skynet.error("[" .. id .. "] recv ping count: " .. count)
    skynet.sleep(100)

    -- 动态创建调用方的代理
    local source_proxy = cluster.proxy(source_node, source_srv)
    -- 通过代理回复
    source_proxy.ping(mynode, skynet.self(), count + 1)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd])
        f(source, ...)
    end)
end)

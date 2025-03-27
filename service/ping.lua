local skynet = require "skynet"
local cluster = require "skynet.cluster"
local mynode = skynet.getenv("node")

local CMD = {}
local MAX_COUNT = 10  -- 最大 ping 次数

-- 启动跨节点 ping
function CMD.start(source, target_node, target_service)
    skynet.error("Start pinging from ["..mynode.."] to "..target_node.."/"..target_service)
    cluster.send(target_node, target_service, "ping", mynode, skynet.self(), 1)
end

-- 处理 ping 消息
function CMD.ping(source, source_node, source_service, count)
    local self_id = skynet.self()
    skynet.error("[" .. self_id .. "] recv ping count: " .. count)
    
    -- 添加延迟防止消息风暴
    skynet.sleep(50)  -- 50 * 10ms = 500ms
    
    if count < MAX_COUNT then
        cluster.send(source_node, source_service, "ping", mynode, self_id, count + 1)
    else
        skynet.error("[" .. self_id .. "] reach max count, stop.")
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local func = CMD[cmd]
        if not func then
            skynet.error("Unknown command:", cmd)
            return
        end
        func(source, ...)
    end)
end)

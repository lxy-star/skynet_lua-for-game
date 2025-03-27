local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

skynet.start(function()
    skynet.error("[start main1] cluster init")

    -- 统一配置集群节点（包含自身节点）
    cluster.reload({
        node1 = "127.0.0.1:7001",
        node2 = "127.0.0.1:7002"
    })

    local node = skynet.getenv("node")
    cluster.open(node) -- 所有节点都需要打开自身集群端口

    if node == "node1" then
        skynet.newservice("debug_console", 8000) -- 控制台端口避免冲突
        -- 创建两个 ping 服务并启动
        local ping1 = skynet.newservice("ping")
        local ping2 = skynet.newservice("ping")
        skynet.send(ping1, "lua", "start", "node2", "pong")
        skynet.send(ping2, "lua", "start", "node2", "pong")
    elseif node == "node2" then
        skynet.newservice("debug_console", 8001)
        -- 创建 pong 服务并注册到全局
        local pong = skynet.newservice("ping")
        skynet.name("pong", pong) -- 使用 cluster.register 跨节点注册
    end

end)

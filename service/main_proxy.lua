local skynet = require "skynet"
local cluster = require "skynet.cluster"
require "skynet.manager"

skynet.start(function()
    skynet.error("[start main] hello world")
    -- 集群配置
    cluster.reload({
        node1 = "127.0.0.1:7001",
        node2 = "127.0.0.1:7002"
    })
    local node = skynet.getenv("node")

    if node == "node1" then
        cluster.open("node1") -- 开放本节点集群端口
        skynet.newservice("debug_console", 8000) -- 控制台

        -- 启动两个 Ping 服务
        local ping1 = skynet.newservice("ping_proxy")
        local ping2 = skynet.newservice("ping_proxy")

        -- 告知 ping 服务目标为 node2 的 pong 服务
        skynet.send(ping1, "lua", "start", "node2", "pong")
        skynet.send(ping2, "lua", "start", "node2", "pong")

    elseif node == "node2" then
        cluster.open("node2") -- 开放本节点集群端口
        skynet.newservice("debug_console", 8001) -- 控制台

        -- 启动 Pong 服务并注册全局名称
        local pong = skynet.newservice("ping_proxy")
        skynet.name("pong", pong) -- 注册为全局名称 "pong"
    end
end)

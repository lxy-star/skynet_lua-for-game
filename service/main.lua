local skynet = require "skynet"
local runconfig = require "runconfig"
local skynet_manager = require "skynet.manager"
local cluster = require "skynet.cluster"

skynet.start(function()
    skynet.error("[start main] : " .. runconfig.agentmgr.node)
    local mynode = skynet.getenv("node")
    local nodeconfig = runconfig[mynode]
    -- 节点管理
    local nodemgr = skynet.newservice("nodemgr", "nodemgr", 0)
    skynet.name("nodemgr", nodemgr)
    -- 集群管理
    cluster.reload(runconfig.cluster)
    cluster.open(mynode)
    -- gateway
    for k, v in pairs(nodeconfig.gateway or {}) do
        local srv = skynet.newservice("gateway", "gateway", k)
        skynet.name("gateway" .. k, srv)
    end
    -- login
    for k, v in pairs(nodeconfig.login or {}) do
        local srv = skynet.newservice("login", "login", k)
        skynet.name("login" .. k, srv)
    end
    -- agentmgr
    local agentmgrnode = runconfig.agentmgr.node
    if mynode == agentmgrnode then
        local srv = skynet.newservice("agentmgr", "agentmgr", 0)
        skynet.name("agentmgr", srv)
    else
        local proxy = cluster.proxy(agentmgrnode, "agentmgr")
        skynet.name("agentmgr",proxy)
    end
    --scene
    for k,v in pairs(runconfig.scene[mynode]) do
        local srv = skynet.newservice("scene","scene",v)
        skynet.name("scene"..v,srv)
    end
    --admin
    local adminnode = "node1"
    if mynode == adminnode then
        local srv = skynet.newservice("admin","admin",0)
        skynet.name("admin",srv)
    end
    --退出自身
    skynet.exit()
end)

local skynet = require "skynet"
local service = require "service"

local players = {}

STATUS = {
    LOGIN = 2,
    GAME = 3,
    LOGOUT = 4
}

function mgrplayer()
    local m = {
        playerid = nil,
        status = nil,
        gateway = nil,
        agent = nil
    }
    return m
end

function get_online_count()
    local count = 0
    for k, v in pairs(players) do
        count = count + 1
    end
    return count
end

service.rep.shutdown = function(source, num)
    local count = get_online_count()
    local n = 0
    for k, v in pairs(players) do
        skynet.fork(service.rep.reqkick, nil, k, "close service")
        n = n + 1
        if n >= num then
            break
        end
    end
    -- 等待玩家数下降
    while true do
        skynet.sleep(200)
        local new_count = get_online_count()
        skynet.error("shutdown online:" .. new_count)
        if new_count <= 0 or new_count <= count - num then
            return new_count
        end
    end
end

service.rep.reqlogin = function(source, playerid, node, gateway)
    local mplayer = players[playerid]
    -- 登录，登出过程中忽视重复操作
    if mplayer and mplayer.status == STATUS.LOGOUT then
        skynet.error("reqlogin fail, at status LOGOUT " .. playerid)
        return false
    elseif mplayer and mplayer.status == STATUS.LOGIN then
        skynet.error("reqlogin fail, at status LOGIN " .. playerid)
        return false
    end
    -- 在线，顶替
    if mplayer then
        local agent = mplayer.agent
        local gateway = mplayer.gateway
        local node = mplayer.node
        mplayer.status = STATUS.LOGOUT
        service.call(node, agent, "kick")
        service.send(node, agent, "exit")
        service.send(node, gateway, "send", playerid, {"kick", "被顶替下线了"})
        service.call(node, gateway, "kick", playerid)
    end
    -- 上线
    local mplayer = mgrplayer()
    mplayer.playerid = playerid
    mplayer.status = STATUS.LOGIN
    mplayer.gateway = gateway
    mplayer.agent = nil
    mplayer.node = node
    players[playerid] = mplayer
    skynet.error("Calling nodemgr:newservice for playerid: ", playerid)
    local agent = service.call(node, "nodemgr", "newservice", "agent", "agent", playerid)
    if not agent then
        skynet.error("Failed to create new agent: ", node, "nodemgr")
        return false
    end
    skynet.error("New agent created: ", agent)
    mplayer.agent = agent
    mplayer.status = STATUS.GAME
    return true, agent
end

service.rep.reqkick = function(source, playerid, reason)
    local mplayer = players[playerid]
    if not mplayer then
        return false
    end

    if mplayer.status ~= STATUS.GAME then
        return false
    end

    local pnode = mplayer.node
    local pagent = mplayer.agent
    local pgate = mplayer.gate
    mplayer.status = STATUS.LOGOUT

    service.call(pnode, pagent, "kick")
    service.send(pnode, pagent, "exit")
    service.send(pnode, pgate, "kick", playerid)
    players[playerid] = nil

    return true
end

service.start(...)

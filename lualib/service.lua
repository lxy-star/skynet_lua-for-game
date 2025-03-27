local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
    -- 类型和id
    name = "",
    id = 0,
    -- 回调函数
    exit = nil,
    init = nil,
    -- 消息处理
    rep = {}
}

function traceback(error)
    skynet.error(tostring(error))
    skynet.error(debug.traceback())
end

local function formatResult(ret)
    local formatted = {}
    for i = 2, #ret do -- 从索引 2 开始，跳过第一个布尔值
        table.insert(formatted, tostring(ret[i])) -- 将每个元素转换为字符串
    end
    return table.concat(formatted, ", ") -- 使用逗号和空格作为分隔符
end

local dispatch = function(session, source, cmd, ...)
    -- 获取与命令对应的函数
    local func = M.rep[cmd]

    -- 如果没有找到对应命令的函数
    if not func then
        -- 如果是 skynet.call 发起的调用，则需要返回 nil
        if session ~= 0 then
            skynet.ret()
        end
        return
    end

    -- 使用 xpcall 调用目标函数，并捕获任何可能的错误
    local ret = table.pack(xpcall(func, traceback, source, ...))
    local isok = ret[1] -- 第一个返回值表示是否成功执行

    -- 如果执行失败
    if not isok then
        if session ~= 0 then
            skynet.ret() -- 返回空响应给调用者
        end
        return
    end

    -- 如果是 skynet.call 发起的调用，则需要打包并返回结果
    if session ~= 0 then
        -- 记录日志
        skynet.error(source .. " Dispatch result:", formatResult(ret))
        skynet.retpack(table.unpack(ret, 2)) -- 从第二个元素开始解包，因为第一个是成功标志
    end
end

function M.call(node, srv, ...)
    local mynode = skynet.getenv("node")
    if mynode == node then
        local result = skynet.call(srv, "lua", ...)
        skynet.error("service.call (local) returned:", tostring(result))
        return result
    else
        local result = cluster.call(node, srv, ...)
        skynet.error("service.call (remote) returned:", tostring(result))
        return result
    end
end

function M.send(node, srv, ...)
    local mynode = skynet.getenv("node")
    if (mynode == node) then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, ...)
    end
end

function init()
    skynet.dispatch("lua", dispatch)
    if M.init then
        M.init()
    end
end

function M.start(name, id, ...)
    M.name = name
    M.id = tonumber(id)
    skynet.start(init)
end

return M

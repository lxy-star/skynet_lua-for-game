local skynet = require "skynet"
local socket = require "skynet.socket"

local clients = {}

function connect(fd, addr)
    clients[fd] = true -- 标记客户端已连接
    print(fd .. " connected from " .. addr)
    socket.start(fd)

    while true do
        local success, readdata = pcall(socket.read, fd) -- 使用 pcall 包装以捕获潜在错误
        if not success then
            -- 如果发生错误，可能是连接已被关闭或其他原因
            print(fd .. " error: ", readdata)
            break
        elseif readdata == nil then
            -- 如果 readdata 是 nil，表示暂时没有数据可读，可以继续等待
            skynet.sleep(10) -- 添加一个小延时避免忙等
            goto continue -- 跳过后续逻辑，回到循环开始
        elseif readdata == false then
            -- 如果 readdata 是 false，表示连接已关闭
            print(fd .. " closed")
            break
        end

        -- 确保 readdata 是字符串类型
        if type(readdata) == "string" then
            print(fd .. " received " .. readdata)
            for clientfd in pairs(clients) do
                if clientfd ~= fd then
                    local ok, err = pcall(socket.write, clientfd, fd .. " send message: " .. readdata)
                    if not ok then
                        print("Failed to write to client ", clientfd, "error:", err)
                    end
                end
            end
            local ok, err = pcall(socket.write, fd, "server reply: " .. readdata)
            if not ok then
                print("Failed to write back to client ", fd, "error:", err)
            end
        else
            print(fd .. " unexpected readdata type: ", type(readdata))
        end

        ::continue::
    end

    -- 清理工作
    clients[fd] = nil
    socket.close(fd)
end

skynet.start(function()
    skynet.error("[start main2] hello world")
    local listen_fd = socket.listen("0.0.0.0", 8888)
    skynet.error("Listening on 0.0.0.0:8888")
    socket.start(listen_fd, function(id, addr)
        skynet.fork(connect, id, addr) -- 对每个新连接启动一个新协程
    end)
end)
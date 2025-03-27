local skynet = require "skynet"
local mysql = require "skynet.db.mysql"

skynet.start(function ()
    skynet.error("[start main] hello world")

    -- 连接到 MySQL 数据库
    local db = mysql.connect({
        host = "127.0.0.1",
        port = 3306,
        database = "test",
        user = "test",
        password = "123456",
        max_packet_size = 1024 * 1024,
        on_connect = nil
    })

    if not db then
        skynet.error("Failed to connect to MySQL")
        skynet.exit()
        return
    end

    -- 创建 users 表（如果不存在）
    db:query([[
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT,
            name VARCHAR(100),
            PRIMARY KEY (id)
        )
    ]])

    -- 插入数据
    local res, err = db:query("INSERT INTO users(name) VALUES ('lxy')")
    if err then
        skynet.error("Insert error: ", err)
    else
        skynet.error("Inserted new user")
    end

    -- 查询数据
    res, err = db:query('SELECT * FROM users')
    if err then
        skynet.error("Select error: ", err)
    else
        for i, v in ipairs(res) do
            print(i, v.id, v.name)
        end
    end

    -- 关闭数据库连接
    db:disconnect()

    skynet.exit()
end)
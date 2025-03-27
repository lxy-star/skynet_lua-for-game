return {
    cluster = {
        node1 = "127.0.0.1:7001",
        node2 = "127.0.0.1:7002",
    },
    --agentmgr
    agentmgr = {node = "node1"},
    --scene
    scene = {
        node1 = {1001,1003},
        node2 = {1002},
    },
    --节点
    node1 = {
        gateway = {
            [1]  = {port = 8001},
            [2] = {port = 8002},
        },
        login = {
            [1] = {},
            [2] = {},
        },
    },
    node2 = {
        gateway = {
            [1] = {port = 8011},
            [2] = {port = 8022},
        },
        login =  {
            [1] = {},
            [2] = {},
        }
    }
}

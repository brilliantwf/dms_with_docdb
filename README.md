# DocumentDB DMS 数据同步项目

## 🎯 项目目标
将源DocumentDB集群中的特定集合数据同步到目标集群的指定数据库中，实现数据合并和重命名。

## 🏗️ 架构概览

### AWS资源配置
```
源集群: docdb-source-cluster
├── 数据库: gamedb
    ├── players-S1toS5 (509条记录)
    ├── equipments-S1toS5 (503条记录)
    └── mails-S1toS5 (503条记录)

目标集群: docdb-target-cluster
├── 数据库: gamedb-S6toS10
    ├── 原有数据:
    │   ├── players-S6toS10 (200条)
    │   ├── equipments-S6toS10 (200条)
    │   └── mails-S6toS10 (200条)
    └── DMS同步数据:
        ├── players-merged (509条) ✅
        └── equipments-merged (503条) ✅

DMS复制实例: docdb-dms-instance
EC2客户端: docdb-client-instance
```

## 🔧 DMS配置详解

### 1. 端点配置

#### 源端点 (docdb-source-endpoint)
```json
{
  "EndpointType": "SOURCE",
  "EngineName": "docdb",
  "ServerName": "<source-cluster-endpoint>",
  "Port": 27017,
  "DatabaseName": "gamedb",
  "Username": "<username>",
  "SslMode": "verify-full"
}
```

#### 目标端点 (docdb-target-endpoint)
```json
{
  "EndpointType": "TARGET", 
  "EngineName": "docdb",
  "ServerName": "<target-cluster-endpoint>",
  "Port": 27017,
  "DatabaseName": "gamedb-S6toS10",
  "Username": "<username>",
  "SslMode": "verify-full"
}
```

### 2. 表映射规则 (TableMappings)

关键配置文件：`table-mappings-final.json`

```json
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "select-players-table",
      "object-locator": {
        "schema-name": "gamedb",
        "table-name": "players-S1toS5"
      },
      "rule-action": "include"
    },
    {
      "rule-type": "selection", 
      "rule-id": "2",
      "rule-name": "select-equipments-table",
      "object-locator": {
        "schema-name": "gamedb",
        "table-name": "equipments-S1toS5"
      },
      "rule-action": "include"
    },
    {
      "rule-type": "transformation",
      "rule-id": "3", 
      "rule-name": "rename-players-table",
      "rule-target": "table",
      "object-locator": {
        "schema-name": "gamedb",
        "table-name": "players-S1toS5"
      },
      "rule-action": "rename",
      "value": "players-merged"
    },
    {
      "rule-type": "transformation",
      "rule-id": "4",
      "rule-name": "rename-equipments-table", 
      "rule-target": "table",
      "object-locator": {
        "schema-name": "gamedb",
        "table-name": "equipments-S1toS5"
      },
      "rule-action": "rename",
      "value": "equipments-merged"
    }
  ]
}
```

## 📊 数据流向图

```
源集群 gamedb 数据库                    目标集群 gamedb-S6toS10 数据库
┌─────────────────────┐                ┌──────────────────────────┐
│ players-S1toS5      │ ──────────────→│ players-merged           │
│ (509条记录)          │   DMS同步+重命名  │ (509条记录)               │
└─────────────────────┘                └──────────────────────────┘

┌─────────────────────┐                ┌──────────────────────────┐
│ equipments-S1toS5   │ ──────────────→│ equipments-merged        │
│ (503条记录)          │   DMS同步+重命名  │ (503条记录)               │
└─────────────────────┘                └──────────────────────────┘

┌─────────────────────┐                ┌──────────────────────────┐
│ mails-S1toS5        │ ──────────────→│ 不同步 (被排除)            │
│ (503条记录)          │      跳过       │                          │
└─────────────────────┘                └──────────────────────────┘
```

## 🔑 关键技术要点

### 1. 选择性同步
- **包含规则**: 只同步 `players-S1toS5` 和 `equipments-S1toS5`
- **排除规则**: 自动排除 `mails-S1toS5` (未在selection规则中包含)

### 2. 数据转换
- **表重命名**: 使用transformation规则将表名添加 `-merged` 后缀
- **数据库定向**: 通过目标端点的 `DatabaseName` 配置指定目标数据库

### 3. 数据合并策略
- **保留原有数据**: 目标数据库中的 `*-S6toS10` 集合保持不变
- **添加新数据**: DMS同步的数据以 `*-merged` 命名，实现数据共存

## 🚀 快速启动

### 1. 环境准备
```bash
# 确保已配置AWS CLI和相关权限
aws configure list

# 准备SSL证书文件
cp global-bundle.pem /path/to/project/
```

### 2. 启动演示服务器
```bash
# 启动演示服务
./start_demo_generic.sh

# 停止服务
pkill -f python3
```

### 3. 访问演示界面
- 本地访问: http://localhost:3000

## 🔧 DMS任务管理

### 启动任务
```bash
aws dms start-replication-task \
  --start-replication-task-type reload-target \
  --replication-task-arn <task-arn>
```

### 检查状态
```bash
aws dms describe-replication-tasks \
  --filters Name=replication-task-arn,Values=<task-arn>
```

### 验证数据
```javascript
// 连接目标集群验证数据
use('gamedb-S6toS10');
db.getCollectionNames().forEach(c => {
  print(c + ': ' + db[c].countDocuments({}) + ' 条记录');
});
```

## 📁 项目文件结构

```
dms_with_docdb/
├── README.md                    # 项目文档
├── start_demo_generic.sh        # 启动脚本
├── dms_demo.html               # 前端页面
├── dms_server_correct.py       # 后端服务器
├── global-bundle.pem           # SSL证书
├── table-mappings-final.json   # 最终表映射配置
├── task-settings.json          # 任务设置
└── docs/                       # 文档目录
    ├── DMS_DEMO_FINAL.md
    └── QUICK_START.md
```

## 📈 项目成果

### 数据统计
- **源数据**: players-S1toS5 (509条) + equipments-S1toS5 (503条)
- **目标数据**: players-merged (509条) + equipments-merged (503条)
- **同步成功率**: 100%
- **数据完整性**: 完全保持

### 业务价值
- **数据整合**: 实现跨集群数据合并
- **命名规范**: 通过重命名避免数据冲突
- **选择性同步**: 只同步需要的数据，提高效率
- **实时监控**: 完整的日志和状态监控体系

## 🔗 相关资源

- [AWS DMS 用户指南](https://docs.aws.amazon.com/dms/)
- [DocumentDB 开发者指南](https://docs.aws.amazon.com/documentdb/)
- [DMS 表映射规则](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.html)

---

**项目状态**: ✅ 完成并可用于演示  
**最后更新**: 2025-09-17  
**维护者**: AWS解决方案团队
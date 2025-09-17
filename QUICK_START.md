# DocumentDB DMS 快速启动指南

## 🚀 5分钟快速部署

### 前置条件
- AWS CLI 已配置
- Python 3.x 环境
- DocumentDB 集群访问权限

### 步骤1: 克隆项目
```bash
git clone https://github.com/brilliantwf/dms_with_docdb.git
cd dms_with_docdb
```

### 步骤2: 配置环境
```bash
# 下载DocumentDB证书
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem -O global-bundle.pem

# 修改服务器配置中的连接字符串
# 编辑 dms_server_correct.py 中的 SOURCE_CONN 和 TARGET_CONN
```

### 步骤3: 启动演示
```bash
# 启动演示服务器
./start_demo_generic.sh

# 访问演示界面
open http://localhost:3000
```

### 步骤4: 创建DMS资源

#### 创建源端点
```bash
aws dms create-endpoint \
  --endpoint-identifier docdb-source-endpoint \
  --endpoint-type source \
  --engine-name docdb \
  --server-name <source-cluster-endpoint> \
  --port 27017 \
  --database-name gamedb \
  --username <username> \
  --password <password> \
  --ssl-mode verify-full \
  --certificate-arn <certificate-arn>
```

#### 创建目标端点
```bash
aws dms create-endpoint \
  --endpoint-identifier docdb-target-endpoint \
  --endpoint-type target \
  --engine-name docdb \
  --server-name <target-cluster-endpoint> \
  --port 27017 \
  --database-name gamedb-S6toS10 \
  --username <username> \
  --password <password> \
  --ssl-mode verify-full \
  --certificate-arn <certificate-arn>
```

#### 创建复制任务
```bash
aws dms create-replication-task \
  --replication-task-identifier docdb-sync-task \
  --source-endpoint-arn <source-endpoint-arn> \
  --target-endpoint-arn <target-endpoint-arn> \
  --replication-instance-arn <replication-instance-arn> \
  --migration-type full-load \
  --table-mappings file://table-mappings-final.json \
  --replication-task-settings file://task-settings.json
```

### 步骤5: 启动同步
```bash
aws dms start-replication-task \
  --replication-task-arn <task-arn> \
  --start-replication-task-type start-replication
```

## 🔍 验证结果

```javascript
// 连接目标集群
use('gamedb-S6toS10');

// 查看同步结果
db.getCollectionNames().forEach(c => {
  print(c + ': ' + db[c].countDocuments({}) + ' 条记录');
});
```

## 🛠️ 故障排除

### 常见问题
1. **连接失败**: 检查安全组和VPC配置
2. **证书错误**: 确保使用正确的DocumentDB证书
3. **权限不足**: 检查IAM角色和策略

### 日志查看
```bash
# 查看CloudWatch日志
aws logs describe-log-groups --log-group-name-prefix dms-tasks

# 查看任务状态
aws dms describe-replication-tasks
```
# DocumentDB DMS 架构设计

## 系统架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   源DocumentDB   │    │   DMS复制实例    │    │  目标DocumentDB  │
│     集群        │    │                │    │     集群        │
│                │    │  ┌───────────┐  │    │                │
│ gamedb         │────┼─→│ 数据转换   │──┼────→│ gamedb-S6toS10 │
│ ├─players-S1toS5│    │  │ 表映射    │  │    │ ├─players-merged│
│ ├─equipments-S1 │    │  │ 重命名    │  │    │ ├─equipments-   │
│ └─mails-S1toS5 │    │  └───────────┘  │    │ │  merged       │
│                │    │                │    │ ├─players-S6toS10│
└─────────────────┘    └─────────────────┘    │ ├─equipments-S6 │
                                              │ └─mails-S6toS10│
                                              └─────────────────┘
```

## 核心组件

### 1. DMS复制实例
- **实例类型**: dms.t3.micro (演示用)
- **存储**: 20GB GP2
- **网络**: 私有子网，安全组开放27017端口

### 2. 源端点配置
```json
{
  "EndpointType": "SOURCE",
  "EngineName": "docdb",
  "DatabaseName": "gamedb",
  "SslMode": "verify-full"
}
```

### 3. 目标端点配置
```json
{
  "EndpointType": "TARGET",
  "EngineName": "docdb", 
  "DatabaseName": "gamedb-S6toS10",
  "SslMode": "verify-full"
}
```

## 数据流处理

### 选择性同步流程
1. **数据读取**: DMS从源集群读取指定集合
2. **规则应用**: 应用表映射和转换规则
3. **数据写入**: 写入目标集群的指定数据库
4. **监控记录**: CloudWatch记录详细日志

### 转换规则链
```
源数据 → 选择规则 → 转换规则 → 目标数据

players-S1toS5 → include → rename → players-merged
equipments-S1toS5 → include → rename → equipments-merged  
mails-S1toS5 → exclude → skip → (不同步)
```

## 网络架构

### VPC配置
- **源集群**: 私有子网A
- **DMS实例**: 私有子网B  
- **目标集群**: 私有子网C
- **EC2客户端**: 公有子网 (演示用)

### 安全组规则
```
DMS安全组:
- 出站: 27017 → DocumentDB安全组
- 入站: 无需配置

DocumentDB安全组:
- 入站: 27017 ← DMS安全组
- 入站: 27017 ← EC2安全组 (演示用)
```

## 监控与日志

### CloudWatch指标
- **CDCIncomingChanges**: CDC变更数量
- **CDCChangesMemorySource**: 内存中变更数
- **CDCChangesMemoryTarget**: 目标内存变更数
- **FreeableMemory**: 可用内存
- **CPUUtilization**: CPU使用率

### 日志组件
- **DATA_STRUCTURE**: 数据结构日志
- **SOURCE_UNLOAD**: 源数据读取日志
- **TARGET_LOAD**: 目标数据写入日志
- **TRANSFORMATION**: 数据转换日志

## 性能优化

### 任务设置优化
```json
{
  "FullLoadSettings": {
    "MaxFullLoadSubTasks": 8,
    "CommitRate": 10000,
    "TransactionConsistencyTimeout": 600
  }
}
```

### 最佳实践
1. **并行度**: 根据数据量调整子任务数
2. **提交频率**: 平衡性能和一致性
3. **内存管理**: 监控内存使用避免OOM
4. **网络优化**: 确保充足的网络带宽

## 扩展性考虑

### 水平扩展
- 多个DMS任务并行处理不同表
- 按数据分区创建多个复制任务
- 使用更大的DMS实例类型

### 高可用性
- Multi-AZ DMS实例部署
- 源和目标集群的高可用配置
- 自动故障转移机制
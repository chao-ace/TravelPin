# 云同步技术路线 (Cloud Sync Plan)

目前 CloudKit 已暂时禁用，以下是恢复云同步的技术路径和前提条件。

## 1. CloudKit 恢复方案

### 前提条件 (Prerequisites)
- [ ] 拥有有效的 Apple Developer Program 成员身份。
- [ ] 在 `Xcode -> Target -> Signing & Capabilities` 中启用了 `iCloud` 和 `CloudKit` 能力。
- [ ] 已在 CloudKit 仪表盘中通过 `iCloud.com.travelpin.app` ID 创建了相应的 Container。

### 操作步骤 (Implementation)
1. 将 `TravelPinApp.swift` 中的 `cloudKitDatabase: .none` 修改为 `.automatic`。
2. 确保 `ModelConfiguration` 有效。
3. 如果发生 `loadIssueModelContainer` 错误，检查：
    - `aps-environment` 环境变量（测试环境通常是 `development`）。
    - 确保 `spot` 之间的关系在云端可以正确映射（即全部为可选类型）。

## 2. Supabase 业务同步 (Manual Sync)

目前已有 `SyncEngine` 作为手动同步引擎，它是作为 CloudKit 的冗余或替代方案（面向非 Apple 环境或高性能业务需求）。

### 状态 (Status)
- 已实现 `TravelDTO` / `SpotDTO` 等 DTO 模型映射。
- 已配置 `SupabaseClient` 初始化。

### 下一步 (Next Steps)
1. 验证 `SyncEngine.pushLocalChanges` 的执行时机。
2. 配置 Supabase 表的 RLS (Row Level Security)，确保 `user_id` 在云端是加密隔离的。
3. 实现从 Supabase 端向本地 SwiftData 的反向拉取（Pull Action）。

## 3. 存储位置同步

为了让 Widget（小组件）显示实时行程：
- 数据库必须迁入 `App Group` 容器。
- 更新 `TravelPinApp.swift` 中的 `ModelConfiguration(url: ...)` 使用共享 URL。

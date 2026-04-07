# TravelPin 开发进度与待办事项 (April 2026)

本文件记录了解决应用启动崩溃问题的进度以及后续需要恢复/优化的功能点。

## ✅ 已解决的问题 (Fixed)

- **启动崩溃 (loadIssueModelContainer)**:
    - 移除了所有 `@Relationship` 属性的行内初始值 (`= []`)，解决了 SwiftData 宏展开冲突。
    - 统一了所有模型的 `id` 为 `@Attribute(.unique) var id: UUID`，标准化了标识符系统。
    - 修复了 `TravelPinApp` 中错误日志输出的语法错误。
    - 修正了 `Spot.swift` 中的重复属性定义。
    - 恢复了误删的 `mapSnapshot` 属性。
- **编译错误 (Macro Expansion Errors)**:
    - 移除了双向关系中冗余的 `inverse` 声明，解决了 `Circular reference` 宏死循环问题。
    - 在各模型的 `init` 方法中手动初始化了集合属性，确保符合 Swift 编译规范。
- **临时稳定性保障**:
    - 将 `cloudKitDatabase` 暂时设为 `.none`，确保即使在高不稳定的网络或配置环境下，应用也能作为本地优先应用正常启动。

## 🚀 待办事项 (To-Do)

### 1. 恢复 CloudKit 同步 (高优先级)
- **目标**: 将 `TravelPinApp.swift` 中的 `cloudKitDatabase` 恢复为 `.automatic`。
- **前提**: 
    - 需确认 Apple Developer Portal 已配置 `iCloud.com.travelpin.app` 容器。
    - 确保当前本地数据 Schema 与线上已存在的容器快照一致。
- **风险**: 若配置不正确，应用可能会再次因 `loadIssueModelContainer` 崩溃。

### 2. 重新启用 App Group 共享存储
- **目标**: 将 SwiftData 的持久化存储路径移回 `group.com.travelpin.app` 下。
- **目的**: 允许主 App 与 Widget（小组件）共享同一数据库实例。
- **步骤**: 更新 `ModelConfiguration` 以使用 `containerURL(forSecurityApplicationGroupIdentifier:)`。

### 3. 验证 Supabase 业务同步
- **状态**: 代码中已包含 `SupabaseService` 和 `SyncEngine` 的结构，但尚未进入联调阶段。
- **任务**:
    - 检查环境变量中的 Supabase Key 是否有效期。
    - 联调 `SyncEngine.pushLocalChanges` 发送数据到云端。

### 4. Widget 小组件数据展示
- **目标**: 确保 `AppState.shared.updateWidgetData` 能够正确写入共享 UserDefaults 并通知小组件刷新。
- **前提**: 需确保 App Group 基础配置稳固。

---

> [!TIP]
> 如果再次出现启动崩溃，建议按住键盘的 `Shift` 键（或在代码中显式调用 `purgeStoreFiles()`）来强制清除损坏的本地元数据。

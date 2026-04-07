# SwiftData 开发规范 (Rules of Persistence)

为了避免再次出现 `loadIssueModelContainer` 或 `Circular reference` 编译错误，在本项目中请严格遵守以下规则。

## 1. 关系定义 (Relationships)

- **禁止在声明处赋初值**：`@Relationship` 装饰的属性（尤其是集合类）必须**不能**在声明时赋值（例如 `= []`）。这会导致宏展开时的 Getter/Setter 冲突。必须在 `init()` 中进行显式赋值。
- **单向 Inverse 原则**：在双向关系的宏定义中，**只能在一侧**（通常是子级/非集合属性一侧）使用 `inverse` 参数。在另一侧仅使用 `@Relationship` 本身。
- **级联删除**：`deleteRule: .cascade` 应当由父级（如 `Travel`）持有。

## 2. 标识符系统 (Identity)

- **全量唯一化**：所有 `@Model` 实体必须包含 `@Attribute(.unique) var id: UUID`，并在 `init()` 中通过 `self.id = UUID()` 显式初始化。
- **业务对齐**：业务逻辑与持久化共用同一个 `id`，以简化 Supabase 回收和同步时的查找逻辑。

## 3. 存储配置 (Container Config)

- **云同步开发阶段隔离**：在未确认 CloudKit 容器完全配置正确前，`ModelConfiguration` 的 `cloudKitDatabase` 默认设为 `.none`。
- **App Group 预留**：如果要启用 Widget 共享，必须使用 `containerURL(forSecurityApplicationGroupIdentifier:)` 获取数据库路径。

## 4. 故障处理 (Troubleshooting)

- **强制重置**：如果启动再次崩溃，调用单例中的 `purgeStoreFiles()` 静态方法并重启应用。
- **Schema 迁移**：如果修改了属性类型而非增删属性，务必手动清除旧数据库，因为 SwiftData 的自动迁移不支持破坏性的类型变更。

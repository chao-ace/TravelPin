# TravelPin

> 为每一个灵魂的驻足，留下一份体面的底片。

TravelPin 是一款面向中国年轻旅行者的 **AI 驱动旅行内容创作工具**。它不是一个简单的打卡 App，而是一个全生命周期旅行伙伴——从灵感萌芽到规划落地，从旅途记录到归来后的记忆复盘，每一个触点都充满仪式感与极致的审美体验。

## 愿景

将冰冷的地理数据点转化为温暖的叙事海报，让每一场旅行都拥有一份 **"数字精装集"**。

去探索，去体验，去存在。To Explore, To Experience, To Exist.

## 近期更新 (2026.04)

### 交互体验全面打磨 ✨
- **引导式建旅向导**：4 步 Wizard 流程替代原有单页表单，视觉化旅行类型图标网格 + 实时名称校验
- **地图交互增强**：首次使用手势引导、路线优化前后对比视图、离线下载空间预估
- **统一手势系统**：左滑删除、右滑收藏、长按编辑、拖拽排序景点
- **灵感广场修复**：移除详情页重复的统计行，保留纯净的四图标互动栏

### 旅行闭环功能 🔄
- **NowPlaying 实时卡片**：旅行中展示当前/下一景点、距离、建议出发时间、天气穿衣、疲劳等级、进度环
- **智能日程修复**：检测时间重叠/距离过远/天气变化，提供一键修复建议
- **签到天气捕获**：打卡时自动记录温度与天气状况
- **旅行模板提取**：完成的旅行可提取为模板，一键复刻类似旅程
- **预算智能拆分**：按交通/住宿/餐饮/门票/购物分类分配预算，超支预警

### 稳定性专项修复 ✅
- **SwiftData 架构深度加固**：解决了 `loadIssueModelContainer` 初始化崩溃，标准化了模型唯一标识符系统
- **关联宏死循环修复**：通过解耦双向关系的 `inverse` 宏定义，彻底消除了编译时与运行时的循环引用风险
- **离线启动保障**：默认禁用 CloudKit 强制同步锁，允许应用在各种网络环境下秒开
- **文档体系化**：在 `Docs/` 目录下建立了完整的开发规范与同步路线图

## 核心特点

### 电影感视觉体验

- **Liquid Glass 设计语言**——毛玻璃层级 + 高对比度排版，打造通透的物理深度感
- **2.35:1 宽幅画幅**——UI 元素采用电影镜头比例，每一次浏览都是一场视觉旅行
- **胶片质感渲染**——Metal Shader 实现真实的胶片颗粒感与暖色调滤镜
- **焦点转换动效**——页面转场模拟电影焦距变换，而非简单的滑入滑出

### AI 旅行叙事

- **四种写作风格**：文艺细腻 / 纪实摘要 / 社交博主 / 要点速览
- **可插拔 AI 引擎**：支持 OpenAI、Anthropic、Apple 本地模型（FoundationModels）
- **流式输出**：文字逐字生成，本身就是一种沉浸式体验
- **智能 Prompt**：根据景点评分、花费、笔记自动生成有参考价值的旅行内容
- **AI 行程规划**：输入目的地自动生成每日行程 + 景点推荐
- **AI 打包助手**：根据目的地天气和旅行风格智能生成行李清单

### 全生命周期管理

```
灵感萌芽 → 详细规划 → 身在旅途 → 归来复盘 → 复刻新旅
```

- **旅行**：统筹每次出行的总体规划，状态流转（愿望清单 → 计划中 → 出行中 → 已出行）
- **行程**：每日行程安排，出发地 → 目的地路线追踪，拖拽排序景点
- **景点**：每个去过的或想去的地方，支持多图、评分、花费、标签、自动签到
- **行李**：分品类管理的智能打包矩阵，AI 天气推荐
- **预算**：分类预算拆分 + 超支预警 + 花费分析
- **模板**：完成旅行后提取模板，一键规划类似旅程

### 旅行中实时引导

- **NowPlaying 卡片**：实时展示当前景点进度、下一站距离与建议出发时间
- **天气感知**：接入 WeatherKit，检测到下雨时自动建议切换到室内景点
- **体力检测**：接入 HealthKit，步行超过阈值时提醒休息
- **日程冲突检测**：自动发现时间重叠、距离过远等问题并提供修复方案
- **GPS 路线追踪**：旅途中自动记录 GPS 轨迹，支持路线回放
- **Live Activity**：锁屏实时显示当前行程进度

### 灵感广场

- **社区灵感**：浏览精选旅行分享，查看行程路线与足迹亮点
- **一键复刻**：喜欢的旅程可直接 Remix 到自己的计划
- **旅行 DNA**：基于历史旅行数据生成个人旅行偏好画像
- **时光胶囊**：旅行结束后的纪念日自动推送美好回忆

### 海报导出

- **小红书 3:4 竖版**（1080×1440）——自动生成小红书风格排版
- **朋友圈 1:1 方形**（1080×1080）——模糊背景 + 精选照片条
- **通用 16:9 横版**（1920×1080）——经典电影海报布局
- 一键分享 / 保存到相册

### 离线地图

- 基于 OpenStreetMap 瓦片的交互式离线地图
- 预下载目的地瓦片，无信号也能精准定位
- 路线 Polyline 自动连接足迹
- 路线优化：自动计算最短路径并支持对比预览

## 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** (iOS 17+) | 声明式 UI 框架 |
| **SwiftData** | 本地数据持久化 |
| **MapKit** | 地图与地理编码 |
| **Metal** | 自定义胶片质感 Shader |
| **WeatherKit** | 实时天气数据 |
| **HealthKit** | 步数与体力检测 |
| **ActivityKit** | Live Activity 锁屏小组件 |
| **Supabase** | 后端服务（协作功能预留） |

## 项目结构

```
TravelPin/
├── Models/
│   ├── Travel.swift              # 旅行模型 + TravelStatus/TravelType 枚举
│   ├── Spot.swift                # 景点模型 + SpotType/SpotStatus 枚举
│   ├── Itinerary.swift           # 行程模型
│   ├── ItineraryDraft.swift      # AI 行程草稿
│   ├── LuggageItem.swift         # 行李清单模型
│   ├── PackingSuggestion.swift   # 智能打包建议
│   ├── BudgetCategory.swift      # 预算分类枚举
│   ├── NowState.swift            # 旅行中实时状态
│   ├── ScheduleFix.swift         # 日程修复建议
│   └── TripTemplate.swift        # 旅行模板
├── Services/
│   ├── AIAssistantService.swift  # AI 游记生成（流式输出）
│   ├── AIProvider.swift          # AI Provider 协议与注册中心
│   ├── AIProviderError.swift     # 错误类型定义
│   ├── AIServiceProxy.swift      # AI 服务代理
│   ├── IntelligenceService.swift # 智能建议（天气 + 体力）
│   ├── LocationService.swift     # 地理编码 + 路线优化
│   ├── TravelLogicService.swift  # 旅行逻辑（状态流转 + NowState + 冲突检测）
│   ├── MemoryService.swift       # 时光胶囊服务
│   ├── TravelDNAService.swift    # 旅行 DNA 分析
│   ├── RouteTrackingService.swift# GPS 路线追踪
│   ├── ClipboardImportService.swift # 剪贴板攻略导入
│   ├── NotificationService.swift # 通知调度
│   ├── LanguageManager.swift     # 双语本地化
│   ├── Providers/
│   │   ├── OpenAIProvider.swift
│   │   ├── AnthropicProvider.swift
│   │   └── FoundationModelsProvider.swift
│   └── ...
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift     # 首页旅行列表 + 统一手势
│   │   ├── TravelCard.swift        # 旅行卡片组件
│   │   └── FootprintReviewView.swift # 足迹数据统计
│   ├── Travel/
│   │   ├── TravelDetailView.swift  # 旅行详情（核心页面）
│   │   ├── AddTravelWizardView.swift # 4 步引导式建旅
│   │   ├── WizardSteps/            # 向导子步骤
│   │   ├── NowPlayingCard.swift    # 旅行中实时卡片
│   │   ├── ScheduleFixSheet.swift  # 日程修复面板
│   │   ├── BudgetBreakdownView.swift # 预算详情分析
│   │   ├── SpotCheckInView.swift   # 景点签到（自动天气）
│   │   ├── AIGenerationView.swift  # AI 游记生成页
│   │   ├── TripPosterView.swift    # 旅行海报
│   │   └── ...
│   ├── Map/
│   │   ├── InteractiveOfflineMap.swift # 离线交互地图
│   │   └── TravelMapView.swift        # 旅行地图（手势引导 + 路线对比）
│   ├── Social/
│   │   ├── InspirationPlazaView.swift  # 灵感广场
│   │   ├── TripResonanceDetailView.swift # 社区灵感详情
│   │   └── ...
│   ├── Luggage/
│   │   └── LuggageView.swift       # 行李管理
│   └── Settings/
│       └── SettingsView.swift      # 设置页
├── Theme/
│   ├── DesignSystem.swift         # 设计系统（颜色、字体、组件）
│   └── CinematicModifier.swift    # 电影感动效修饰器
├── Shaders/
│   └── Cinematic.metal            # Metal 胶片质感 Shader
└── Docs/
    ├── PRODUCT_SPEC.md            # 产品定义文档
    └── VISION_STRATEGY_2026.md    # 愿景与策略蓝图
```

## 开发路线

### 第一阶段：足迹版图 ✅
- SwiftData 持久化架构
- 多图景点记录
- 足迹数据统计看板

### 第二阶段：智行交互 ✅
- AI 旅行叙事（可插拔 LLM 架构）
- 路线 Polyline 可视化 + GPS 轨迹追踪
- 离线交互地图 + 下载预估
- WeatherKit + HealthKit 智能建议
- Liquid Glass 电影感动效
- Live Activity 锁屏实时进度

### 第三阶段：内容创作 ✅
- 小红书 / 朋友圈海报导出
- AI 智能行程生成
- AI 打包助手
- 预算智能拆分与预警
- 时光胶囊 / 旅行 DNA / 社区灵感

### 第四阶段：体验打磨 🚧
- 引导式建旅 Wizard + 零摩擦交互
- 统一手势系统（滑动/长按/拖拽排序）
- 地图首次使用引导 + 路线优化对比
- 日程冲突自动检测与修复

### 愿景方向 🌟
- AR 时空穿梭导览
- 同频旅伴匹配（Vibe-Matching）
- 实体画册打印
- 在地文化深度连接

## 开发环境

- **Xcode** 16+
- **iOS** 17.0+
- **Swift** 5.9+

## License

MIT License

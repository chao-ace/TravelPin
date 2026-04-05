# TravelPin

> 为每一个灵魂的驻足，留下一份体面的底片。

TravelPin 是一款面向中国年轻旅行者的 **AI 驱动旅行内容创作工具**。它不是一个简单的打卡 App，而是一个全生命周期旅行伙伴——从灵感萌芽到规划落地，从旅途记录到归来后的记忆复盘，每一个触点都充满仪式感与极致的审美体验。

## 愿景

将冰冷的地理数据点转化为温暖的叙事海报，让每一场旅行都拥有一份 **"数字精装集"**。

去探索，去体验，去存在。To Explore, To Experience, To Exist.

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

### 全生命周期管理

```
灵感萌芽 → 详细规划 → 身在旅途 → 归来复盘
```

- **旅行**：统筹每次出行的总体规划，状态流转（愿望清单 → 计划中 → 出行中 → 已出行）
- **行程**：每日行程安排，出发地 → 目的地路线追踪
- **景点**：每个去过的或想去的地方，支持多图、评分、花费、标签
- **行李**：分品类管理的智能打包矩阵

### 智能旅途助手

- **天气感知**：接入 WeatherKit，检测到下雨时自动建议切换到室内景点
- **体力检测**：接入 HealthKit，步行超过 15000 步时提醒休息
- **实时建议**：基于环境数据动态推荐下一步行动

### 海报导出

- **小红书 3:4 竖版**（1080×1440）——自动生成小红书风格排版
- **朋友圈 1:1 方形**（1080×1080）——模糊背景 + 精选照片条
- **通用 16:9 横版**（1920×1080）——经典电影海报布局
- 一键分享 / 保存到相册

### 离线地图

- 基于 OpenStreetMap 瓦片的交互式离线地图
- 预下载目的地瓦片，无信号也能精准定位
- 路线 Polyline 自动连接足迹

## 技术栈

| 技术 | 用途 |
|------|------|
| **SwiftUI** (iOS 17+) | 声明式 UI 框架 |
| **SwiftData** | 本地数据持久化 |
| **MapKit** | 地图与地理编码 |
| **Metal** | 自定义胶片质感 Shader |
| **WeatherKit** | 实时天气数据 |
| **HealthKit** | 步数与体力检测 |
| **Supabase** | 后端服务（协作功能预留） |

## 项目结构

```
TravelPin/
├── Models/
│   ├── Travel.swift          # 旅行模型 + TravelStatus/TravelType 枚举
│   ├── Spot.swift            # 景点模型 + SpotType/SpotStatus 枚举
│   ├── Itinerary.swift       # 行程模型
│   └── LuggageItem.swift     # 行李清单模型
├── Services/
│   ├── AIAssistantService.swift    # AI 游记生成（流式输出）
│   ├── AIProvider.swift            # AI Provider 协议与注册中心
│   ├── AIProviderError.swift       # 错误类型定义
│   ├── IntelligenceService.swift   # 智能建议（天气 + 体力）
│   ├── LocationService.swift       # 地理编码服务
│   ├── MapCacheService.swift       # 地图缓存管理
│   ├── Providers/
│   │   ├── OpenAIProvider.swift          # OpenAI 流式 API
│   │   ├── AnthropicProvider.swift       # Anthropic 流式 API
│   │   └── FoundationModelsProvider.swift # Apple 本地模型（iOS 26+）
│   ├── RealtimeManager.swift       # 实时协作（预留）
│   ├── SupabaseService.swift       # 后端服务（预留）
│   └── SyncEngine.swift           # 数据同步（预留）
├── Views/
│   ├── Dashboard/
│   │   ├── DashboardView.swift     # 首页旅行列表
│   │   ├── TravelCard.swift        # 旅行卡片组件
│   │   └── FootprintReviewView.swift # 足迹数据统计
│   ├── Travel/
│   │   ├── TravelDetailView.swift  # 旅行详情（核心页面）
│   │   ├── AddTravelView.swift     # 新建旅行
│   │   ├── AddItineraryView.swift  # 添加行程
│   │   ├── AddSpotView.swift       # 添加景点
│   │   ├── AIGenerationView.swift  # AI 游记生成页
│   │   ├── TripPosterView.swift    # 旅行海报
│   │   └── PosterExportView.swift  # 多格式导出
│   ├── Map/
│   │   ├── InteractiveOfflineMap.swift # 离线交互地图
│   │   └── TravelMapView.swift        # 旅行地图视图
│   ├── Social/
│   │   ├── InspirationPlazaView.swift  # 灵感广场（预留）
│   │   └── CursorOverlayView.swift    # 协作光标（预留）
│   ├── Luggage/
│   │   └── LuggageView.swift       # 行李管理
│   └── Intelligence/
│       └── IntelligenceBanner.swift # 智能建议横幅
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

### 第二阶段：智行交互 🚧
- AI 旅行叙事（可插拔 LLM 架构）
- 路线 Polyline 可视化
- 离线交互地图
- WeatherKit + HealthKit 智能建议
- Liquid Glass 电影感动效

### 第三阶段：内容创作 🔜
- 小红书 / 朋友圈海报导出
- 内置旅行模板
- AI 行程生成（"输入需求 → 生成行程"）
- 链接分享与轻量协作

### 愿景方向 🌟
- AR 时空穿梭导览
- 同频旅伴匹配（Vibe-Matching）
- 实体画册打印
- 在地文化深度连接

## 开发环境

- **Xcode** 15+
- **iOS** 17.0+
- **Swift** 5.9+

## License

MIT License

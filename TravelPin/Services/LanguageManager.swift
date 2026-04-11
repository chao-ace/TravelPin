import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    private let storageKey = "selectedLanguage"
    
    @Published var currentLanguage: AppLanguage = .simplifiedChinese {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
        }
    }
    
    private init() {
        let savedRawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.simplifiedChinese.rawValue
        if let savedLanguage = AppLanguage(rawValue: savedRawValue) {
            self.currentLanguage = savedLanguage
        }
    }
    
    // A pure Swift dictionary string resolver that guarantees instant UI updates
    func localizedString(for key: String) -> String {
        guard let stringsMap = translations[key],
              let text = stringsMap[currentLanguage] else {
            return key // Fallback to key if string doesn't exist
        }
        return text
    }
    
    // MARK: - Translation Dictionary
    private let translations: [String: [AppLanguage: String]] = [
        // Tab Bar
        "nav.journeys": [.english: "Journeys", .simplifiedChinese: "旅程"],
        "nav.footprints": [.english: "Footprints", .simplifiedChinese: "足迹"],
        "nav.discover": [.english: "Discover", .simplifiedChinese: "灵感广场"],
        "nav.settings": [.english: "Settings", .simplifiedChinese: "设置"],
        
        // Settings Page
        "settings.title": [.english: "Settings", .simplifiedChinese: "设置"],
        "settings.section.ai": [.english: "AI Assistant", .simplifiedChinese: "AI 智能助手"],
        "settings.section.account": [.english: "Account & Sync", .simplifiedChinese: "个人与账户"],
        "settings.section.preferences": [.english: "Preferences", .simplifiedChinese: "应用偏好"],
        "settings.section.storage": [.english: "Storage", .simplifiedChinese: "存储空间"],
        "settings.section.support": [.english: "Support & Legal", .simplifiedChinese: "支持与关于"],
        
        "settings.row.ai_config": [.english: "AI Model Config", .simplifiedChinese: "AI 模型配置"],
        "settings.row.icloud": [.english: "iCloud Sync", .simplifiedChinese: "iCloud 云同步"],
        "settings.row.language": [.english: "Language", .simplifiedChinese: "语言设置"],
        "settings.row.app_icon": [.english: "Change App Icon", .simplifiedChinese: "更换图标"],
        "settings.row.dark_mode": [.english: "Dark Mode", .simplifiedChinese: "深色模式"],
        "settings.row.haptic": [.english: "Haptic Feedback", .simplifiedChinese: "触感反馈"],
        "settings.row.clear_cache": [.english: "Clear Cache", .simplifiedChinese: "清除缓存"],
        "settings.row.data_mgmt": [.english: "Data Management", .simplifiedChinese: "数据管理"],
        "settings.row.rate": [.english: "Rate on App Store", .simplifiedChinese: "去 App Store 评分"],
        "settings.row.feedback": [.english: "Feedback", .simplifiedChinese: "意见反馈"],
        "settings.row.privacy": [.english: "Privacy Policy", .simplifiedChinese: "隐私政策"],
        "settings.row.terms": [.english: "Terms of Service", .simplifiedChinese: "使用条款"],
        "settings.row.cache_calculating": [.english: "Calculating...", .simplifiedChinese: "计算中..."],

        // Profile View
        "profile.title": [.english: "Profile", .simplifiedChinese: "个人资料"],
        "profile.user.name": [.english: "Designer Chao", .simplifiedChinese: "设计师 chao"],
        "profile.user.role": [.english: "Standard User", .simplifiedChinese: "普通用户"],
        "profile.user.tag": [.english: "TravelPin Explorer", .simplifiedChinese: "TravelPin 旅行家"],
        "profile.stat.journeys": [.english: "Journeys", .simplifiedChinese: "旅程"],
        "profile.stat.spots": [.english: "Spots", .simplifiedChinese: "足迹"],
        "profile.stat.photos": [.english: "Photos", .simplifiedChinese: "照片"],
        "profile.stat.cities": [.english: "Cities", .simplifiedChinese: "城市"],
        "profile.section.achievements": [.english: "Travel Achievements", .simplifiedChinese: "旅行成就"],
        "profile.achievement.first": [.english: "First Journey", .simplifiedChinese: "初次启程"],
        "profile.achievement.explorer": [.english: "World Explorer", .simplifiedChinese: "世界探索者"],
        "profile.achievement.photographer": [.english: "Photo Master", .simplifiedChinese: "摄影达人"],
        "profile.achievement.ten_trips": [.english: "10-Trip Veteran", .simplifiedChinese: "十旅达人"],
        "profile.achievement.footprints": [.english: "Footprints Everywhere", .simplifiedChinese: "足迹遍布"],
        "profile.achievement.ai": [.english: "AI Memoirs", .simplifiedChinese: "AI 旅记家"],

        // Feedback Sheet
        "feedback.title": [.english: "Feedback & Suggestions", .simplifiedChinese: "意见反馈与建议"],
        "feedback.placeholder": [.english: "Describe your feedback or feature request here...", .simplifiedChinese: "在此输入您的意见反馈或功能建议..."],
        "feedback.submit": [.english: "Submit", .simplifiedChinese: "提交"],
        "feedback.success": [.english: "Thank you for your feedback!", .simplifiedChinese: "感谢您的反馈！"],
        "feedback.error": [.english: "Please enter some content.", .simplifiedChinese: "请输入反馈内容。"],
        "feedback.type.bug": [.english: "Bug Report", .simplifiedChinese: "问题报错"],
        "feedback.type.feature": [.english: "Feature Request", .simplifiedChinese: "功能建议"],
        "feedback.type.other": [.english: "Other", .simplifiedChinese: "其他内容"],

        // Dashboard & Onboarding
        "dashboard.title": [.english: "My Journeys", .simplifiedChinese: "我的旅程"],
        "dashboard.header.title": [.english: "Travel Log", .simplifiedChinese: "旅程日志"],
        "dashboard.header.subtitle": [.english: "Every footprint is a chapter.", .simplifiedChinese: "每一次驻足，皆为序章。"],
        "dashboard.onboarding.title": [.english: "Launch Your First Journey", .simplifiedChinese: "开启首段旅程"],
        "dashboard.onboarding.subtitle": [.english: "Your cinematic log awaits.", .simplifiedChinese: "您的电影感日志正待撰写。"],
        "dashboard.onboarding.task1": [.english: "Name your dream destination", .simplifiedChinese: "为梦想目的地命名"],
        "dashboard.onboarding.task2": [.english: "Set the seasonal vibe", .simplifiedChinese: "设定季节氛围"],
        "dashboard.onboarding.task3": [.english: "Pin your first key spot", .simplifiedChinese: "钉下首个关键坐标"],
        "dashboard.empty.title": [.english: "A New Chapter Awaits", .simplifiedChinese: "新篇章正待开启"],
        "dashboard.empty.subtitle": [.english: "Start your first journey to see your footprint review.", .simplifiedChinese: "开启第一场旅程，查看您的足迹回顾。"],
        "dashboard.empty.button": [.english: "Create Journey", .simplifiedChinese: "开启旅程"],
        "dashboard.guide.create.title": [.english: "Create a Journey", .simplifiedChinese: "创建一段旅程"],
        "dashboard.guide.create.desc": [.english: "Name your dream destination and set the dates", .simplifiedChinese: "为梦想目的地命名，设定出发日期"],
        "dashboard.guide.footprint.title": [.english: "View Footprints", .simplifiedChinese: "查看旅行足迹"],
        "dashboard.guide.footprint.desc": [.english: "Review your travel stats and journey map", .simplifiedChinese: "回顾旅行统计和足迹图谱"],
        "dashboard.guide.inspiration.title": [.english: "Explore Inspirations", .simplifiedChinese: "探索旅行灵感"],
        "dashboard.guide.inspiration.desc": [.english: "Discover curated journeys from the community", .simplifiedChinese: "发现来自社区的精选旅程"],
        "dashboard.featured.badge": [.english: "Featured Trip", .simplifiedChinese: "精选回顾"],
        "dashboard.action.all": [.english: "All Journeys", .simplifiedChinese: "全部旅程"],
        "dashboard.action.view_all": [.english: "View All Journeys", .simplifiedChinese: "查看全部旅程"],
        "dashboard.search.placeholder": [.english: "Search journeys, dates...", .simplifiedChinese: "搜索旅程名称、日期..."],
        "dashboard.search.empty": [.english: "No relevant journeys found", .simplifiedChinese: "未找到相关旅程"],
        "dashboard.recent.title": [.english: "Recent Journey", .simplifiedChinese: "近期旅程"],
        "dashboard.recent.days_suffix": [.english: "d", .simplifiedChinese: " 天"],
        "dashboard.recent.spots_suffix": [.english: " spots", .simplifiedChinese: " 处足迹"],
        "dashboard.archive.search.placeholder": [.english: "Search all journeys...", .simplifiedChinese: "在全部旅程中搜索..."],
        "dashboard.archive.year_suffix": [.english: "", .simplifiedChinese: " 年"],
        "dashboard.archive.title": [.english: "All Journeys", .simplifiedChinese: "全部旅程"],
        "dashboard.workflow.stage1": [.english: "Planning", .simplifiedChinese: "旅行规划"],
        "dashboard.workflow.stage2": [.english: "Execution", .simplifiedChinese: "旅行执行"],
        "dashboard.workflow.stage3": [.english: "Review", .simplifiedChinese: "足迹回顾"],
        "dashboard.workflow.guide_suffix": [.english: " Guide", .simplifiedChinese: "指南"],

        // Footprints Review
        "footprint.title": [.english: "Footprint Review", .simplifiedChinese: "足迹回顾"],
        "footprint.header.title": [.english: "Your Journey Map", .simplifiedChinese: "你的旅程图谱"],
        "footprint.header.subtitle": [.english: "A cinematic summary of your travels.", .simplifiedChinese: "你所有旅途的电影式回顾。"],
        "footprint.stat.journeys": [.english: "Total Journeys", .simplifiedChinese: "累计旅程"],
        "footprint.stat.spots": [.english: "Spots Marked", .simplifiedChinese: "标记地点"],
        "footprint.stat.photos": [.english: "Photos Saved", .simplifiedChinese: "照片存档"],
        "footprint.stat.planning": [.english: "In Planning", .simplifiedChinese: "筹划当中"],
        "footprint.section.distribution": [.english: "Travel Distribution", .simplifiedChinese: "旅行类型图谱"],
        "footprints.section.recent": [.english: "Recent Milestones", .simplifiedChinese: "最近的里程碑"],
        "footprint.more_types": [.english: "More Types", .simplifiedChinese: "更多类型"],
        "footprint.stat.journeys_short": [.english: "Journeys", .simplifiedChinese: "旅程"],
        "footprint.stat.visited_short": [.english: "Visited", .simplifiedChinese: "去过"],

        "live.activity.start": [.english: "Start Live Tracker", .simplifiedChinese: "开启实时追踪"],
        "live.activity.stop": [.english: "Stop Live Tracker", .simplifiedChinese: "关闭实时追踪"],
        "live.activity.active": [.english: "Live Tracker Active", .simplifiedChinese: "实时追踪中"],
        "footprint.stat.photos_short": [.english: "Photos", .simplifiedChinese: "相册"],
        "footprint.stat.planning_short": [.english: "Planning", .simplifiedChinese: "策划"],

        // Footprints Stats (Legacy/Alt)
        "footprints.title": [.english: "Footprint Review", .simplifiedChinese: "足迹回顾"],
        "footprints.stats.total": [.english: "Total Countries", .simplifiedChinese: "足迹国家"],
        "footprints.stats.cities": [.english: "Cities Explored", .simplifiedChinese: "探索城市"],
        "footprints.stats.spots": [.english: "Spots Marked", .simplifiedChinese: "标记地点"],

        // Inspiration
        "inspiration.title": [.english: "Inspiration Plaza", .simplifiedChinese: "灵感广场"],
        "inspiration.header": [.english: "Discover the World", .simplifiedChinese: "探索世界"],
        "inspiration.subtitle": [.english: "Curated experiences from the global architecture.", .simplifiedChinese: "来自全球旅行者的精选体验。"],
        "luggage.action.save_as_template": [.english: "Save as Template", .simplifiedChinese: "保存为模板"],
        "luggage.action.apply_template": [.english: "Apply Template", .simplifiedChinese: "应用模板"],
        "luggage.action.copy_from_trip": [.english: "Copy from Previous Trip", .simplifiedChinese: "从历史旅行引用"],
        "luggage.title.template_library": [.english: "Template Library", .simplifiedChinese: "模版库"],
        "luggage.title.trip_history": [.english: "Trip History", .simplifiedChinese: "历史旅行"],
        "luggage.placeholder.template_name": [.english: "Template Name (e.g. Summer Beach)", .simplifiedChinese: "模板名称（例如：夏季海滩）"],
        "luggage.alert.save_template_success": [.english: "Template saved successfully", .simplifiedChinese: "模板保存成功"],
        "luggage.alert.apply_success": [.english: "Items added successfully", .simplifiedChinese: "清单项目已添加"],
        "luggage.empty.templates": [.english: "No templates yet", .simplifiedChinese: "暂无自定义模板"],

        "discover.card.remix": [.english: "Remix This Trip", .simplifiedChinese: "复刻这段旅程"],
        "inspiration.loading": [.english: "Loading inspirations...", .simplifiedChinese: "正在加载灵感..."],
        "inspiration.section.featured": [.english: "Editor's Pick", .simplifiedChinese: "编辑精选"],
        "inspiration.section.community": [.english: "Community Inspiration", .simplifiedChinese: "社区灵感"],
        "inspiration.badge.featured": [.english: "Featured", .simplifiedChinese: "精选推荐"],
        "inspiration.badge.new": [.english: "NEW", .simplifiedChinese: "NEW"],
        "inspiration.badge.developing": [.english: "Developing", .simplifiedChinese: "开发中"],
        "inspiration.empty.title": [.english: "No community content yet", .simplifiedChinese: "还没有社区内容"],
        "inspiration.empty.subtitle": [.english: "Be the first traveler to share your journey", .simplifiedChinese: "成为第一个分享旅程的旅行者"],
        "inspiration.collab.title": [.english: "Collaboration", .simplifiedChinese: "同行协作"],
        "inspiration.collab.desc": [.english: "Invite companions to edit and sync footprints in real-time", .simplifiedChinese: "邀请旅伴共同编辑行程，实时同步足迹"],
        "inspiration.reroute.title": [.english: "Dynamic Re-routing", .simplifiedChinese: "动态重路由"],
        "inspiration.reroute.desc": [.english: "AI senses weather and stamina to intelligently adjust routes", .simplifiedChinese: "AI 实时感知天气与体力，智能调整行程路线"],

        "inspiration.cat.featured": [.english: "Featured", .simplifiedChinese: "精选"],
        "inspiration.cat.nature": [.english: "Nature", .simplifiedChinese: "自然风光"],
        "inspiration.cat.culture": [.english: "Culture", .simplifiedChinese: "人文探索"],
        "inspiration.cat.food": [.english: "Food", .simplifiedChinese: "美食之旅"],
        "inspiration.cat.all": [.english: "All", .simplifiedChinese: "全部"],

        "inspiration.tag.nature": [.english: "Nature", .simplifiedChinese: "自然风光"],
        "inspiration.tag.culture": [.english: "Culture", .simplifiedChinese: "人文历史"],
        "inspiration.tag.food": [.english: "Gourmet", .simplifiedChinese: "美食探索"],

        "inspiration.stat.likes": [.english: "likes", .simplifiedChinese: "喜欢"],

        // Travel Detail
        "detail.itinerary.title": [.english: "The Itinerary", .simplifiedChinese: "行程规划"],
        "detail.itinerary.empty": [.english: "No daily plans yet.", .simplifiedChinese: "暂无每日计划"],
        "detail.archive.title": [.english: "Highlights & Archive", .simplifiedChinese: "高光时刻与存档"],
        "detail.archive.view_all": [.english: "View All", .simplifiedChinese: "查看全部"],
        "selected.count": [.english: "Selected", .simplifiedChinese: "已选择"],
        "detail.packing.title": [.english: "Packing Matrix", .simplifiedChinese: "行李清单"],
        "detail.packing.prepared": [.english: "Prepared", .simplifiedChinese: "已准备"],
        "detail.menu.add_day": [.english: "Add Day", .simplifiedChinese: "添加日程"],
        "detail.menu.add_spot": [.english: "Add Spot", .simplifiedChinese: "添加地点"],
        "detail.menu.explore_map": [.english: "Explore Map", .simplifiedChinese: "探索地图"],
        "detail.menu.ai_review": [.english: "AI Review", .simplifiedChinese: "AI 总结"],
        "detail.menu.trip_poster": [.english: "Trip Poster", .simplifiedChinese: "旅行海报"],
        "detail.atmosphere": [.english: "The Atmosphere", .simplifiedChinese: "氛围感"],
        "detail.collaborators": [.english: "Collaborators", .simplifiedChinese: "协作者"],

        // Add Travel / Edit Travel
        "add.travel.title": [.english: "New Journey", .simplifiedChinese: "开启新旅程"],
        "add.travel.info": [.english: "Basic Information", .simplifiedChinese: "基本信息"],
        "add.travel.name": [.english: "Travel Name", .simplifiedChinese: "行程名称"],
        "add.travel.type": [.english: "Travel Type", .simplifiedChinese: "旅行类型"],
        "add.travel.dates": [.english: "Dates", .simplifiedChinese: "日期选择"],
        "add.travel.start": [.english: "Start Date", .simplifiedChinese: "出发日期"],
        "add.travel.end": [.english: "End Date", .simplifiedChinese: "返程日期"],
        "add.travel.status": [.english: "Current Status", .simplifiedChinese: "当前状态"],
        "add.travel.create": [.english: "Create", .simplifiedChinese: "创建"],

        // Add Spot
        "add.spot.title": [.english: "New Highlight", .simplifiedChinese: "记录高光地点"],
        "add.spot.detail": [.english: "Spot Detail", .simplifiedChinese: "地点详情"],
        "add.spot.name": [.english: "Spot Name", .simplifiedChinese: "地点名称"],
        "add.spot.type": [.english: "Visit Type", .simplifiedChinese: "访问类型"],
        "add.spot.itinerary": [.english: "Connected Itinerary", .simplifiedChinese: "关联行程日程"],
        "add.spot.itinerary.pick": [.english: "Plan for Day", .simplifiedChinese: "关联行程天数"],
        "add.spot.itinerary.none": [.english: "Independent Spot", .simplifiedChinese: "不限天数"],
        "add.spot.geocoding": [.english: "Searching coordinates...", .simplifiedChinese: "正在锁定坐标..."],
        "add.spot.located": [.english: "Location locked", .simplifiedChinese: "坐标已锁定"],
        "add.spot.photos": [.english: "Photos", .simplifiedChinese: "照片存档"],
        "add.spot.photos.select": [.english: "Select Photos", .simplifiedChinese: "选择照片"],
        "add.spot.notes": [.english: "Notes", .simplifiedChinese: "心得/备注"],
        "add.spot.notes.placeholder": [.english: "Recommendation, feelings, etc.", .simplifiedChinese: "推荐理由、当时的心情等..."],
        "add.spot.save": [.english: "Save", .simplifiedChinese: "保存"],

        // Add Itinerary
        "add.itinerary.title": [.english: "Add Daily Plan", .simplifiedChinese: "添加每日计划"],
        "add.itinerary.day": [.english: "Day", .simplifiedChinese: "第"],
        "add.itinerary.unit": [.english: "", .simplifiedChinese: "天"],
        "add.itinerary.origin": [.english: "Origin", .simplifiedChinese: "出发地"],
        "add.itinerary.destination": [.english: "Destination", .simplifiedChinese: "目的地"],
        "add.itinerary.add": [.english: "Add", .simplifiedChinese: "添加"],

        // Luggage / Packing
        "luggage.title": [.english: "Packing Matrix", .simplifiedChinese: "行李清单"],
        "luggage.add.header": [.english: "Add to Matrix", .simplifiedChinese: "添加项目"],
        "luggage.add.placeholder": [.english: "New item...", .simplifiedChinese: "新项目..."],
        "luggage.add.category": [.english: "Category", .simplifiedChinese: "类别"],

        // Detail Menu
        "detail.menu.luggage": [.english: "Packing Matrix", .simplifiedChinese: "行李清单"],
        "detail.menu.edit": [.english: "Edit Trip Info", .simplifiedChinese: "编辑旅行信息"],

        // Edit Spot
        "edit.spot.title": [.english: "Edit Spot", .simplifiedChinese: "编辑地点"],
        "edit.spot.save": [.english: "Update Location", .simplifiedChinese: "更新地点"],

        // AI Valet Persona
        "intelligence.valet.header": [.english: "Private Concierge Tip", .simplifiedChinese: "私享礼宾提示"],
        "intelligence.valet.action.swap": [.english: "Adjust My Plans", .simplifiedChinese: "为我调整计划"],
        "intelligence.valet.action.later": [.english: "Not Now", .simplifiedChinese: "稍后处理"],

        // Edit Itinerary
        "edit.itinerary.title": [.english: "Edit Daily Plan", .simplifiedChinese: "编辑每日计划"],

        // Edit Travel
        "edit.travel.title": [.english: "Edit Journey", .simplifiedChinese: "编辑旅行"],
        "edit.travel.info": [.english: "Journey Blueprint", .simplifiedChinese: "旅行蓝图"],
        "edit.travel.save": [.english: "Save Changes", .simplifiedChinese: "保存修改"],
        "edit.travel.companions": [.english: "Travel Companions", .simplifiedChinese: "同行伙伴"],
        "edit.travel.add_companion": [.english: "Add Companion", .simplifiedChinese: "添加伙伴"],
        "edit.travel.photos": [.english: "Trip Memories", .simplifiedChinese: "旅行影像"],
        "edit.travel.add_photo": [.english: "Add Photo", .simplifiedChinese: "添加照片"],

        "companion.placeholder": [.english: "Friend's name", .simplifiedChinese: "朋友名字"],

        "poster.title": [.english: "Trip Poster", .simplifiedChinese: "旅行海报"],
        "poster.highlights": [.english: "The Highlights", .simplifiedChinese: "高光时刻"],
        "poster.footer": [.english: "Your travel architecture, preserved.", .simplifiedChinese: "你的旅行架构，由此铭刻。"],
        "poster.export.title": [.english: "Export Poster", .simplifiedChinese: "导出海报"],
        "poster.export.format": [.english: "Export Format", .simplifiedChinese: "导出格式"],
        "poster.export.rendering": [.english: "Rendering...", .simplifiedChinese: "正在渲染..."],
        "poster.export.share": [.english: "Share", .simplifiedChinese: "分享"],
        "poster.export.save": [.english: "Save to Album", .simplifiedChinese: "保存到相册"],
        "poster.format.xiaohongshu": [.english: "XiaoHongShu 3:4", .simplifiedChinese: "小红书 3:4"],
        "poster.format.moments": [.english: "Moments 1:1", .simplifiedChinese: "朋友圈 1:1"],
        "poster.format.landscape": [.english: "Universal 16:9", .simplifiedChinese: "通用 16:9"],
        "poster.stat.days": [.english: "Days", .simplifiedChinese: "天数"],
        "poster.stat.spots": [.english: "Spots", .simplifiedChinese: "打卡"],
        "poster.stat.mood": [.english: "Mood", .simplifiedChinese: "基调"],
        "poster.date.start": [.english: "Departure", .simplifiedChinese: "出发"],
        "poster.date.end": [.english: "Return", .simplifiedChinese: "归来"],

        // AI Assistant
        "ai.review.title": [.english: "AI Review Assistant", .simplifiedChinese: "AI 游记助手"],
        "ai.review.header": [.english: "Craft Your Narrative", .simplifiedChinese: "编织你的旅途叙事"],
        "ai.review.subtitle": [.english: "Choose a style and let AI weave your trip into a story.", .simplifiedChinese: "选一种文风，让 AI 将碎片记忆编织成诗"],
        "ai.review.style": [.english: "Writing Style", .simplifiedChinese: "写作风格"],
        "ai.review.generate": [.english: "Generate Journey Journal", .simplifiedChinese: "生成旅行回忆录"],
        "ai.review.memoir": [.english: "M E M O I R", .simplifiedChinese: "回 忆 录"],
        "ai.review.copy": [.english: "Copy Memoir", .simplifiedChinese: "复制游记"],
        "ai.review.share": [.english: "Share Journal", .simplifiedChinese: "分享精彩"],

        // Intelligence
        "intel.button.swap": [.english: "Swap My Plans", .simplifiedChinese: "调整我的计划"],
        "intel.button.new": [.english: "Discover Something New", .simplifiedChinese: "发现新灵感"],
        "intel.button.later": [.english: "Not Now", .simplifiedChinese: "晚点再说"],
        "intel.fatigue.title": [.english: "Take a Break", .simplifiedChinese: "注意休息"],
        "intel.fatigue.subtitle": [.english: "You've walked %d steps today. How about a quiet cafe?", .simplifiedChinese: "今天已经走了 %d 步，要不要找个安静的咖啡馆坐一会儿？"],
        "intel.weather.rain.title": [.english: "It's Raining", .simplifiedChinese: "下雨了"],
        "intel.weather.rain.subtitle": [.english: "Rain detected near %1$@ (%2$d°C). Swap to %3$@?", .simplifiedChinese: "检测到 %1$@ 附近有雨（%2$d°C）。要不要先去 %3$@？"],
        "intel.weather.rain.indoor": [.english: "Indoor Activity", .simplifiedChinese: "室内活动"],

        // Models - Status
        "status.wishing": [.english: "Wishing", .simplifiedChinese: "心之所向"],
        "status.planning": [.english: "Planning", .simplifiedChinese: "计划中"],
        "status.traveling": [.english: "Traveling", .simplifiedChinese: "旅途中"],
        "status.travelled": [.english: "Travelled", .simplifiedChinese: "已完成"],
        "status.cancelled": [.english: "Cancelled", .simplifiedChinese: "已取消"],

        // Models - Travel Type
        "type.tourism": [.english: "Tourism", .simplifiedChinese: "出游"],
        "type.concert": [.english: "Concert", .simplifiedChinese: "演唱会"],
        "type.chill": [.english: "Chill", .simplifiedChinese: "散心"],
        "type.business": [.english: "Business", .simplifiedChinese: "出差"],
        "type.other": [.english: "Other", .simplifiedChinese: "其他"],

        // Luggage Categories
        "luggage.cat.clothes": [.english: "Clothes", .simplifiedChinese: "衣物"],
        "luggage.cat.products": [.english: "Toiletries", .simplifiedChinese: "洗护"],
        "luggage.cat.electronics": [.english: "Electronics", .simplifiedChinese: "电子"],
        "luggage.cat.essentials": [.english: "Essentials", .simplifiedChinese: "必需品"],
        "luggage.cat.other": [.english: "Other", .simplifiedChinese: "其他"],
        "luggage.tpl.tshirt": [.english: "T-Shirt/Top", .simplifiedChinese: "T恤/上衣"],
        "luggage.tpl.pants": [.english: "Pants/Jeans", .simplifiedChinese: "裤子"],
        "luggage.tpl.jacket": [.english: "Jacket/Coat", .simplifiedChinese: "外套"],
        "luggage.tpl.underwear": [.english: "Underwear", .simplifiedChinese: "内衣裤"],
        "luggage.tpl.socks": [.english: "Socks", .simplifiedChinese: "袜子"],
        "luggage.tpl.toothbrush": [.english: "Toothbrush & Paste", .simplifiedChinese: "牙刷/牙膏"],
        "luggage.tpl.skincare": [.english: "Skincare", .simplifiedChinese: "洗面护肤"],
        "luggage.tpl.shampoo": [.english: "Shampoo & Body Wash", .simplifiedChinese: "沐浴洗发"],
        "luggage.tpl.towel": [.english: "Towel", .simplifiedChinese: "毛巾"],
        "luggage.tpl.cosmetics": [.english: "Cosmetics", .simplifiedChinese: "化妆品"],
        "luggage.tpl.charger": [.english: "Phone Charger", .simplifiedChinese: "充电器"],
        "luggage.tpl.powerbank": [.english: "Power Bank", .simplifiedChinese: "充电宝"],
        "luggage.tpl.earphones": [.english: "Earphones", .simplifiedChinese: "耳机"],
        "luggage.tpl.laptop": [.english: "Laptop & Charger", .simplifiedChinese: "笔记本电脑"],
        "luggage.tpl.adapter": [.english: "Power Adapter", .simplifiedChinese: "转换插头"],
        "luggage.tpl.passport": [.english: "ID/Passport", .simplifiedChinese: "身份证/护照"],
        "luggage.tpl.card": [.english: "Credit Card", .simplifiedChinese: "银行卡/信用卡"],
        "luggage.tpl.cash": [.english: "Cash", .simplifiedChinese: "现金"],
        "luggage.tpl.keys": [.english: "Keys", .simplifiedChinese: "钥匙"],
        "luggage.tpl.medicine": [.english: "Medication", .simplifiedChinese: "常备药品"],
        "luggage.tpl.umbrella": [.english: "Umbrella", .simplifiedChinese: "雨伞"],
        "luggage.tpl.sunglasses": [.english: "Sunglasses", .simplifiedChinese: "墨镜"],
        "luggage.tpl.bottle": [.english: "Water Bottle", .simplifiedChinese: "水杯"],
        "luggage.tpl.tissue": [.english: "Tissue/Wipes", .simplifiedChinese: "纸巾/湿巾"],

        // Luggage Categories
        "luggage.category.clothes": [.english: "Clothes", .simplifiedChinese: "衣物"],
        "luggage.category.products": [.english: "Toiletries", .simplifiedChinese: "洗护用品"],
        "luggage.category.electronics": [.english: "Electronics", .simplifiedChinese: "电子设备"],
        "luggage.category.essentials": [.english: "Essentials", .simplifiedChinese: "必备证件"],
        "luggage.category.other": [.english: "Other", .simplifiedChinese: "其他"],

        // Luggage Weather
        "luggage.weather.title": [.english: "Destination Weather", .simplifiedChinese: "目的地天气"],
        "luggage.weather.unavailable": [.english: "Add spots with location to see weather", .simplifiedChinese: "添加带位置的景点后可查看天气"],


        // Spot Types
        "spot.type.food": [.english: "Food", .simplifiedChinese: "美食"],
        "spot.type.sightseeing": [.english: "Sightseeing", .simplifiedChinese: "景点"],
        "spot.type.shopping": [.english: "Shopping", .simplifiedChinese: "购物"],
        "spot.type.performance": [.english: "Performance", .simplifiedChinese: "演出"],
        "spot.type.fun": [.english: "Fun", .simplifiedChinese: "游玩"],
        "spot.type.hotel": [.english: "Hotel", .simplifiedChinese: "住宿"],
        "spot.type.travel": [.english: "Transit", .simplifiedChinese: "出行"],

        // Common
        "common.cancel": [.english: "Cancel", .simplifiedChinese: "取消"],
        "common.done": [.english: "Done", .simplifiedChinese: "完成"],
        "common.close": [.english: "Close", .simplifiedChinese: "关闭"],
        "common.days": [.english: "Days", .simplifiedChinese: "天"],
        "common.spots": [.english: "Spots", .simplifiedChinese: "景点"],
        "common.explore": [.english: "Explore", .simplifiedChinese: "探索"],

        // Onboarding & Dashboard Empty State
        "dashboard.onboarding.hero.title": [.english: "Your Director's Cut Awaits", .simplifiedChinese: "你的导演剪辑版正待开机"],
        "dashboard.onboarding.hero.subtitle": [.english: "Every journey is a story worth filming.", .simplifiedChinese: "每一段旅程，都值得一部电影。"],
        "dashboard.onboarding.task1.desc": [.english: "Where does your heart want to go?", .simplifiedChinese: "你的心想去哪里？"],
        "dashboard.onboarding.task2.desc": [.english: "Pick the season and vibe.", .simplifiedChinese: "选择季节与氛围。"],
        "dashboard.onboarding.task3.desc": [.english: "Pin the first coordinate.", .simplifiedChinese: "钉下第一个坐标。"],

        // Brand & Identity
        "common.tagline": [.english: "TO EXPLORE, TO EXPERIENCE, TO EXIST", .simplifiedChinese: "去探索，去体验，去存在"],
        "common.delete": [.english: "Delete", .simplifiedChinese: "删除"],
        "common.edit": [.english: "Edit", .simplifiedChinese: "编辑"],

        // Inspiration Plaza
        "inspiration.header.title": [.english: "Inspiration Plaza", .simplifiedChinese: "灵感广场"],
        "inspiration.header.subtitle": [.english: "Curated journeys from the global collective.", .simplifiedChinese: "来自全球旅行者的精选体验。"],
        "inspiration.remix_success": [.english: "Journey Remixed!", .simplifiedChinese: "旅程已复刻！"],

        // Stat Detail
        "stat.detail.subtitle": [.english: "Explore your journey details", .simplifiedChinese: "探索你的旅程细节"],
        "travel.detail.destination": [.english: "DESTINATION", .simplifiedChinese: "目的地"],

        // Edit Travel
        "edit.travel.dates": [.english: "Edit Dates", .simplifiedChinese: "编辑日期"],
        "edit.travel.start": [.english: "Start Date", .simplifiedChinese: "开始日期"],
        "edit.travel.end": [.english: "End Date", .simplifiedChinese: "结束日期"],

        // Settings — Appearance
        "settings.appearance.dark_mode": [.english: "Dark Mode", .simplifiedChinese: "深色模式"],
        "settings.appearance.dark_mode.value": [.english: "Follow System", .simplifiedChinese: "跟随系统"],
        "settings.appearance.icon": [.english: "App Icon", .simplifiedChinese: "应用图标"],

        // Settings — About
        "settings.about.title": [.english: "About TravelPin", .simplifiedChinese: "关于 TravelPin"],
        "settings.about.philosophy": [.english: "Our Philosophy", .simplifiedChinese: "我们的理念"],
        "settings.about.philosophy.text": [.english: "TravelPin is not just a notebook — it's the Director's Cut of your travels. We believe every journey deserves to be remembered with cinematic beauty, not as scattered data points.\n\nTo Explore, To Experience, To Exist.", .simplifiedChinese: "TravelPin 不仅仅是记事本，它是你旅行的导演剪辑版。我们相信每一段旅程都值得用电影般的唯美来铭记，而非散落的数据碎片。\n\n去探索，去体验，去存在。"],
        "settings.about.made_with": [.english: "Crafted with care for wanderers.", .simplifiedChinese: "为每一位行者，精心打造。"],

        // Splash
        "splash.tagline": [.english: "Footprints connected, exploration infinite", .simplifiedChinese: "足迹相连，便是探索无限"],

        // Onboarding
        "onboarding.welcome.title": [.english: "Welcome to TravelPin", .simplifiedChinese: "欢迎来到 TravelPin"],
        "onboarding.welcome.subtitle": [.english: "Capture every moment.\nYour footprints, an eternal story.", .simplifiedChinese: "记录旅途中的每一个瞬间\n让足迹变成永恒的故事"],
        "onboarding.feature.map.title": [.english: "Interactive Map", .simplifiedChinese: "交互式地图"],
        "onboarding.feature.map.desc": [.english: "Precise positioning offline", .simplifiedChinese: "离线也能精准定位"],
        "onboarding.feature.ai.title": [.english: "AI Journal", .simplifiedChinese: "AI 游记"],
        "onboarding.feature.ai.desc": [.english: "Generate essays with one click", .simplifiedChinese: "一键生成文学随笔"],
        "onboarding.feature.poster.title": [.english: "Cinematic Poster", .simplifiedChinese: "电影感海报"],
        "onboarding.feature.poster.desc": [.english: "Exquisite layout for sharing", .simplifiedChinese: "精美排版一键分享"],

        "onboarding.name.title": [.english: "Name Your Journey", .simplifiedChinese: "为旅程命名"],
        "onboarding.name.subtitle": [.english: "Give your first destination a name", .simplifiedChinese: "给第一个目的地起个名字吧"],
        "onboarding.name.placeholder": [.english: "e.g. Kamakura Escape", .simplifiedChinese: "例如：镰仓避世之旅"],
        "onboarding.name.typeLabel": [.english: "Select Travel Type", .simplifiedChinese: "选择旅行类型"],

        "onboarding.date.title": [.english: "Plan Your Departure", .simplifiedChinese: "计划出发时间"],
        "onboarding.date.subtitle": [.english: "You can always change it later", .simplifiedChinese: "不确定也没关系，随时可以修改"],
        "onboarding.date.start": [.english: "Departure Date", .simplifiedChinese: "出发日期"],
        "onboarding.date.end": [.english: "Return Date", .simplifiedChinese: "返回日期"],

        "onboarding.ready.title": [.english: "Ready to Explore", .simplifiedChinese: "准备就绪"],
        "onboarding.ready.subtitle": [.english: "Your first journey is about to begin", .simplifiedChinese: "你的第一个旅程即将开始"],
        "onboarding.ready.destination": [.english: "Destination", .simplifiedChinese: "目的地"],
        "onboarding.ready.type": [.english: "Type", .simplifiedChinese: "类型"],
        "onboarding.ready.date": [.english: "Date", .simplifiedChinese: "日期"],
        "onboarding.ready.unnamed": [.english: "Unnamed Journey", .simplifiedChinese: "未命名旅程"],

        "onboarding.action.next": [.english: "Next", .simplifiedChinese: "下一步"],
        "onboarding.action.back": [.english: "Back", .simplifiedChinese: "上一步"],
        "onboarding.action.start": [.english: "Start Journey", .simplifiedChinese: "开始旅程"],
        "onboarding.default.name": [.english: "My First Journey", .simplifiedChinese: "第一次旅行"],

        // Workflow Steps
        "workflow.stage1.step1": [.english: "Trip Creation", .simplifiedChinese: "旅行创建"],
        "workflow.stage1.step2": [.english: "Spot Collection", .simplifiedChinese: "景点收集"],
        "workflow.stage1.step3": [.english: "Itinerary", .simplifiedChinese: "行程安排"],
        "workflow.stage1.step4": [.english: "Packing", .simplifiedChinese: "行李准备"],
        "workflow.stage1.step5": [.english: "Departure", .simplifiedChinese: "出发"],
        
        "workflow.stage2.step1": [.english: "View Plans", .simplifiedChinese: "查看行程"],
        "workflow.stage2.step2": [.english: "Check-in", .simplifiedChinese: "景点打卡"],
        "workflow.stage2.step3": [.english: "Photo Log", .simplifiedChinese: "照片记录"],
        "workflow.stage2.step4": [.english: "Status Update", .simplifiedChinese: "状态更新"],
        "workflow.stage2.step5": [.english: "Notes", .simplifiedChinese: "体验备注"],
        
        "workflow.stage3.step1": [.english: "Stats", .simplifiedChinese: "足迹统计"],
        "workflow.stage3.step2": [.english: "Photo Archive", .simplifiedChinese: "照片整理"],
        "workflow.stage3.step3": [.english: "Memoirs", .simplifiedChinese: "回忆分享"],
        "workflow.stage3.step4": [.english: "Review", .simplifiedChinese: "经验总结"],
        "workflow.stage3.step5": [.english: "Next Plan", .simplifiedChinese: "下次规划"],

        // Detail View
        "detail.menu.edit_trip": [.english: "Edit Journey", .simplifiedChinese: "编辑旅程"],
        "detail.menu.view_map": [.english: "View Map", .simplifiedChinese: "查看地图"],
        "detail.menu.publish": [.english: "Publish to Plaza", .simplifiedChinese: "发布到灵感广场"],
        "detail.menu.collaborate": [.english: "Collaborate", .simplifiedChinese: "同行协作"],
        "detail.menu.activity": [.english: "Activity", .simplifiedChinese: "协作动态"],
        "detail.action.add_day": [.english: "Add Day %d", .simplifiedChinese: "添加第 %d 天"],
        "detail.action.add_first_day": [.english: "Add First Day", .simplifiedChinese: "添加第一天"],
        "detail.action.add_spot": [.english: "Add Spot", .simplifiedChinese: "添加地点"],
        "detail.archive.empty": [.english: "No highlights yet", .simplifiedChinese: "暂无高光时刻"],
        "detail.packing.status": [.english: "%1$d/%2$d Prepared", .simplifiedChinese: "%1$d/%2$d 已准备"],
        "detail.spot.map_overview": [.english: "Map Overview", .simplifiedChinese: "地图概览"],
        "detail.spot.atmosphere": [.english: "Atmosphere & Impression", .simplifiedChinese: "氛围与印象"],
        "poster.design.dots": [.english: " · ", .simplifiedChinese: " · "],
        "poster.type.tourism": [.english: "✈️ Tourism", .simplifiedChinese: "✈️ 出游"],
        "poster.type.concert": [.english: "🎵 Concert", .simplifiedChinese: "🎵 演唱会"],
        "poster.type.chill": [.english: "🏖 Chill", .simplifiedChinese: "🏖 散心"],
        "poster.type.business": [.english: "💼 Business", .simplifiedChinese: "💼 出差"],
        "poster.type.other": [.english: "🗺 Travel", .simplifiedChinese: "🗺 旅行"],

        "add.spot.status.locating": [.english: "Locating...", .simplifiedChinese: "正在定位..."],
        "add.spot.status.locked": [.english: "Location Locked", .simplifiedChinese: "位置已锁定"],
        "add.spot.status.failed": [.english: "Unrecognized, edit later", .simplifiedChinese: "未能识别，可稍后编辑坐标"],
        
        "common.error.network": [.english: "Network error, please check connection", .simplifiedChinese: "网络错误，请检查连接"],
        "ai.error.offline": [.english: "AI features require network connection", .simplifiedChinese: "AI 功能需要网络连接"],
        "map.error.offline": [.english: "Map features require network connection", .simplifiedChinese: "地图功能需要网络连接"],

        "map.status.offline": [.english: "Offline", .simplifiedChinese: "离线"],
        "map.alert.download_success.title": [.english: "Map Downloaded", .simplifiedChinese: "地图已下载"],
        "map.alert.download_success.message": [.english: "Cached %1$d map tiles (%2$@), available offline.", .simplifiedChinese: "已缓存 %1$d 个地图瓦片 (%2$@)，可离线使用"],
        "map.alert.clear_cache.title": [.english: "Clear Offline Map Cache?", .simplifiedChinese: "清除离线地图缓存？"],
        "map.alert.clear_cache.message": [.english: "This will delete all downloaded map tiles (%@).", .simplifiedChinese: "将删除所有已下载的地图瓦片 (%@)"],
        "map.action.clear": [.english: "Clear Cache", .simplifiedChinese: "清除缓存"],
        "map.action.all": [.english: "All", .simplifiedChinese: "全部"],

        // Settings — About (section keys)
        "settings.about": [.english: "About", .simplifiedChinese: "关于"],
        "settings.about.quote": [.english: "To Explore, To Experience, To Exist.", .simplifiedChinese: "去探索，去体验，去存在。"],

        // Logic Closed Loop
        "logic.plan.alert.title": [.english: "Trip Logic Alert", .simplifiedChinese: "行程逻辑提醒"],
        "logic.plan.conflict.time": [.english: "Schedule Overlap", .simplifiedChinese: "行程重叠"],
        "logic.plan.conflict.spatial": [.english: "Transit Logic Warning", .simplifiedChinese: "交通逻辑预警"],
        "logic.active.now": [.english: "Now Playing", .simplifiedChinese: "正在进行"],
        "logic.active.next": [.english: "Next Up", .simplifiedChinese: "下一站"],
        "logic.active.empty": [.english: "No logic available", .simplifiedChinese: "当前无行程"],
        "logic.active.start_day": [.english: "Start your day", .simplifiedChinese: "开启新的一天吧"],
        "logic.post.title": [.english: "Journey Concluded", .simplifiedChinese: "旅途圆满结束"],
        "logic.post.subtitle": [.english: "Review your footprints", .simplifiedChinese: "回顾你的足迹"],
        "logic.stat.cost": [.english: "Total Cost", .simplifiedChinese: "累计开销"],
        "logic.stat.distance": [.english: "Distance Traveled", .simplifiedChinese: "穿行距离"],
        "logic.stat.rate": [.english: "Completion Rate", .simplifiedChinese: "完成率"],
        "logic.stat.cost_per_km": [.english: "Cost per KM", .simplifiedChinese: "每公里成本"],
        "logic.stat.budget_usage": [.english: "Budget Usage", .simplifiedChinese: "预算执行率"],
        
        // Budget & Export
        "detail.menu.export_trail": [.english: "Export Logic Trail", .simplifiedChinese: "导出逻辑长图"],
        "export.long_trail.title": [.english: "Journey Logic Trail", .simplifiedChinese: "旅途逻辑长图"],
        "detail.budget.title": [.english: "Budget Analytics", .simplifiedChinese: "预算智能分析"],
        "detail.budget.left": [.english: "Budget Left: ¥%.0f", .simplifiedChinese: "剩余预算: ¥%.0f"],
        "LOGIC.STAT.DISTANCE": [.english: "DISTANCE", .simplifiedChinese: "穿行距离"],
        "LOGIC.STAT.COST": [.english: "TOTAL COST", .simplifiedChinese: "累计支出"],
        "LOGIC.STAT.RATE": [.english: "TARGET RATE", .simplifiedChinese: "目标达成"],

        // AI Itinerary Generation
        "ai.itinerary.title": [.english: "AI Itinerary Planner", .simplifiedChinese: "AI 智能行程规划"],
        "ai.itinerary.generate": [.english: "Generate Itinerary", .simplifiedChinese: "生成行程"],
        "ai.itinerary.adopt": [.english: "Adopt", .simplifiedChinese: "采纳"],
        "ai.itinerary.adopt_all": [.english: "Adopt All", .simplifiedChinese: "全部采纳"],
        "ai.itinerary.day_plan": [.english: "Day %d Plan", .simplifiedChinese: "第 %d 天计划"],
        "ai.itinerary.loading": [.english: "AI is planning your itinerary...", .simplifiedChinese: "AI 正在规划行程..."],
        "ai.itinerary.error": [.english: "Generation failed. Please try again.", .simplifiedChinese: "生成失败，请重试"],
        "ai.itinerary.spots": [.english: "Suggested Spots", .simplifiedChinese: "推荐景点"],

        // Weather Overlay
        "weather.overlay.temp": [.english: "%.0f°C", .simplifiedChinese: "%.0f°C"],
        "weather.overlay.rain_chance": [.english: "Rain Chance: %.0f%%", .simplifiedChinese: "降雨概率: %.0f%%"],
        "weather.overlay.expanded": [.english: "WEATHER FORECAST", .simplifiedChinese: "天气预报"],
        "weather.overlay.hourly": [.english: "HOURLY FORECAST", .simplifiedChinese: "逐时预报"],
        "weather.overlay.now": [.english: "Now", .simplifiedChinese: "现在"],

        // Footprint Heatmap
        "footprint.heatmap.title": [.english: "Footprint Heatmap", .simplifiedChinese: "足迹热力图"],
        "footprint.heatmap.subtitle": [.english: "Your footprint density heatmap", .simplifiedChinese: "你的足迹分布热力图"],
        "footprint.heatmap.spots_count": [.english: "%d Spots", .simplifiedChinese: "%d 个足迹"],
        "footprint.heatmap.cities": [.english: "%d Cities", .simplifiedChinese: "%d 个城市"],

        // Annual Report
        "annual.title": [.english: "%@ Annual Report", .simplifiedChinese: "%@ 年度报告"],
        "annual.subtitle": [.english: "Your Year in Review", .simplifiedChinese: "你的旅行年度回顾"],
        "annual.stat.trips": [.english: "Trips", .simplifiedChinese: "旅程"],
        "annual.stat.spots": [.english: "Footprints", .simplifiedChinese: "足迹"],
        "annual.stat.days": [.english: "On the Road", .simplifiedChinese: "在路上"],
        "annual.stat.photos": [.english: "Photos", .simplifiedChinese: "照片"],
        "annual.generate": [.english: "Generate AI Annual Summary", .simplifiedChinese: "生成 AI 年度总结"],
        "annual.share": [.english: "Share Annual Report", .simplifiedChinese: "分享年度报告"],
        "annual.generating": [.english: "AI is writing...", .simplifiedChinese: "AI 正在撰写..."],
        "annual.top_trips": [.english: "Top Journeys", .simplifiedChinese: "年度精选"],
        "annual.ai_summary": [.english: "AI Annual Summary", .simplifiedChinese: "AI 年度总结"],

        // Budget & Calendar
        "add.travel.budget": [.english: "Budget", .simplifiedChinese: "预算"],
        "add.travel.budget.placeholder": [.english: "Estimated budget", .simplifiedChinese: "预估预算"],
        "add.travel.currency": [.english: "Currency", .simplifiedChinese: "币种"],
        "add.travel.calendar": [.english: "Calendar", .simplifiedChinese: "日历"],
        "add.travel.calendar_sync": [.english: "Sync to Calendar", .simplifiedChinese: "同步到日历"],
        "add.travel.calendar_synced": [.english: "Synced to Calendar", .simplifiedChinese: "已同步日历"],
        "add.travel.calendar_failed": [.english: "Calendar sync failed", .simplifiedChinese: "日历同步失败"],

        // Calendar Event Notes
        "calendar.travel.notes": [.english: "Trip: %1$@ — Destination: %2$@ (%3$d days)", .simplifiedChinese: "旅行：%1$@ — 目的地：%2$@（%3$d 天）"],

        // Remix
        "remix.suffix": [.english: "Remix", .simplifiedChinese: "复刻"],

        // Notifications
        "notif.trip_upcoming.title": [.english: "Trip Approaching", .simplifiedChinese: "旅途将至"],
        "notif.trip_upcoming.body": [.english: "%@ departs tomorrow! Don't forget to check your packing list ✈️", .simplifiedChinese: "%@ 明天就要出发了！别忘了检查行李清单 ✈️"],
        "notif.trip_depart.title": [.english: "Departure Day!", .simplifiedChinese: "今天出发！"],
        "notif.trip_depart.body": [.english: "%@ begins today. Have a wonderful trip! 🌟", .simplifiedChinese: "%@ 的旅程从今天开始，祝你旅途愉快 🌟"],
        "notif.packing.title": [.english: "Packing Reminder", .simplifiedChinese: "收拾行李提醒"],
        "notif.packing.body": [.english: "%@ departs in 3 days. Time to pack! 🧳", .simplifiedChinese: "%@ 还有3天出发，该准备行李了 🧳"],
        "notif.review.title": [.english: "Journey Review", .simplifiedChinese: "旅程回顾"],
        "notif.review.body": [.english: "%@ has ended. Time to capture those beautiful memories 📸", .simplifiedChinese: "%@ 已经结束了，来记录旅途中的美好回忆吧 📸"],
        "notif.spot_arrival.title": [.english: "You've Arrived at %@", .simplifiedChinese: "你已到达 %@"],
        "notif.spot_arrival.body": [.english: "Tap to check in and capture this moment!", .simplifiedChinese: "点击打卡，记录这一刻！"],
        "notif.memory.title": [.english: "Memory: %@", .simplifiedChinese: "回忆：%@"],
        "notif.memory.body": [.english: "A month ago you were exploring %@. Relive those moments!", .simplifiedChinese: "一个月前你正在探访 %@，重温那些美好时光吧！"],

        // Check-in
        "checkin.title": [.english: "You've Arrived!", .simplifiedChinese: "到达打卡!"],
        "checkin.subtitle": [.english: "You're near %@", .simplifiedChinese: "你已到达 %@"],
        "checkin.action": [.english: "Check In", .simplifiedChinese: "打卡"],
        "checkin.skip": [.english: "Skip", .simplifiedChinese: "跳过"],
        "checkin.photo": [.english: "Quick Photo", .simplifiedChinese: "快速拍照"],
        "checkin.notes.placeholder": [.english: "Quick thoughts...", .simplifiedChinese: "记一笔感受..."],

        // AI Review Enhanced
        "ai.review.enhanced": [.english: "Enhanced Mode (with timeline & photos)", .simplifiedChinese: "增强模式（含时间线与照片）"],

        // Smart Packing
        "luggage.ai.suggestions": [.english: "Smart Suggestions", .simplifiedChinese: "智能推荐"],
        "luggage.ai.weather_based": [.english: "Get suggestions based on destination weather", .simplifiedChinese: "基于目的地天气获取建议"],
        "luggage.ai.add_all": [.english: "Add All", .simplifiedChinese: "全部添加"],

        // Annual Report Banner
        "annual.banner.title": [.english: "Your %@ in Review", .simplifiedChinese: "你的 %@ 旅行回顾"],
        "annual.banner.action": [.english: "View Report", .simplifiedChinese: "查看报告"],
        "annual.banner.stat": [.english: "%d trips completed", .simplifiedChinese: "已完成 %d 次旅程"],

        // Companion Header
        "detail.header.companions": [.english: "%d Travelers", .simplifiedChinese: "%d 人同行"],

        // Footprint Heatmap Empty
        "footprint.heatmap.empty": [.english: "No visited spots yet", .simplifiedChinese: "还没有访问记录"],

        // Common
        "common.confirm": [.english: "Confirm", .simplifiedChinese: "确认"],
        "common.items": [.english: "items", .simplifiedChinese: "项"],

        // Dashboard Greeting
        "dashboard.greeting.morning": [.english: "Good Morning, Traveler", .simplifiedChinese: "早安，旅行家"],
        "dashboard.greeting.afternoon": [.english: "Good Afternoon, Traveler", .simplifiedChinese: "午安，旅行家"],
        "dashboard.greeting.evening": [.english: "Good Evening, Traveler", .simplifiedChinese: "晚上好，旅行家"],

        // Dashboard Status Groups
        "dashboard.section.upcoming": [.english: "UPCOMING", .simplifiedChinese: "即将出发"],
        "dashboard.section.active": [.english: "ACTIVE", .simplifiedChinese: "旅途中"],
        "dashboard.section.completed": [.english: "RECENTLY COMPLETED", .simplifiedChinese: "旅途回忆"],

        // Travel Detail — Onboarding Guide
        "detail.guide.title": [.english: "Quick Start Guide", .simplifiedChinese: "快速上手指南"],
        "detail.guide.ai_itinerary.title": [.english: "AI Smart Planning", .simplifiedChinese: "AI 智能行程"],
        "detail.guide.ai_itinerary.desc": [.english: "Let AI generate a complete itinerary based on your destination", .simplifiedChinese: "让 AI 根据目的地自动生成完整行程"],
        "detail.guide.add_day.title": [.english: "Add Daily Plan", .simplifiedChinese: "添加每日计划"],
        "detail.guide.add_day.desc": [.english: "Break down your trip day by day for clear planning", .simplifiedChinese: "按天拆分行程，清晰规划每一天"],
        "detail.guide.luggage.title": [.english: "Packing Checklist", .simplifiedChinese: "行李清单"],
        "detail.guide.luggage.desc": [.english: "AI generates a smart packing list based on weather and trip type", .simplifiedChinese: "AI 根据天气和旅行类型智能生成打包清单"],
        "detail.guide.collab.title": [.english: "Invite Companions", .simplifiedChinese: "邀请同行伙伴"],
        "detail.guide.collab.desc": [.english: "Invite friends to co-edit itineraries and sync footprints", .simplifiedChinese: "邀请朋友一起编辑行程，实时同步足迹"],

        // Detail — Coming Soon
        "detail.section.coming_soon": [.english: "COMING SOON", .simplifiedChinese: "即将推出"],

        // AI Copilot
        "copilot.title": [.english: "AI Packing Copilot", .simplifiedChinese: "AI 打包助手"],
        "copilot.field.destination": [.english: "Destination", .simplifiedChinese: "目的地"],
        "copilot.field.season": [.english: "Season", .simplifiedChinese: "季节"],
        "copilot.field.style": [.english: "Trip Style", .simplifiedChinese: "旅行风格"],
        "copilot.field.notes": [.english: "Special Needs", .simplifiedChinese: "特殊需求"],
        "copilot.placeholder.destination": [.english: "Where are you going?", .simplifiedChinese: "你要去哪里？"],
        "copilot.placeholder.notes": [.english: "Any special requirements...", .simplifiedChinese: "有什么特殊需求..."],
        "copilot.action.generate": [.english: "Generate Smart List", .simplifiedChinese: "智能生成清单"],
        "copilot.generating": [.english: "AI is thinking...", .simplifiedChinese: "AI 正在思考..."],
        "copilot.results.count": [.english: "%d smart suggestions", .simplifiedChinese: "%d 条智能推荐"],
        "copilot.action.select_all": [.english: "Select All", .simplifiedChinese: "全选"],
        "copilot.action.add_count": [.english: "Add %d Items", .simplifiedChinese: "添加 %d 项"],
        "copilot.banner.title": [.english: "AI Packing Copilot", .simplifiedChinese: "AI 打包助手"],
        "copilot.banner.subtitle": [.english: "Tell me your destination, I'll plan the rest", .simplifiedChinese: "告诉我目的地，智能生成完整清单"],

        // Travel DNA
        "dna.title": [.english: "Your Travel DNA", .simplifiedChinese: "你的旅行 DNA"],
        "dna.card.title": [.english: "TRAVEL DNA", .simplifiedChinese: "旅行 DNA"],
        "dna.section.preferences": [.english: "TRAVEL PREFERENCES", .simplifiedChinese: "旅行偏好"],
        "dna.section.personality": [.english: "TRAVEL PERSONALITY", .simplifiedChinese: "旅行性格"],
        "dna.section.cities": [.english: "FAVORITE CITIES", .simplifiedChinese: "常去城市"],
        "dna.stat.trips": [.english: "Trips", .simplifiedChinese: "旅程"],
        "dna.stat.spots": [.english: "Spots", .simplifiedChinese: "打卡"],
        "dna.stat.days": [.english: "Days", .simplifiedChinese: "天数"],
        "dna.stat.photos": [.english: "Photos", .simplifiedChinese: "照片"],
        "dna.action.share": [.english: "Share DNA Card", .simplifiedChinese: "分享 DNA 卡片"],
        "dna.action.close": [.english: "Close", .simplifiedChinese: "关闭"],

        // Map Route Optimization
        "map.alert.optimize_route.title": [.english: "Optimize Route?", .simplifiedChinese: "优化路线？"],
        "map.alert.optimize_route.message": [.english: "Reorder %d spots for the shortest path", .simplifiedChinese: "重新排列 %d 个景点以获得最短路线"],
        "map.action.optimize": [.english: "Optimize", .simplifiedChinese: "优化"],
        "map.toast.route_optimized": [.english: "Route optimized!", .simplifiedChinese: "路线已优化！"],

        // Memory Capsule
        "memory.banner.title": [.english: "Time Capsule", .simplifiedChinese: "时光胶囊"],
        "memory.banner.subtitle": [.english: "%@ · %d days ago", .simplifiedChinese: "%@ · %d 天前"],
        "memory.banner.action": [.english: "Open Capsule", .simplifiedChinese: "打开胶囊"],
        "memory.title": [.english: "Time Capsule", .simplifiedChinese: "时光胶囊"],
        "memory.subtitle": [.english: "%d days of wonderful moments", .simplifiedChinese: "%d 天的美好时光"],
        "memory.ai_reflection": [.english: "AI Reflection", .simplifiedChinese: "AI 感悟"],
        "memory.action.share": [.english: "Share Memory", .simplifiedChinese: "分享回忆"],
        "memory.action.close": [.english: "Close", .simplifiedChinese: "关闭"],

        // Memory Notification Milestone
        "notif.memory.milestone.body": [.english: "It's been %2$@ since your trip to %1$@. Relive those moments!", .simplifiedChinese: "你的 %@ 之旅已过去 %@，来看看当时的美好瞬间"],

        // Route Replay
        "route.replay.title": [.english: "Route Replay", .simplifiedChinese: "路线回放"],

        // Clipboard Import
        "import.clipboard.title": [.english: "Import from Clipboard", .simplifiedChinese: "从剪贴板导入"],
        "import.empty.title": [.english: "No Travel Content Found", .simplifiedChinese: "未检测到旅行内容"],
        "import.empty.subtitle": [.english: "Copy a travel post from Xiaohongshu or other apps, then open this page", .simplifiedChinese: "先从小红书等平台复制一篇旅行攻略，再打开此页面"],
        "import.source.preview": [.english: "SOURCE PREVIEW", .simplifiedChinese: "来源预览"],
        "import.spots.found": [.english: "%d Spots Detected", .simplifiedChinese: "识别到 %d 个地点"],
        "import.action.add": [.english: "Import", .simplifiedChinese: "导入"],

        // Route Tracking
        "tracking.title": [.english: "Route Tracking", .simplifiedChinese: "路线追踪"],
        "tracking.status.active": [.english: "Tracking Active", .simplifiedChinese: "正在记录路线"],
        "tracking.status.inactive": [.english: "Not Tracking", .simplifiedChinese: "未开始记录"],
        "tracking.action.start": [.english: "Start Tracking", .simplifiedChinese: "开始记录"],
        "tracking.action.stop": [.english: "Stop & Save", .simplifiedChinese: "停止并保存"],
        "tracking.action.replay": [.english: "Replay Route", .simplifiedChinese: "回放路线"],
        "tracking.action.import": [.english: "Import from Clipboard", .simplifiedChinese: "从剪贴板导入攻略"],

        // MARK: - NowPlaying Card
        "now.playing.title": [.english: "NOW PLAYING", .simplifiedChinese: "此刻"],
        "now.playing.free_time": [.english: "Free time", .simplifiedChinese: "自由活动时间"],
        "now.playing.next": [.english: "UP NEXT", .simplifiedChinese: "下一站"],
        "now.playing.no_weather": [.english: "Weather unavailable", .simplifiedChinese: "天气暂无"],
        "now.fatigue.low": [.english: "Energetic", .simplifiedChinese: "精力充沛"],
        "now.fatigue.moderate": [.english: "Moderate", .simplifiedChinese: "略有疲惫"],
        "now.fatigue.high": [.english: "Tired", .simplifiedChinese: "较为疲惫"],
        "now.clothing.very_cold": [.english: "Heavy coat recommended", .simplifiedChinese: "建议穿厚外套"],
        "now.clothing.cold": [.english: "Jacket recommended", .simplifiedChinese: "建议带外套"],
        "now.clothing.warm": [.english: "Sun protection", .simplifiedChinese: "建议防晒"],
        "now.clothing.hot": [.english: "Stay cool & hydrated", .simplifiedChinese: "注意防暑降温"],

        // MARK: - Wizard Flow
        "wizard.title": [.english: "New Journey", .simplifiedChinese: "新建旅程"],
        "wizard.next": [.english: "Continue", .simplifiedChinese: "继续"],
        "wizard.back": [.english: "Back", .simplifiedChinese: "上一步"],
        "wizard.create": [.english: "Create Journey", .simplifiedChinese: "创建旅程"],
        "wizard.type.recommended": [.english: "For You", .simplifiedChinese: "为你推荐"],

        // Wizard Step 1
        "wizard.step1.title": [.english: "Name Your Journey", .simplifiedChinese: "给旅程起个名字"],
        "wizard.step1.subtitle": [.english: "Start with a name and pick your travel style", .simplifiedChinese: "从名字开始，选择你的旅行风格"],
        "wizard.step1.name_section": [.english: "Journey Name", .simplifiedChinese: "旅程名称"],
        "wizard.step1.type_section": [.english: "Travel Style", .simplifiedChinese: "旅行风格"],

        // Wizard Step 2
        "wizard.step2.title": [.english: "When Are You Going?", .simplifiedChinese: "什么时候出发？"],
        "wizard.step2.subtitle": [.english: "Pick your travel dates or use quick presets", .simplifiedChinese: "选择出行日期或使用快捷预设"],
        "wizard.step2.quick": [.english: "Quick Select", .simplifiedChinese: "快捷选择"],
        "wizard.step2.custom": [.english: "Custom Dates", .simplifiedChinese: "自定义日期"],
        "wizard.step2.duration": [.english: "%d days", .simplifiedChinese: "%d 天"],
        "wizard.dates.this_weekend": [.english: "This Weekend", .simplifiedChinese: "本周末"],
        "wizard.dates.next_week": [.english: "Next Week", .simplifiedChinese: "下周"],
        "wizard.dates.next_month": [.english: "Next Month", .simplifiedChinese: "下个月"],
        "wizard.dates.custom": [.english: "Custom", .simplifiedChinese: "自定义"],

        // Wizard Step 3
        "wizard.step3.title": [.english: "Set Your Budget", .simplifiedChinese: "设定预算"],
        "wizard.step3.subtitle": [.english: "Optional — helps track spending during your trip", .simplifiedChinese: "可选 — 帮助旅途中追踪花费"],
        "wizard.step3.smart": [.english: "Smart Allocation", .simplifiedChinese: "智能分配"],
        "wizard.step3.over_budget": [.english: "Over budget by %.0f", .simplifiedChinese: "超出预算 %.0f"],

        // Wizard Step 4
        "wizard.step4.title": [.english: "All Set!", .simplifiedChinese: "一切就绪！"],
        "wizard.step4.subtitle": [.english: "Review your journey before creating", .simplifiedChinese: "创建前确认你的旅程信息"],
        "wizard.step4.untitled": [.english: "Untitled Journey", .simplifiedChinese: "未命名旅程"],
        "wizard.step4.tip1": [.english: "You can add itinerary details after creation", .simplifiedChinese: "创建后可以随时添加行程细节"],
        "wizard.step4.tip2": [.english: "AI can help generate an itinerary for you", .simplifiedChinese: "AI 可以帮你智能生成行程"],

        // MARK: - Budget Categories
        "budget.category.transport": [.english: "Transport", .simplifiedChinese: "交通"],
        "budget.category.accommodation": [.english: "Accommodation", .simplifiedChinese: "住宿"],
        "budget.category.food": [.english: "Food", .simplifiedChinese: "餐饮"],
        "budget.category.tickets": [.english: "Tickets", .simplifiedChinese: "门票"],
        "budget.category.shopping": [.english: "Shopping", .simplifiedChinese: "购物"],
        "budget.category.other": [.english: "Other", .simplifiedChinese: "其他"],

        // Budget Breakdown
        "budget.breakdown.title": [.english: "Budget Details", .simplifiedChinese: "预算详情"],
        "budget.breakdown.total": [.english: "Total Budget", .simplifiedChinese: "总预算"],
        "budget.breakdown.spent": [.english: "Spent: %.0f", .simplifiedChinese: "已花费: %.0f"],
        "budget.breakdown.remaining": [.english: "Remaining: %.0f", .simplifiedChinese: "剩余: %.0f"],
        "budget.breakdown.categories": [.english: "Category Breakdown", .simplifiedChinese: "分类明细"],
        "budget.breakdown.by_type": [.english: "Spending by Activity Type", .simplifiedChinese: "按活动类型花费"],
        "budget.breakdown.no_spending": [.english: "No spending recorded yet", .simplifiedChinese: "暂无花费记录"],
        "budget.warning.over": [.english: "Over budget by %.0f!", .simplifiedChinese: "超支 %.0f！"],
        "budget.warning.near": [.english: "Approaching budget limit", .simplifiedChinese: "接近预算上限"],

        // MARK: - Logic Fixes
        "logic.fix.title": [.english: "Fix Schedule", .simplifiedChinese: "修复日程"],
        "logic.fix.action": [.english: "Fix", .simplifiedChinese: "修复"],
        "logic.fix.shift": [.english: "Push Back", .simplifiedChinese: "延后30分钟"],
        "logic.fix.shift.desc": [.english: "Shift this spot later by 30 minutes", .simplifiedChinese: "将该景点时间延后30分钟"],
        "logic.fix.skip": [.english: "Skip", .simplifiedChinese: "跳过"],
        "logic.fix.skip.desc": [.english: "Remove from today's plan", .simplifiedChinese: "从今日计划中移除"],
        "logic.fix.reorder": [.english: "Optimize Route", .simplifiedChinese: "优化路线"],
        "logic.fix.reorder.desc": [.english: "Reorder spots for better flow", .simplifiedChinese: "重新排序景点以优化路线"],
        "logic.fix.indoor_note": [.english: "Consider indoor alternative", .simplifiedChinese: "考虑室内替代方案"],

        // Post-trip
        "logic.post.similar": [.english: "Plan Similar Trip", .simplifiedChinese: "规划类似旅行"],
        "logic.post.similar_name": [.english: "Like %@", .simplifiedChinese: "类似 %@"],
        "logic.post.metrics": [.english: "TRIP METRICS", .simplifiedChinese: "旅行指标"],
        "logic.metric.completion": [.english: "Completion", .simplifiedChinese: "完成率"],
        "logic.metric.budget": [.english: "Budget", .simplifiedChinese: "预算"],
        "logic.metric.rating": [.english: "Rating", .simplifiedChinese: "评分"],

        // Check-in enhancements
        "checkin.weather.auto": [.english: "AUTO CAPTURED", .simplifiedChinese: "自动捕获"],
        "checkin.duration.hint": [.english: "Suggested %d min", .simplifiedChinese: "建议停留 %d 分钟"],

        // MARK: - Map Gesture Hints
        "map.hint.pinch": [.english: "Pinch to zoom in/out", .simplifiedChinese: "双指缩放地图"],
        "map.hint.drag": [.english: "Drag to pan the map", .simplifiedChinese: "拖动平移地图"],
        "map.hint.tap_marker": [.english: "Tap markers for details", .simplifiedChinese: "点击标记查看详情"],
        "map.hint.got_it": [.english: "Got It!", .simplifiedChinese: "知道了！"],

        // Map download estimation
        "map.download.estimate": [.english: "Download approx. %@ for offline use", .simplifiedChinese: "离线地图下载约 %@"],

        // Route comparison
        "map.compare.title": [.english: "Route Comparison", .simplifiedChinese: "路线对比"],
        "map.compare.subtitle": [.english: "Review the optimized route before applying", .simplifiedChinese: "应用前查看优化后的路线"],
        "map.compare.before": [.english: "BEFORE", .simplifiedChinese: "优化前"],
        "map.compare.after": [.english: "AFTER", .simplifiedChinese: "优化后"],
        "map.compare.apply": [.english: "Apply Optimized Route", .simplifiedChinese: "应用优化路线"],

        // Wizard validation
        "wizard.step1.name_required": [.english: "Please enter a journey name", .simplifiedChinese: "请输入旅程名称"],
        "wizard.step1.name_ok": [.english: "Great name!", .simplifiedChinese: "好名字！"]
    ]
}

// A handy SwiftUI View modifier to effortlessly localize Text Views
public extension Text {
    init(locKey: String) {
        self.init(LanguageManager.shared.localizedString(for: locKey))
    }
}

public extension Button where Label == Text {
    init(locKey: String, action: @escaping () -> Void) {
        self.init(action: action) {
            Text(locKey: locKey)
        }
    }
}

public extension Label where Title == Text, Icon == Image {
    init(locKey: String, systemImage: String) {
        self.init {
            Text(locKey: locKey)
        } icon: {
            Image(systemName: systemImage)
        }
    }
}

public extension View {
    func navigationTitle(locKey: String) -> some View {
        self.navigationTitle(Text(locKey: locKey))
    }
}

public extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
}

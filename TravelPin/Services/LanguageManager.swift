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
        "settings.language": [.english: "Language", .simplifiedChinese: "多语言设置"],
        "settings.appearance": [.english: "Appearance", .simplifiedChinese: "外观偏好"],
        "settings.version": [.english: "Version", .simplifiedChinese: "当前版本"],

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
        "dashboard.featured.badge": [.english: "Featured Trip", .simplifiedChinese: "精选回顾"],

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

        // Footprints Stats (Legacy/Alt)
        "footprints.title": [.english: "Footprint Review", .simplifiedChinese: "足迹回顾"],
        "footprints.stats.total": [.english: "Total Countries", .simplifiedChinese: "足迹国家"],
        "footprints.stats.cities": [.english: "Cities Explored", .simplifiedChinese: "探索城市"],
        "footprints.stats.spots": [.english: "Spots Marked", .simplifiedChinese: "标记地点"],

        // Inspiration
        "inspiration.title": [.english: "Inspiration Plaza", .simplifiedChinese: "灵感广场"],
        "inspiration.header": [.english: "Discover the World", .simplifiedChinese: "探索世界"],
        "inspiration.subtitle": [.english: "Curated experiences from the global architecture.", .simplifiedChinese: "来自全球旅行者的精选体验。"],
        "discover.card.remix": [.english: "Remix This Trip", .simplifiedChinese: "复刻这段旅程"],

        // Travel Detail
        "detail.itinerary.title": [.english: "The Itinerary", .simplifiedChinese: "行程规划"],
        "detail.itinerary.empty": [.english: "No daily plans yet.", .simplifiedChinese: "暂无每日计划"],
        "detail.archive.title": [.english: "Highlights & Archive", .simplifiedChinese: "高光时刻与存档"],
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

        // Settings — About (section keys)
        "settings.about": [.english: "About", .simplifiedChinese: "关于"],
        "settings.about.quote": [.english: "To Explore, To Experience, To Exist.", .simplifiedChinese: "去探索，去体验，去存在。"]
    ]
}

// A handy SwiftUI View modifier to effortlessly localize Text Views
public extension Text {
    init(locKey: String) {
        self.init(LanguageManager.shared.localizedString(for: locKey))
    }
}

public extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
}

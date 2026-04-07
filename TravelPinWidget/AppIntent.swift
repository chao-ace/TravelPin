//
//  AppIntent.swift
//  TravelPinWidget
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "旅行倒计时配置" }
    static var description: IntentDescription { "选择要显示的旅行信息" }

    @Parameter(title: "显示内容", default: "countdown")
    var displayMode: String
}

//
//  Item.swift
//  TravelPin
//
//  Created by chao on 2026/4/5.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

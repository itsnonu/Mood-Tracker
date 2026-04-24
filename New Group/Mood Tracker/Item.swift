//
//  Item.swift
//  Mood Tracker
//
//  Created by Salvador Nuno on 4/23/26.
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

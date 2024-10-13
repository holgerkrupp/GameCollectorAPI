//
//  File.swift
//  GameCollectorAPI
//
//  Created by Holger Krupp on 13.10.24.
//

import Foundation

struct GCPlaytimes: Codable {
    var HLTBid: Int
    var IGDBid: Int
    var name: String
    var playtimes: [Playtime]
    
    struct Playtime: Codable {
        var Time: Int
        var type: String
        var date: String
    }
    }

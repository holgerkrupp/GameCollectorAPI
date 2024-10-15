//
//  File.swift
//  GameCollectorAPI
//
//  Created by Holger Krupp on 13.10.24.
//

import Foundation

public struct GCPlaytimes: Codable, Sendable {
    var HLTBid: Int
    var IGDBid: Int
    var name: String
     var playtimes: [Playtime]
    
    public struct Playtime: Codable, Sendable {
        var Time: Int
        var type: String
        var date: String
    }
    }

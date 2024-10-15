//
//  File.swift
//  GameCollectorAPI
//
//  Created by Holger Krupp on 13.10.24.
//

import Foundation

public struct GCPlaytimes: Codable, Sendable {
    public var HLTBid: Int
    public var IGDBid: Int
    public var name: String
    public var playtimes: [Playtime]
    
    public struct Playtime: Codable, Sendable {
        public var Time: Int
        public var type: String
        public var date: String
    }
    }

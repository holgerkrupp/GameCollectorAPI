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



public class BasicGame: NSObject, Codable{
    public var name: String?
    public var source: String?
    public var sourceID: String?
    
    public var EAN: String?
    public var Platform: String?
    
    public  var Cover: URL?
    
    enum CodingKeys: CodingKey{
        case name, sourceID, source, EAN, platform, cover
    }
    
    required public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self){
            name = try? container.decode(String.self, forKey: .name)
            source = try? container.decode(String?.self, forKey: .source)
            sourceID = try? String(container.decode(Int.self, forKey: .sourceID))
            if sourceID == nil {
                sourceID = try? container.decode(String.self, forKey: .sourceID)
            }
            EAN = try? container.decode(String?.self, forKey: .EAN)
            Platform = try? container.decode(String.self, forKey: .platform)
            Cover = try? container.decode(URL.self, forKey: .cover)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        //   try container.encode(source, forKey: .source)
        try container.encode(sourceID, forKey: .sourceID)
        //try container.encode(JSONString, forKey: .JSONString)
        
    }
}

//
//  File.swift
//  GameCollectorAPI
//
//  Created by Holger Krupp on 13.10.24.
//

import Foundation

public struct GCPlaytimes: Codable, Sendable {
    public var id: Int
    public var IGDBid: Int
    public var name: String
    public var playtimes: [Playtime]
    
    public struct Playtime: Codable, Sendable {
        public var Time: Int
        public var type: String
        public var date: String
    }
    }

public struct GCReleaseIdentifier: Codable, Sendable {
    public var identifier_type: String
    public var identifier_value: String
    public var source_name: String?
    public var is_primary: Int?
    public var created_at: String?
    public var updated_at: String?
}

public struct GCRelease: Codable, Sendable {
    public var id: Int
    public var source: String?
    public var source_id: String?
    public var igdb_id: Int?
    public var name: String
    public var platform: String?
    public var region_code: String?
    public var variant_name: String?
    public var created_at: String?
    public var updated_at: String?
    public var identifiers: [GCReleaseIdentifier]?
}

public struct GCPricePoint: Codable, Sendable {
    public var id: Int?
    public var release_id: Int?
    public var condition_code: String
    public var region_code: String?
    public var variant_name: String?
    public var currency_code: String
    public var amount: Double
    public var source_name: String?
    public var source_item_id: String?
    public var source_url: String?
    public var observed_at: String?
    public var created_at: String?
    public var updated_at: String?
    public var is_legacy_seed: Bool?
}

public struct GCReleasePricesResponse: Codable, Sendable {
    public var release: GCRelease
    public var prices: [GCPricePoint]
}

public struct GCReleasePriceHistoryResponse: Codable, Sendable {
    public var release: GCRelease
    public var history: [GCPricePoint]
}

public struct GCPriceWriteIdentifier: Codable, Sendable {
    public var type: String
    public var value: String
    public var sourceName: String?
    public var isPrimary: Bool?
    
    public init(type: String, value: String, sourceName: String? = nil, isPrimary: Bool? = nil) {
        self.type = type
        self.value = value
        self.sourceName = sourceName
        self.isPrimary = isPrimary
    }
}

public struct GCPriceWriteRelease: Codable, Sendable {
    public var releaseId: Int?
    public var ean: String?
    public var priceChartingId: String?
    public var source: String?
    public var sourceID: String?
    public var igdbId: Int?
    public var name: String?
    public var platform: String?
    public var region: String?
    public var variant: String?
    public var identifiers: [GCPriceWriteIdentifier]?
    
    public init(
        releaseId: Int? = nil,
        ean: String? = nil,
        priceChartingId: String? = nil,
        source: String? = nil,
        sourceID: String? = nil,
        igdbId: Int? = nil,
        name: String? = nil,
        platform: String? = nil,
        region: String? = nil,
        variant: String? = nil,
        identifiers: [GCPriceWriteIdentifier]? = nil
    ) {
        self.releaseId = releaseId
        self.ean = ean
        self.priceChartingId = priceChartingId
        self.source = source
        self.sourceID = sourceID
        self.igdbId = igdbId
        self.name = name
        self.platform = platform
        self.region = region
        self.variant = variant
        self.identifiers = identifiers
    }
}

public struct GCPriceWritePrice: Codable, Sendable {
    public var condition: String
    public var region: String?
    public var variant: String?
    public var currency: String
    public var amount: Double
    public var observedAt: String?
    public var source: String?
    public var sourceItemId: String?
    public var sourceUrl: String?
    
    public init(
        condition: String,
        region: String? = nil,
        variant: String? = nil,
        currency: String,
        amount: Double,
        observedAt: String? = nil,
        source: String? = nil,
        sourceItemId: String? = nil,
        sourceUrl: String? = nil
    ) {
        self.condition = condition
        self.region = region
        self.variant = variant
        self.currency = currency
        self.amount = amount
        self.observedAt = observedAt
        self.source = source
        self.sourceItemId = sourceItemId
        self.sourceUrl = sourceUrl
    }
}

public struct GCPriceWriteRequest: Codable, Sendable {
    public var releaseId: Int?
    public var release: GCPriceWriteRelease?
    public var price: GCPriceWritePrice
    
    public init(releaseId: Int? = nil, release: GCPriceWriteRelease? = nil, price: GCPriceWritePrice) {
        self.releaseId = releaseId
        self.release = release
        self.price = price
    }
}

public struct GCPriceWriteResult: Codable, Sendable {
    public var priceId: Int
    public var release: GCRelease
    public var price: GCPricePoint
}

public struct GCPriceWriteResponse: Codable, Sendable {
    public var message: String
    public var results: [GCPriceWriteResult]
}

public enum collectiontype: Hashable, Sendable {
    case collection
    case wishlist
}

public struct BasicGame:  Codable, Sendable{
    public var name: String?
    public var source: String?
    public var sourceID: String?
    
    public var EAN: String?
    public var Platform: String?
    public var Region: Int?
    
    public  var Cover: URL?
    
    public var AddingTo: collectiontype?
    
    enum CodingKeys: CodingKey{
        case name, sourceID, source, EAN, platform, cover, region
    }
    
    public init(){}
    
     public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self){
            name = try? container.decode(String.self, forKey: .name)
            source = try? container.decode(String?.self, forKey: .source)
            sourceID = try? String(container.decode(Int.self, forKey: .sourceID))
            if sourceID == nil {
                sourceID = try? container.decode(String.self, forKey: .sourceID)
            }
            EAN = try? String(container.decode(Int.self, forKey: .EAN))
            if EAN == nil {
                EAN = try? container.decode(String.self, forKey: .EAN)
            }
            Platform = try? container.decode(String.self, forKey: .platform)
            Cover = try? container.decode(URL.self, forKey: .cover)
            
            Region = try? container.decode(Int.self, forKey: .region)
            if Region == nil {
                Region = try? Int(container.decode(String.self, forKey: .region))
            }
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

// MARK: - DoesItPlay?

/// One physical-release test published by DoesItPlay? (https://www.doesitplay.org),
/// mirrored by the levelcomplete backend so the app doesn't have to scrape the
/// site once per user.
///
/// `offline_play` and `download_required` use the site's own four/three-step
/// scale, normalised into stable codes:
/// - `offline_play`: `yes`, `yes_limited` ("Yes*"), `no`
/// - `download_required`: `no`, `no_minor` ("No*"), `yes_minor` ("Yes*"), `yes`
public struct GCDoesItPlayReport: Codable, Sendable {
    public var id: Int?
    public var title: String?
    public var platform: String?
    public var platform_code: String?
    public var tested_on: String?
    public var region: String?
    public var version: String?
    public var offline_play: String?
    public var download_required: String?
    public var notes: String?
    public var cover: String?
    public var igdb_id: Int?
    public var source_url: String?
    public var tested_at: String?
    public var fetched_at: String?
    public var updated_at: String?

    public init(
        id: Int? = nil,
        title: String? = nil,
        platform: String? = nil,
        platform_code: String? = nil,
        tested_on: String? = nil,
        region: String? = nil,
        version: String? = nil,
        offline_play: String? = nil,
        download_required: String? = nil,
        notes: String? = nil,
        cover: String? = nil,
        igdb_id: Int? = nil,
        source_url: String? = nil,
        tested_at: String? = nil,
        fetched_at: String? = nil,
        updated_at: String? = nil
    ) {
        self.id = id
        self.title = title
        self.platform = platform
        self.platform_code = platform_code
        self.tested_on = tested_on
        self.region = region
        self.version = version
        self.offline_play = offline_play
        self.download_required = download_required
        self.notes = notes
        self.cover = cover
        self.igdb_id = igdb_id
        self.source_url = source_url
        self.tested_at = tested_at
        self.fetched_at = fetched_at
        self.updated_at = updated_at
    }
}

public struct GCDoesItPlayResponse: Codable, Sendable {
    public var message: String?
    public var count: Int?
    public var source: String?
    public var attribution: String?
    public var results: [GCDoesItPlayReport]

    public init(
        message: String? = nil,
        count: Int? = nil,
        source: String? = nil,
        attribution: String? = nil,
        results: [GCDoesItPlayReport] = []
    ) {
        self.message = message
        self.count = count
        self.source = source
        self.attribution = attribution
        self.results = results
    }
}

/// A report the app looked up itself and hands back to the server so the next
/// client gets it from the cache instead of hitting doesitplay.org again.
public struct GCDoesItPlayWriteRequest: Codable, Sendable {
    public var title: String
    public var platform: String?
    public var platformCode: String
    public var testedOn: String?
    public var region: String?
    public var version: String?
    public var offlinePlay: String?
    public var downloadRequired: String?
    public var notes: String?
    public var cover: String?
    public var igdbId: Int?
    public var sourceUrl: String

    public init(
        title: String,
        platform: String? = nil,
        platformCode: String,
        testedOn: String? = nil,
        region: String? = nil,
        version: String? = nil,
        offlinePlay: String? = nil,
        downloadRequired: String? = nil,
        notes: String? = nil,
        cover: String? = nil,
        igdbId: Int? = nil,
        sourceUrl: String
    ) {
        self.title = title
        self.platform = platform
        self.platformCode = platformCode
        self.testedOn = testedOn
        self.region = region
        self.version = version
        self.offlinePlay = offlinePlay
        self.downloadRequired = downloadRequired
        self.notes = notes
        self.cover = cover
        self.igdbId = igdbId
        self.sourceUrl = sourceUrl
    }
}

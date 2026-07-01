// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HowLongToBeatSwift

public actor GCAPIconnector {
    
    
    let APIkey:String
    let APIbaseURL = URL(string: "https://levelcomplete.de/api/v3a/")
    
    
    let endpoints = [
        "playtimes": "playtimes",
        "ean": "ean",
        "prices": "prices"
    ]
    
    public  init(apikey: String) {
        APIkey = apikey
    }
    
    public func getPlaytimes(igdbID: String) async -> [GCPlaytimes]?{
        print("getPlaytimes")
        guard let endpoint = endpoints["playtimes"],
              let APIurl = URL(string: endpoint, relativeTo: APIbaseURL) else {
            print("Invalid URL")
            
            return nil
        }
        let requestURL = APIurl.appending(path: igdbID)
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.addValue(APIkey, forHTTPHeaderField: "APIkey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let session = URLSession.shared
        do{
            let (data, response) = try await session.data(for: request)
            //     print((response as? HTTPURLResponse)?.allHeaderFields ?? "")
            print(String(decoding: data, as: UTF8.self))
            switch (response as? HTTPURLResponse)?.statusCode {
            case 200:
                print("ok")
                let decoder = JSONDecoder()
                let playtimes = try decoder.decode(GCPlaytimes.self, from: data)
                // let gamemodes = parsedData.playTimes
                dump(playtimes)
                return [playtimes]
                
                
                               default:
                return nil
                //     print((response as? HTTPURLResponse)?.statusCode ?? "??")
            }
        }catch{
            print(error)
            return nil
        }
        
    }
    
    public func push(playtimes: [[String: Any]]) async -> Bool?{
        
 
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: playtimes, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            dump(jsonString)
            
            guard let endpoint = endpoints["playtimes"],
                  let APIurl = URL(string: endpoint, relativeTo: APIbaseURL) else {
                print("Invalid URL")
                return nil
            }
            
            var request = URLRequest(url: APIurl)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            request.addValue(APIkey, forHTTPHeaderField: "APIkey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            dump(request)
            dump(request.allHTTPHeaderFields ?? [:])
            dump(request.httpBody ?? Data())
            
            
            let session = URLSession.shared
            do{
                let (data, response) = try await session.data(for: request)
                //     print((response as? HTTPURLResponse)?.allHeaderFields ?? "")
                //    print(String(decoding: data, as: UTF8.self))
                switch (response as? HTTPURLResponse)?.statusCode {
                case 201:
                    print("ok")
                default:
                    print((response as? HTTPURLResponse)?.statusCode ?? "??")
                }
                return true
            }catch{
                print(error)
                return true
            }
            
        }catch{
            print(error)
            return true
        }
    }
    
    public func push(EAN: [String: Any]) async -> Bool?{
        
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: [EAN], options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            dump(jsonString)
            
            guard let endpoint = endpoints["ean"],
                  let APIurl = URL(string: endpoint, relativeTo: APIbaseURL) else {
                print("Invalid URL")
                return nil
            }
            
            var request = URLRequest(url: APIurl)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            request.addValue(APIkey, forHTTPHeaderField: "APIkey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            
            
            let session = URLSession.shared
            do{
                let (data, response) = try await session.data(for: request)
                //     print((response as? HTTPURLResponse)?.allHeaderFields ?? "")
                //    print(String(decoding: data, as: UTF8.self))
                switch (response as? HTTPURLResponse)?.statusCode {
                case 201:
                    print("ok")
                default:
                    print((response as? HTTPURLResponse)?.statusCode ?? "??")
                }
                return true
            }catch{
                print(error)
                return true
            }
            
        }catch{
            print(error)
            return true
        }
    }
    
    public func getGameInfo(EAN: String) async -> [BasicGame]?{
      
        guard let endpoint = endpoints["ean"],
              let APIurl = URL(string: endpoint, relativeTo: APIbaseURL) else {
            print("Invalid URL")
            return nil
        }
        
        let requestURL = APIurl.appending(path: EAN)
            
       
        var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.addValue(APIkey, forHTTPHeaderField: "APIkey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
         
            
            
            let session = URLSession.shared

        do{
            let (data, response) = try await session.data(for: request)
            //     print((response as? HTTPURLResponse)?.allHeaderFields ?? "")
            print(String(decoding: data, as: UTF8.self))
            switch (response as? HTTPURLResponse)?.statusCode {
            case 200:
                print("ok")
                let decoder = JSONDecoder()
                let GameInfo = try decoder.decode([BasicGame].self, from: data)

                return GameInfo
                
                
            default:
                return nil
                //     print((response as? HTTPURLResponse)?.statusCode ?? "??")
            }
        }catch{
            print(error)
            return nil
        }
        
        
        
    }
    
    public func getPrices(
        releaseId: Int? = nil,
        ean: String? = nil,
        identifierType: String? = nil,
        identifierValue: String? = nil,
        condition: String? = nil,
        region: String? = nil,
        variant: String? = nil,
        currency: String? = nil,
        source: String? = nil
    ) async -> GCReleasePricesResponse? {
        guard let endpoint = endpoints["prices"],
              let apiURL = URL(string: endpoint, relativeTo: APIbaseURL) else {
            return nil
        }
        
        let requestURL: URL
        if let releaseId {
            requestURL = apiURL.appending(path: String(releaseId))
        } else {
            guard var components = URLComponents(url: apiURL, resolvingAgainstBaseURL: true) else {
                return nil
            }
            
            var queryItems: [URLQueryItem] = []
            if let ean { queryItems.append(URLQueryItem(name: "ean", value: ean)) }
            if let identifierType { queryItems.append(URLQueryItem(name: "identifierType", value: identifierType)) }
            if let identifierValue { queryItems.append(URLQueryItem(name: "identifierValue", value: identifierValue)) }
            if let condition { queryItems.append(URLQueryItem(name: "condition", value: condition)) }
            if let region { queryItems.append(URLQueryItem(name: "region", value: region)) }
            if let variant { queryItems.append(URLQueryItem(name: "variant", value: variant)) }
            if let currency { queryItems.append(URLQueryItem(name: "currency", value: currency)) }
            if let source { queryItems.append(URLQueryItem(name: "source", value: source)) }
            components.queryItems = queryItems.isEmpty ? nil : queryItems
            
            guard let url = components.url else {
                return nil
            }
            requestURL = url
        }
        
        return await performPriceReadRequest(url: requestURL)
    }
    
    public func getPriceHistory(
        releaseId: Int,
        condition: String? = nil,
        region: String? = nil,
        variant: String? = nil,
        currency: String? = nil,
        source: String? = nil
    ) async -> GCReleasePriceHistoryResponse? {
        guard let endpoint = endpoints["prices"],
              let apiURL = URL(string: endpoint, relativeTo: APIbaseURL) else {
            return nil
        }
        
        let historyURL = apiURL
            .appending(path: String(releaseId))
            .appending(path: "history")
        
        guard var components = URLComponents(url: historyURL, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        var queryItems: [URLQueryItem] = []
        if let condition { queryItems.append(URLQueryItem(name: "condition", value: condition)) }
        if let region { queryItems.append(URLQueryItem(name: "region", value: region)) }
        if let variant { queryItems.append(URLQueryItem(name: "variant", value: variant)) }
        if let currency { queryItems.append(URLQueryItem(name: "currency", value: currency)) }
        if let source { queryItems.append(URLQueryItem(name: "source", value: source)) }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let requestURL = components.url else {
            return nil
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.addValue(APIkey, forHTTPHeaderField: "APIkey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do{
            let (data, response) = try await URLSession.shared.data(for: request)
            switch (response as? HTTPURLResponse)?.statusCode {
            case 200:
                let decoder = JSONDecoder()
                return try decoder.decode(GCReleasePriceHistoryResponse.self, from: data)
            default:
                return nil
            }
        }catch{
            print(error)
            return nil
        }
    }
    
    public func push(price: GCPriceWriteRequest) async -> GCPriceWriteResponse?{
        return await push(prices: [price])
    }
    
    public func push(prices: [GCPriceWriteRequest]) async -> GCPriceWriteResponse?{
        guard let endpoint = endpoints["prices"],
              let apiURL = URL(string: endpoint, relativeTo: APIbaseURL) else {
            return nil
        }
        
        do{
            let encoder = JSONEncoder()
            let body = prices.count == 1 ? try encoder.encode(prices[0]) : try encoder.encode(prices)
            
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.httpBody = body
            request.addValue(APIkey, forHTTPHeaderField: "APIkey")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            switch (response as? HTTPURLResponse)?.statusCode {
            case 201:
                let decoder = JSONDecoder()
                return try decoder.decode(GCPriceWriteResponse.self, from: data)
            default:
                print((response as? HTTPURLResponse)?.statusCode ?? "??")
                print(String(decoding: data, as: UTF8.self))
                return nil
            }
        }catch{
            print(error)
            return nil
        }
    }
    
    private func performPriceReadRequest(url: URL) async -> GCReleasePricesResponse? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(APIkey, forHTTPHeaderField: "APIkey")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        do{
            let (data, response) = try await URLSession.shared.data(for: request)
            switch (response as? HTTPURLResponse)?.statusCode {
            case 200:
                let decoder = JSONDecoder()
                return try decoder.decode(GCReleasePricesResponse.self, from: data)
            default:
                return nil
            }
        }catch{
            print(error)
            return nil
        }
    }
                     
                     
    
}

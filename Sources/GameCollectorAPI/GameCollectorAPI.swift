// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HowLongToBeatSwift

public actor GCAPIconnector {
    
    
    let APIkey:String
    let APIbaseURL = URL(string: "https://levelcomplete.de/api/v3/")
    
    
    let endpoints = [
        "playtimes": "playtimes"
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
        var request = URLRequest(url: APIurl)
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
                let playtimes = try decoder.decode([GCPlaytimes].self, from: data)
                // let gamemodes = parsedData.playTimes
                dump(playtimes)
                return playtimes
                
                
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
                     
                     
    
}


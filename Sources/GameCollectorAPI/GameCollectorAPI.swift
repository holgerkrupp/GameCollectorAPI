// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import HowLongToBeatSwift

actor GCAPIConnector {
    
    
    let APIkey:String
    let APIurl = URL(string: "https://levelcomplete.de/api/v3/")
    
    
    let endpoints = ["playtimes"]
    
    init(apikey: String) {
        APIkey = apikey
    }
    
    func getPlaytimes(igdbID: String) async -> [GCPlaytimes]?{
        print("getPlaytimes")
        var APIurl = URL(string: "https://levelcomplete.de/api/v3/playtimes")!
        let APIkey = "4wcWji4sQqLg2QXFuFyjiaThs3sasdnJxeyZMMrA8tJXwJ3Q4umtNN7Gfna3DTp3GY"
        
        APIurl.append(path: igdbID)
        
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
    
    func push(playtimes: [HowLongToBeatGame]) async{
        
 
        var times : [[String: Any]] = []
        for game in playtimes {
            
            var gameDict = game.dict()
            gameDict["IGDBid"] = self.sourceID ?? ""
            times.append(gameDict)
        }
        
        
        do{
            let jsonData = try JSONSerialization.data(withJSONObject: times, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            dump(jsonString)
            
            let APIurl = URL(string: "https://levelcomplete.de/api/v3/playtimes")!
            let APIkey = "4wcWji4sQqLg2QXFuFyjiaThs3sasdnJxeyZMMrA8tJXwJ3Q4umtNN7Gfna3DTp3GY"
            
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
            }catch{
                print(error)
            }
            
        }catch{
            print(error)
        }
    }
                     
                     
    
}

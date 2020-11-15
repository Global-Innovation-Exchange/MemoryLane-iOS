//
//  UsersProfile.swift
//  MemoryLane
//
//  Created by Yi Zheng on 10/28/20.
//

import Foundation

class UserDataManager {
    
    struct Profile: Codable {
        let first_name: String
        let last_name: String
        let birth_year: Int
        let music: [String]
        let video: [String]
    }
    
    let baseURL = "https://us-central1-memory-lane-954c7.cloudfunctions.net"
    var userId: String

    init(userId: String) {
        self.userId = userId
    }
    
    
    func fetchProfile(profileCompletionHandler: @escaping (Profile?, Error?) -> Void){
        let endpoint = "/getUserProfile?id=\(userId)"
        let url = URL(string: baseURL + endpoint)
        let request = URLRequest(url: url!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error != nil || data == nil {
                print("Client error!")
                return
            }
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                return
            }
            guard let mime = response.mimeType, mime == "application/json" else {
                print("Wrong MIME type!")
                return
            }
            do {
                let jsonDecoder = JSONDecoder()
                let parsedJSON = try jsonDecoder.decode(Profile.self, from: data!)
                profileCompletionHandler(parsedJSON, nil)
            } catch let parseErr {
                print("JSON error: \(parseErr.localizedDescription)")
                print(parseErr)
                profileCompletionHandler(nil, parseErr)
            }
        })
        task.resume()
    }
    
    
//    func fetchPlaylist(mediaType: String) -> [String] {
//        switch mediaType{
//        case "video":
//            return videoList
//        case "music":
//            return musicList
//        default:
//            return []
//        }
//    }
}

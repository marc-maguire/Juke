//
//  DataManager.swift
//  FoodTracker
//
//  Created by Marc Maguire on 2017-06-05.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

import UIKit
import Alamofire


class DataManager {

    lazy var playlists = [Playlist?]()
    lazy var trackArray = [Song]()

    private static var sharedInstance: DataManager = {
        let dataManager = DataManager()
        //do any additional configuration

        return dataManager
    }()

    //MARK: - Init

    private init() {

    }
    //MARK: Accessor Method

    class func shared() -> DataManager {
        return sharedInstance
    }

    //MARK: - Network Calls

    func spotifySearch(searchString: String, completionArray: @escaping ([Song]) -> ()) {

        guard let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? else {
            return
        }

        let sessionDataObj = sessionObj as! Data
        let savedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        let session = savedSession
        let token = session.accessToken

        var urlWithComponents = URLComponents()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]

//        let parameters: Parameters = ["query" : searchString, "type" : "track"]



        urlWithComponents.scheme = "https"
        urlWithComponents.host = "api.spotify.com"
        urlWithComponents.path = "/v1/search"

        let query = URLQueryItem(name: "query", value: searchString)
        let type = URLQueryItem(name: "type", value: "track")
        urlWithComponents.queryItems = [query, type]
        print(urlWithComponents.url!)


        Alamofire.request(urlWithComponents, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
            if let request = dataResponse.request {
            print("\(request)")

            }

            if let status = dataResponse.response?.statusCode {
                switch(status){
                case 200:
                    print("example success")
                default:
                    print("error with response status: \(status)")
                }
            }
            //to get JSON return value
            if let result = dataResponse.result.value {
                let data = result as! [String:AnyObject]



                let tracks = data["tracks"] as! [String:AnyObject]
                let items = tracks["items"] as! [[String:AnyObject]]

                var searchArray = [Song]()

                for item in items {
					
					if let song = Song(trackDict: item) {
						searchArray.append(song)
					}
                }
                completionArray(searchArray)
                print(searchArray)
            }
        }

    }


    func spotifyCurrentUserPlaylists(completionArray: @escaping ([Playlist]) -> ()) {

        guard let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? else {
            return
        }

        let sessionDataObj = sessionObj as! Data
        let savedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        let session = savedSession
        let token = session.accessToken

        var urlWithComponents = URLComponents()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]

        urlWithComponents.scheme = "https"
        urlWithComponents.host = "api.spotify.com"
        urlWithComponents.path = "/v1/me/playlists"


        Alamofire.request(urlWithComponents, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in

            if let status = dataResponse.response?.statusCode {
                switch(status){
                case 200:
                    print("example success")
                default:
                    print("error with response status: \(status)")
                }
            }
            //to get JSON return value
            var playlistArray: [Playlist] = []
            if let result = dataResponse.result.value {
                let data = result as! [String:AnyObject]

                let items = data["items"] as! [[String:AnyObject]]

                for item in items {
					
					if let playlist = Playlist(jsonDictionary: item) {
						playlistArray.append(playlist)
					}
                }
				completionArray(playlistArray)
                print(data)
            }
        }
    }
    func spotifySaveSongForCurrentUser(songURI: String) {
        
        
        guard let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? else {
            return
        }
        
        
        let sessionDataObj = sessionObj as! Data
        let savedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        let session = savedSession
        let token = session.accessToken
        
        var urlWithComponents = URLComponents()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        
        //spotify:track:4qikXelSRKvoCqFcHLB2H2 is the songURI format
        //remove left 14 characters
        
        let editedSongURI = songURI.replacingOccurrences(of: "spotify:track:", with: "")
        
        urlWithComponents.scheme = "https"
        urlWithComponents.host = "api.spotify.com"
        urlWithComponents.path = "/v1/me/tracks"
        

        let query = URLQueryItem(name: "ids", value: editedSongURI)
        
        urlWithComponents.queryItems = [query]
        print(urlWithComponents)
        
        Alamofire.request(urlWithComponents, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            if let status = dataResponse.response?.statusCode {
                switch(status){
                case 200:
                    print("example success")
                default:
                    print("error with response status: \(status)")
                }
            }

            print("Song did finish adding")
            
        }
        
    }

    //playlistURL: String, completion: @escaping ([Song]) -> ()
    func spotifyPlaylistTracks(ownerID: String, playlistID: String, completionArray: @escaping ([Song]) -> ()) {


        guard let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? else {
            return
        }


        let sessionDataObj = sessionObj as! Data
        let savedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        let session = savedSession
        let token = session.accessToken

        var urlWithComponents = URLComponents()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]

        urlWithComponents.scheme = "https"
        urlWithComponents.host = "api.spotify.com"
        urlWithComponents.path = "/v1/users/\(ownerID)/playlists/\(playlistID)/tracks"



        Alamofire.request(urlWithComponents, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in

            if let status = dataResponse.response?.statusCode {
                switch(status){
                case 200:
                    print("example success")
                default:
                    print("error with response status: \(status)")
                }
            }
            //to get JSON return value
            if let result = dataResponse.result.value {

                let data = result as! [String:AnyObject]

                let items = data["items"] as! [[String:AnyObject]]
                print(items)

                var trackArray: [Song] = []
                for item in items {

                    let trackDict = item["track"] as! [String:AnyObject]
                    print(trackDict)
                    let song = Song(trackDict: trackDict)
                    
                    if let song = song {
                        trackArray.append(song)
                    } else {
                        print("Song is nil")
                    }
                   
                }

                print(data)
                completionArray(trackArray)
            }


        }

    }
    
    enum playbackAction {
        case play
        case pause
    }
    
    func playback(action: playbackAction) {
        
        var result: String {
            if action == .play {
            return "play"
        } else {
            return "pause"
        }
        }
        guard let sessionObj:Any = UserDefaults.standard.object(forKey: "SpotifySession") as Any? else {
            return
        }
        
        
        let sessionDataObj = sessionObj as! Data
        let savedSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
        let session = savedSession
        let token = session.accessToken
        
        var urlWithComponents = URLComponents()
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token!)",
            "Accept": "application/json"
        ]
        
        urlWithComponents.scheme = "https"
        urlWithComponents.host = "api.spotify.com"
        urlWithComponents.path = "/v1/me/player/\(result)"
        
        
        
        Alamofire.request(urlWithComponents, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (dataResponse) in
            
            if let status = dataResponse.response?.statusCode {
                switch(status){
                case 200:
                    print("example success")
                default:
                    print("error with response status: \(status)")
                }
            }

                
            }
        
        }

    
}

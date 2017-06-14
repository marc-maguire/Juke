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

                    let song = Song(trackDict: item)

                    searchArray.append(song!)

                }
                completionArray(searchArray)
                print(searchArray)
            }
        }

    }


    func spotifyCurrentUserPlaylists() {

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
            if let result = dataResponse.result.value {
                let data = result as! [String:AnyObject]

                let items = data["items"] as! [[String:AnyObject]]

                for item in items {

                    let playlist = Playlist(jsonDictionary: item)

                    self.playlists.append(playlist)

                }
                print(data)
            }
        }
    }
    //playlistURL: String, completion: @escaping ([Song]) -> ()
    func spotifyPlaylistTracks(ownerID: String, playlistID: String) {


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


                for item in items {

                    let trackDict = item["track"] as! [String:AnyObject]
                    print(trackDict)
                    let song = Song(trackDict: trackDict)

                    self.trackArray.append(song!)
                }

                print(data)

            }


        }

    }
    
}

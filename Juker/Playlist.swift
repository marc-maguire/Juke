//
//  Playlist.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-14.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class Playlist: NSObject {
    
    var name: String
    var trackRequestURL: String
    var playlistID: String
    var ownerID: String
    var image: String
    
    
    init?(jsonDictionary: [String:AnyObject]) {
		//Spotify API sometimes returns bad data that causes crashes on random songs where the JSON is not formatted properly
		guard let owner = jsonDictionary["owner"] as? [String : AnyObject], let images = jsonDictionary["images"] as? [[String : AnyObject]], let name = jsonDictionary["name"] as? String, let trackRequestURL = jsonDictionary["href"] as? String, let playlistID = jsonDictionary["id"] as? String, let ownerID = owner["id"] as? String, let image = images.first?["url"] as? String else {
			print("Spotify Playlist API returned bad data")
			return nil
		}
        self.name = name
        self.trackRequestURL = trackRequestURL
        self.playlistID = playlistID
        self.ownerID = ownerID
        self.image = image
    }
}

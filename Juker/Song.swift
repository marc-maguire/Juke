//
//  Song.swift
//  ConnectedColors
//
//  Created by Marc Maguire on 2017-06-12.
//  Copyright © 2017 Example. All rights reserved.
//

import Foundation

class Song: NSObject, NSCoding {
    
    var title: String
    var artist: String
    var songURI: String
    var album: String
    var albumURI: String
    var duration: TimeInterval
    var isExplicit: Bool
    
    init(withDefaultString: String){

        self.title = withDefaultString
        self.artist = withDefaultString
        self.songURI = withDefaultString
        self.album = withDefaultString
        self.albumURI = withDefaultString
        self.duration = TimeInterval(5)
        self.isExplicit = false
    
    }
    
    init?(trackDict: [String:AnyObject]) {
        
        
        guard let album = trackDict["album"], let artists = album["artists"] as? [[String:AnyObject]] else {
            return nil
        }
        
        self.title = trackDict["name"] as! String
        //sometimes we are getting nil here
        if let artist = artists.first?["name"] {
        self.artist = artist as! String
        } else {
            self.artist = "DJ No Name"
        }
        self.songURI = trackDict["uri"] as! String
        self.album = album["name"] as! String
        self.albumURI = album["uri"] as! String
        self.duration = trackDict["duration_ms"] as! TimeInterval
        self.isExplicit = trackDict["explicit"] as! Bool
        super.init()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.title = aDecoder.decodeObject(forKey: "title") as! String
        self.artist = aDecoder.decodeObject(forKey: "artist") as! String
        self.songURI = aDecoder.decodeObject(forKey: "songURI") as! String
        self.album = aDecoder.decodeObject(forKey: "album") as! String
        self.albumURI = aDecoder.decodeObject(forKey: "albumURI") as! String
        self.duration = aDecoder.decodeDouble(forKey: "duration")
        self.isExplicit = aDecoder.decodeBool(forKey: "explicit")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(artist, forKey: "artist")
        aCoder.encode(songURI, forKey: "songURI")
        aCoder.encode(album, forKey: "album")
        aCoder.encode(albumURI, forKey: "albumURI")
        aCoder.encode(duration, forKey: "duration")
        aCoder.encode(isExplicit, forKey: "explicit")
    }
    
}

//
//  Event.swift
//  Juker
//
//  Created by Marc Maguire on 2017-06-19.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import Foundation

class Event: NSObject, NSCoding {
    
    enum SongAction: String {
        
        case addSong = "addSong"
        case removeSong = "removeSong"
        case togglePlay = "togglePlay"
        case startNewSong = "startNewSong"
        case newUserSyncResponse = "newUserSyncResponse"
        case newUserFinishedSyncing = "newUserFinishedSyncing"
        case newUserSyncRequest = "newUserSyncRequest"
        case newConnectionDetected = "newConnectionDetected"
        case currentSongLiked = "currentSongLiked"
        case currentSongDisliked = "currentSongDisliked"
        
    }

    var songAction: SongAction
    var song: Song
    var totalSongTime: Int
    var timeRemaining: Int
    var timeElapsed: Int
    var index: Int
    
    init(songAction: SongAction, song: Song, totalSongTime: Int, timeRemaining: Int, timeElapsed: Int, index: Int) {
        
        self.songAction = songAction
        self.song = song
        self.totalSongTime = totalSongTime
        self.timeRemaining = timeRemaining
        self.timeElapsed = timeElapsed
        self.index = index
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.songAction = SongAction(rawValue: (aDecoder.decodeObject(forKey: "songAction") as! String))!
        self.song = aDecoder.decodeObject(forKey: "song") as! Song

        self.totalSongTime = Int(aDecoder.decodeInt32(forKey: "totalSongTime"))
        self.timeRemaining = Int(aDecoder.decodeInt32(forKey: "timeRemaining"))
        self.timeElapsed = Int(aDecoder.decodeInt32(forKey: "timeElapsed"))
        self.index = Int(aDecoder.decodeInt32(forKey: "index"))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.songAction.rawValue, forKey: "songAction")
        aCoder.encode(self.song, forKey: "song")
        aCoder.encode(self.totalSongTime, forKey: "totalSongTime")
        aCoder.encode(self.timeRemaining, forKey: "timeRemaining")
        aCoder.encode(self.timeElapsed, forKey: "timeElapsed")
        aCoder.encode(self.index, forKey: "index")
        
    }
    
}

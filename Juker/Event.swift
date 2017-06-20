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
    }

    var songAction: SongAction
    var song: Song
    var totalSongTime: Int
    var timeRemaining: Int
    var timeElapsed: Int
    
    init(songAction: SongAction, song: Song, totalSongTime: Int, timeRemaining: Int, timeElapsed: Int) {
        
        self.songAction = songAction
        self.song = song
        self.totalSongTime = totalSongTime
        self.timeRemaining = timeRemaining
        self.timeElapsed = timeElapsed
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.songAction = SongAction(rawValue: (aDecoder.decodeObject(forKey: "songAction") as! String))!
        self.song = aDecoder.decodeObject(forKey: "song") as! Song

        self.totalSongTime = Int(aDecoder.decodeInt32(forKey: "totalSongTime"))
        self.timeRemaining = Int(aDecoder.decodeInt32(forKey: "timeRemaining"))
        self.timeElapsed = Int(aDecoder.decodeInt32(forKey: "timeElapsed"))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.songAction.rawValue, forKey: "songAction")
        aCoder.encode(self.song, forKey: "song")
        aCoder.encode(self.totalSongTime, forKey: "totalSongTime")
        aCoder.encode(self.timeRemaining, forKey: "timeRemaining")
        aCoder.encode(self.timeElapsed, forKey: "timeElapsed")
        
    }
    
}

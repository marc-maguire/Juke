//
//  PlaylistTableCell.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-19.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class PlaylistTableCell: MGSwipeTableCell {

    
    @IBOutlet weak var trackArtistLabel: UILabel!
    @IBOutlet weak var trackAlbumImage: UIImageView!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var explicitMarkerImage: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.backgroundColor = UIColor(red: 244.0/255, green: 244.0/255, blue: 244.0/255, alpha: 1)
        
        trackAlbumImage.layer.cornerRadius = 6
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
}

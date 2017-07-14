//
//  SearchTrackCell.swift
//  Juker
//
//  Created by Alex Mitchell on 2017-06-21.
//  Copyright © 2017 Alex Mitchell. All rights reserved.
//

import UIKit

class SearchTrackCell: UITableViewCell {


    @IBOutlet weak var trackNameLabel: UILabel!
    
    @IBOutlet weak var trackArtistLabel: UILabel!
    
    @IBOutlet weak var explicitMarkerImage: UIImageView!
   
    @IBOutlet weak var trackAlbumImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        let colorView = UIView()
        colorView.backgroundColor = UIColor(red: 245.0/255, green: 253.0/255, blue: 100.0/255, alpha: 1.0)
        
        self.selectedBackgroundView = colorView

    }
    
}

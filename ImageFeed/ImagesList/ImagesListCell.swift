//
//  ImagesListCell.swift
//  ImageFeed
//
//  Created by Сергей on 28.07.2026.
//

import UIKit

final class ImagesListCell: UITableViewCell {
    
    static let reuseIdentifier = "ImagesListCell"
    

    @IBOutlet var cellImage: UIImageView!
    
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet var likeButton: UIButton!
    

}

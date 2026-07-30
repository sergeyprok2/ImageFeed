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
    @IBOutlet var gradientView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Если градиент ещё не добавлен, создаём его
        if gradientView.layer.sublayers == nil || gradientView.layer.sublayers?.isEmpty == true {
            let gradient = CAGradientLayer()
            gradient.frame = gradientView.bounds
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
            gradientView.layer.insertSublayer(gradient, at: 0)
        } else {
            gradientView.layer.sublayers?.first?.frame = gradientView.bounds
        }
    }
    
}

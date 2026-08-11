//
//  ProfileViewController.swift
//  ImageFeed
//
//  Created by Сергей on 30.07.2026.
//

import UIKit

final class ProfileViewController: UIViewController {
    
    private var avatar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarImageView()
        labels()
        button()
    }
    
    private func avatarImageView() {
        let image = UIImage(named: "avatar")
        let imageview = UIImageView(image: image)
        imageview.layer.cornerRadius = 35
        imageview.clipsToBounds = true
        imageview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageview)
        imageview.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imageview.heightAnchor.constraint(equalToConstant: 70).isActive = true
        imageview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        imageview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        self.avatar = imageview
    }
    
    private func labels() {
        let nameLabel = UILabel()
        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = .systemFont(ofSize: 23, weight: .bold)
        nameLabel.textColor = UIColor(named: "YP White (iOS)")
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        let loginNameLabel = UILabel()
        loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.font = .systemFont(ofSize: 13, weight: .regular)
        loginNameLabel.textColor = UIColor(named: "YP Gray (iOS)")
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Hello, world!"
        descriptionLabel.textColor = UIColor(named: "YP White (iOS)")
        descriptionLabel.font = .systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            nameLabel.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8)
        ])
    }
    
    private func button() {
        let logoutButton = UIButton.systemButton(
            with: UIImage(named: "Exit")!,
            target: self,
            action: #selector(didTapLogoutButton))
        logoutButton.tintColor = UIColor(named: "YP Red (iOS)")
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        logoutButton.centerYAnchor.constraint(equalTo: avatar.centerYAnchor).isActive = true
        logoutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        logoutButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        logoutButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    @objc private func didTapLogoutButton() {}
    
}

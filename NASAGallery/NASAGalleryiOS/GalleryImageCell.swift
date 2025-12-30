//
//  GalleryImageCell.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 02/10/25.
//

import Foundation
import NASAGallery
import UIKit

@MainActor public final class GalleryImageCell: UICollectionViewCell {
    // MARK: - Components
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Init & lifecycle
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupActivityIndicator()
    }
    
    required init?(coder: NSCoder) { nil }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
        self.contentConfiguration = nil
    }
    
    // MARK: - Methods
    
    private func setupActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        bringSpinnerToFront() // Note: most likely not needed
    }
    
    private func bringSpinnerToFront() {
        contentView.bringSubviewToFront(activityIndicator)
    }
    
    public var isLoading: Bool {
        activityIndicator.isAnimating
    }
    
    public func startLoading() {
        activityIndicator.startAnimating()
        bringSpinnerToFront()
    }
    
    public func stopLoading() {
        activityIndicator.stopAnimating()
    }
    
    // Configure content using UIListContentConfiguration to keep the same subtitle style
    func apply(model: GalleryImage) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = model.title
        content.secondaryText = model.date.formatted(date: .abbreviated, time: .omitted)
        self.contentConfiguration = content

    }
}

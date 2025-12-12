//
//  GalleryImageCell.swift
//  NASAGalleryiOS
//
//  Created by Ivo on 02/10/25.
//

import Foundation
import NASAGallery
import UIKit

public final class GalleryImageCell: UICollectionViewCell {
    // Configure content using UIListContentConfiguration to keep the same subtitle style
    func apply(model: GalleryImage) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = model.title
        content.secondaryText = model.date.formatted(date: .abbreviated, time: .omitted)
        self.contentConfiguration = content
    }

    // Note: this will be used later on as TDD flow
//    public override func prepareForReuse() {
//        super.prepareForReuse()
//        // Reset any previous content/accessories
//        self.contentConfiguration = nil
//    }
}

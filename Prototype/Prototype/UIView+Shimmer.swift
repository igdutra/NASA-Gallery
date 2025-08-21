//
//  UIView+Shimmer.swift
//  Prototype
//
//  Created by Ivo on 14/04/25.
//

import UIKit
import Foundation

extension UIView {
    private var shimmerAnimationKey: String { "shimmerAnimation" }
    private var shimmerLayerName: String { "shimmerLayer" } // ✅ NEW: We use this to identify and clean up shimmer later

    func startShimmering() {
        stopShimmering() // ✅ NEW: Always remove previous shimmer before adding a new one

        // ✅ NEW: Bail out early if layout hasn't happened yet
//        guard bounds.width > 0, bounds.height > 0 else {
//            print("Shimmer skipped: bounds are not ready")
//            return
//        }

        // ✅ Same color setup as before, renamed for clarity
        let white = UIColor.white.withAlphaComponent(0.6).cgColor
        let alpha = UIColor.white.withAlphaComponent(0.3).cgColor

        // ✅ CHANGED: Use `CAGradientLayer` as a sublayer instead of `layer.mask`
        // Reason: `layer.mask` hides all content — shimmer becomes invisible if view has no content yet.
        let gradient = CAGradientLayer()
        gradient.name = shimmerLayerName // ✅ NEW: To identify the shimmer later in `stopShimmering`
        gradient.colors = [alpha, white, alpha]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)

        // ✅ NEW: Maintain shimmer aesthetics for rounded corners
        gradient.cornerRadius = layer.cornerRadius
        gradient.masksToBounds = true

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        animation.duration = 1.2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: shimmerAnimationKey)

        // ✅ CHANGED: Use CATransaction to defer sublayer insertion until next run loop
        // Reason: When hosted in SwiftUI or added to the hierarchy late, layout might not be final yet.
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.layer.insertSublayer(gradient, at: 0) // Insert below content
        }
        CATransaction.commit()
    }

    func stopShimmering() {
        // ✅ CHANGED: Now removes only shimmer sublayer, not the entire mask
        // Safer, prevents interfering with other view configuration
        layer.sublayers?.removeAll(where: { $0.name == shimmerLayerName })
    }
}

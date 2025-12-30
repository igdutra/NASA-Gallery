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
    private let retryButton = UIButton(type: .system)

    // MARK: - Init & lifecycle


    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupActivityIndicator()
        setupRetryButton()
    }

    required init?(coder: NSCoder) { nil }

    public override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
        hideRetry()
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

    private func setupRetryButton() {
        retryButton.setTitle("↻", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 32)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.isHidden = true
        contentView.addSubview(retryButton)

        NSLayoutConstraint.activate([
            retryButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func bringSpinnerToFront() {
        contentView.bringSubviewToFront(activityIndicator)
    }
    
    // Note: could that me moved to a private DSL in the tests?
    public var isLoading: Bool {
        activityIndicator.isAnimating
    }

    public var isShowingRetry: Bool {
        !retryButton.isHidden
    }

    /// Test hook: Called when stopLoading() executes. Allows tests to wait for async loading to complete.
    public var onStopLoading: (() -> Void)?

    /// Test hook: Called when showRetry() executes. Allows tests to wait for async error handling to complete.
    public var onShowRetry: (() -> Void)?

    public func startLoading() {
        activityIndicator.startAnimating()
        bringSpinnerToFront()
    }

    public func stopLoading() {
        activityIndicator.stopAnimating()
        onStopLoading?()
    }

    public func showRetry() {
        retryButton.isHidden = false
        onShowRetry?()
    }

    public func hideRetry() {
        retryButton.isHidden = true
    }

    // Configure content using UIListContentConfiguration to keep the same subtitle style
    func apply(model: GalleryImage) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = model.title
        content.secondaryText = model.date.formatted(date: .abbreviated, time: .omitted)
        self.contentConfiguration = content

    }
}

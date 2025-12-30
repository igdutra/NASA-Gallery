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

    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let activityIndicator = UIActivityIndicatorView(style: .medium)
    public let retryButton = UIButton(type: .system)

    // MARK: - Init & lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
        setupTitleLabel()
        setupActivityIndicator()
        setupRetryButton()
    }

    required init?(coder: NSCoder) { nil }

    public override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
        hideRetry()
        imageView.image = nil
        titleLabel.text = nil
    }
    
    // MARK: - Methods

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 9/16) // 16:9 aspect ratio
        ])
    }

    private func setupTitleLabel() {
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

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

    /// Test hook: Called when stopLoading() executes. Allows tests to wait for async loading to complete.
    public var onStopLoading: (() -> Void)?

    /// Test hook: Called when showRetry() executes. Allows tests to wait for async error handling to complete.
    public var onShowRetry: (() -> Void)?

    /// Test hook: Called when display(_:) executes. Allows tests to wait for async image rendering to complete.
    public var onDisplayImage: (() -> Void)?

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

    func apply(model: GalleryImage) {
        titleLabel.text = model.title
    }

    public func display(_ image: UIImage) {
        imageView.image = image
        onDisplayImage?()
    }
}

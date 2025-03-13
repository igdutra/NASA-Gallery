//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

// Reply this with a better solution:    https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

import SwiftUI

struct SwiftUIView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                // Note: clear difference between LazyVStack and VStack: animation only occurs on LazyVStack
                LazyVStack {
                    bigRow(with: .apod1)
                    horizontalRow(size: geometry.size)
                    bigRow(with: .apod10)
                    columnRow(size: geometry.size)
                    bigRow(with: .apod13)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    // MARK: - Row Types
    
    func bigRow(with image: ImageResource) -> some View {
        fillImage(for: image)
    }
    
    func columnRow(size: CGSize) -> some View {
        let totalHeight = size.height
        let firstColumnWidth = size.width / 3
        let goldenRatio: CGFloat = 1.618
        let tallerImageHeight = totalHeight / goldenRatio
        let shorterImageHeight = totalHeight - tallerImageHeight

        return HStack(spacing: 12) {
            VStack(spacing: 4) {
                fillImage(for: .apod2)
                fillImage(for: .apod3)
                fillImage(for: .apod6)
                fillImage(for: .apod8)
                fillImage(for: .apod9)
            }
            .frame(width: firstColumnWidth)
            .smoothEdges()
            
            VStack(spacing: 12) {
                fillImage(for: .apod12)
                    .frame(height: tallerImageHeight)
                    .smoothEdges()
                fillImage(for: .apod14)
                    .frame(height: shorterImageHeight)
                    .smoothEdges()
            }
            .frame(width: firstColumnWidth * 2)
            .smoothEdges()
        }
        .frame(height: totalHeight)
    }
    
    func horizontalRow(size: CGSize) -> some View {
        let height = size.height / 3
        let fifth = size.width / 5
        
        return VStack {
            HStack {
                fillImage(for: .apod11)
                    .frame(maxWidth: fifth * 2.5)
                    .frame(height: height * 0.6)
                    .smoothEdges()
                
                fillImage(for: .apod12)
                    .frame(maxWidth: fifth * 2.5)
                    .smoothEdges()
            }
            .frame(maxHeight: height)
            
            HStack {
                fillImage(for: .apod1)
                    .frame(maxWidth: fifth)
                    .frame(height: height * 0.4)
                    .smoothEdges()
                
                fitImage(for: .apod4)
                    .frame(maxWidth: fifth * 4)
                    .smoothEdges()
                
                fillImage(for: .apod6)
                    .frame(maxWidth: fifth)
                    .frame(height: height * 0.4)
                    .smoothEdges()
            }
            .frame(maxHeight: height)
            
            HStack {
                fitImage(for: .apod5)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: fifth * 4)
                
                fillImage(for: .apod7)
                    .containerRelativeFrame(.horizontal) { size, axis in
                        size * 0.2
                    }
                    .frame(maxHeight: height * 0.6)
                    .smoothEdges()
            }
            .frame(maxHeight: height)
        }
    }
    
    // MARK: - Image Helpers
    
    func fitImage(for resource: ImageResource) -> some View {
        AsyncImageSimulatorView(resource: resource)
            .scaledToFit()
    }
    
    func fillImage(for resource: ImageResource) -> some View {
        AsyncImageSimulatorView(resource: resource)
            .scaledToFill()
    }
}

private extension View {
    func smoothEdges() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    SwiftUIView()
}

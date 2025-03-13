//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

// Reply this with a better solution:    https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

// TODO: fade in

import SwiftUI

struct SwiftUIView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
//                    row1(with: .apod1)
//                    row5(size: geometry.size)
//                    row1(with: .apod15)
                    
                    columnRow(size: geometry.size)
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
        let height1 = totalHeight / (1 + goldenRatio)
        let height2 = totalHeight - height1

        return HStack(spacing: 100) {
            VStack {
                fillImage(for: .apod2)
                    .clipped()
                
                fillImage(for: .apod3)
                    .clipped()
                
                fillImage(for: .apod6)
                    .clipped()
                fillImage(for: .apod8)
                    .clipped()
                fillImage(for: .apod9)
                    .clipped()
            }
            .frame(width: firstColumnWidth)
            .debugBorder()
            
            VStack {
                fillImage(for: .apod4)
                    .smoothEdges()
                    .debugBorder()
                
                fillImage(for: .apod12)
                    .smoothEdges()
                    .debugBorder()
                fillImage(for: .apod13)
                    .smoothEdges()
                    .debugBorder()
            }
            .frame(width: firstColumnWidth * 2)
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
        Image(resource)
            .resizable()
            .scaledToFit()
    }
    
    func fillImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .scaledToFill()
    }
    
    // MARK: - Old Image Helpers
    
    func resizedImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            // .frame(maxWidth: .infinity, maxHeight: 200)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 5)
            .clipped()
    }
    
    func fillBigImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: 300)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 5)
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

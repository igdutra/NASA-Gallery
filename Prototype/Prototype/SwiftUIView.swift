//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import SwiftUI

// Ref:     https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

import SwiftUI

enum RowPattern: CaseIterable {
    case single
    case triple
    case tripleOffset
    case doubleOffset
    
    /// Defines how many images this row needs
    var chunkSize: Int {
        switch self {
        case .single:
            return 1
        case .triple, .tripleOffset:
            return 3
        case .doubleOffset:
            return 2
        }
    }
}

struct SwiftUIView: View {    
    private var randomRows: [RowPattern] {
        var result = [RowPattern]()
        var remaining = apodImages.count
        
        while remaining > 0 {
            let pattern = RowPattern.allCases.randomElement() ?? .single
            
            if pattern.chunkSize <= remaining {
                result.append(pattern)
                remaining -= pattern.chunkSize
            } else {
                result.append(.single)
                remaining -= 1
            }
        }
        return result
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                let rowRanges = stride(from: 0, to: apodImages.count, by: randomRows.first?.chunkSize ?? 1).map { index -> (RowPattern, ArraySlice<ImageResource>) in
                    let pattern = randomRows[min(index / (randomRows.first?.chunkSize ?? 1), randomRows.count - 1)]
                    let rangeEnd = min(index + pattern.chunkSize, apodImages.count)
                    return (pattern, apodImages[index..<rangeEnd])
                }
                
                ForEach(Array(rowRanges.enumerated()), id: \.offset) { _, data in
                    let (pattern, rowImages) = data
                    rowView(for: pattern, images: Array(rowImages))
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    @ViewBuilder
    private func rowView(for pattern: RowPattern, images: [ImageResource]) -> some View {
        switch pattern {
        case .single:
            if let first = images.first {
                Image(first)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(10)
            }
            
        case .triple:
            HStack(spacing: 8) {
                ForEach(images, id: \.self) { img in
                    Image(img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
        case .tripleOffset:
            if images.count == 3 {
                ZStack {
                    HStack(spacing: 8) {
                        Image(images[0])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                        
                        Image(images[1])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(images[2])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(8)
                        .offset(x: 20, y: 80)
                }
                .frame(height: 180)
            }
            
        case .doubleOffset:
            if images.count == 2 {
                ZStack(alignment: .topLeading) {
                    Image(images[0])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 200)
                        .clipped()
                        .cornerRadius(8)
                    
                    Image(images[1])
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .offset(x: 160, y: 50)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
    }
}


#Preview {
    SwiftUIView()
}

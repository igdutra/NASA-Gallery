//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

// Reply this with a better solution:    https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

// TODO: fade in
// TODO: extract Image helpers -> use scale to fit only on big images, smaller ones are fill

import SwiftUI

struct SwiftUIView: View {
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    row5(size: geometry.size)
//                    row4(totalHeight: geometry.size.height)
//                    row1()
//                    row3(totalHeight: geometry.size.height * (1.4)) // Use 2/3 of available space
//                    row1()
//                    row2(totalHeight: geometry.size.height * (2/3)) // Use 2/3 of available space
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    // MARK: - Row Types
    
    func row1() -> some View {
        fillImage(for: .apod1)
    }
    
    func row2(totalHeight: CGFloat) -> some View {
        HStack {
            VStack {
                resizedImage(for: .apod2)
                    .frame(maxHeight: totalHeight / 2)

                resizedImage(for: .apod3)
                    .frame(maxHeight: totalHeight / 2)
                
                resizedImage(for: .apod6)
                    .frame(maxHeight: totalHeight / 2)
            }
            VStack {
                let goldenRatio: CGFloat = 1.618
                let height1 = totalHeight / (1 + goldenRatio) // Right column: golden ratio
                let height2 = totalHeight - height1
                
                resizedImage(for: .apod4)
                    .frame(maxHeight: height1)
                resizedImage(for: .apod5)
                    .clipped()
                    .frame(maxHeight: height2)
            }

        }
        .frame(height: totalHeight)
    }
    
    func row3(totalHeight: CGFloat) -> some View {
        HStack {
            VStack {
                resizedImage(for: .apod10)
                    .frame(maxHeight: totalHeight / 4)

                resizedImage(for: .apod11)
                    .frame(maxHeight: totalHeight / 4)
                
                resizedImage(for: .apod12)
                    .frame(maxHeight: totalHeight / 4)
                
                resizedImage(for: .apod1)
                    .frame(maxHeight: totalHeight / 4)
            }
            .padding(.bottom, 100)

            VStack {
                resizedImage(for: .apod13)
                    .frame(maxHeight: totalHeight / 4)

                resizedImage(for: .apod14)
                    .frame(maxHeight: totalHeight / 4)
                
                resizedImage(for: .apod15)
                    .frame(maxHeight: totalHeight / 4)
                
                resizedImage(for: .apod11)
                    .frame(maxHeight: totalHeight / 4)
            }
            .padding(.top, 100)

        }
        .frame(height: totalHeight)
    }
    
    func row4(totalHeight: CGFloat) -> some View {
        HStack {
            VStack {
                resizedImage(for: .apod1)
                    .frame(maxHeight: totalHeight / 4)

                resizedImage(for: .apod2)
                resizedImage(for: .apod6)
            }
            VStack {
                resizedImage(for: .apod5)
                resizedImage(for: .apod6)
                resizedImage(for: .apod7)
                resizedImage(for: .apod8)
                resizedImage(for: .apod9)

            }
        }
        .frame(height: totalHeight)
    }
    
    func row5(size: CGSize) -> some View {
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

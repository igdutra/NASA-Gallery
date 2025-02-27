//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import SwiftUI

// Ref:     https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size



struct SwiftUIView: View {
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        Grid(alignment: .center) {
            GridRow {
                resizedImage(for : .apod1)
                resizedImage(for: .apod2)
                    .offset(y: 100)
            }
//            .frame(height: 300)
            GridRow {
                resizedImage(for: .apod3)
                    .gridCellColumns(2)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func resizedImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 5)
    }
}

#Preview {
    SwiftUIView()
}


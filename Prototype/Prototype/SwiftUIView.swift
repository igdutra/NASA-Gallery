//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

// Ref:     https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

import SwiftUI

struct SwiftUIView: View {
    
    var body: some View {
        Grid(alignment: .center) {
            // First row with variation in offset
            GridRow {
                resizedImage(for : .apod1)
                resizedImage(for: .apod5)
                    .border(.red)
                    .padding(.top, 100)
            }
        }
        .clipped()
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

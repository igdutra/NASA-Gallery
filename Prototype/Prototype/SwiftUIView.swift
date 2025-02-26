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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(apodImages.enumerated()), id: \.element) { index, resource in
                    Image(resource)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 5)
                        .offset(y: index % 2 != 0 ? 100 : 0) // Offset second column images
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    SwiftUIView()
}


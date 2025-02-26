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
                ForEach(apodImages, id: \.self) { resource in
                    Image(resource)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 5)
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

//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import SwiftUI

// Ref:     https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

struct SwiftUIView: View {
    var body: some View {
        List {
            ForEach(apodImages, id: \.self) { resource in
                Image(resource)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .listRowBackground(Color.black)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea()
    }
}

#Preview {
    SwiftUIView()
}

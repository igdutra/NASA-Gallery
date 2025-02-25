//
//  SwiftUIView.swift
//  Prototype
//
//  Created by Ivo on 25/02/25.
//

import SwiftUI

// Ref:     https://stackoverflow.com/questions/69489035/how-to-get-a-grid-in-swiftui-with-custom-layout-different-cell-size

struct SwiftUIView: View {
    let colors: [Color] = [
        .red,
        .green,
        .blue
    ]
    
    var body: some View {
        List {
            ForEach(colors, id: \.self) { color in
                color
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
    }
}

#Preview {
    SwiftUIView()
}

//
//  Columns.swift
//  Prototype
//
//  Created by Ivo on 28/02/25.
//

import SwiftUI

// Note: Using Grids is more useful for layots that DO NOT vary: Always 2 columns, always same width.

struct Columns: View {
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
        .background(Color.black.edgesIgnoringSafeArea(.all))    }
}

// MARK: - Preview

#Preview {
    Columns()
}

//
//  ContentView.swift
//  Prototype
//
//  Created by Ivo on 21/02/25.
//

import SwiftUI

struct ContentView: View {
        
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

// MARK: - Preview

#Preview {
    ContentView()
}

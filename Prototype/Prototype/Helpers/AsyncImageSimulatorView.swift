//
//  AsyncSimulatorImageView.swift
//  Prototype
//
//  Created by Ivo on 13/03/25.
//

import SwiftUI

struct AsyncImageSimulatorView: View {
    let resource: ImageResource
    @State private var isImageLoaded = false
    
    var body: some View {
        Image(resource)
            .resizable()
            .opacity(isImageLoaded ? 1 : 0)
            .animation(.easeIn(duration: 0.5), value: isImageLoaded)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isImageLoaded = true
                }
            }
    }
}

#Preview {
    AsyncImageSimulatorView(resource: .apod1)
}

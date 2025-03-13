//
//  Grid.swift
//  Prototype
//
//  Created by Ivo on 06/03/25.
//

import SwiftUI

struct GridView: View {
    
    var body: some View {
        ScrollView {
            Grid(alignment: .center) {
                GridRow {
                    column1()
                    column2()
                }
                
                GridRow {
                    fillImage(for: .apod6)
                        .gridCellColumns(2)
                }
                
                GridRow {
                    resizedImage(for: .apod6)
                        .frame(maxHeight: 100, alignment: .center)
                        .gridCellColumns(2)
                }
                
                GridRow {
                    resizedImage(for: .apod10)
                    resizedImage(for: .apod15)
                        
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    func column1() -> some View {
        VStack {
            resizedImage(for: .apod1)
                .padding()
            resizedImage(for: .apod2)
                .padding()
                .frame(height: 100)
        }
    }
    
    func column2() -> some View {
        fillImage(for: .apod5)
    }
    
    func resizedImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 200, alignment: .trailing)
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 5)
    }
    
    func fillImage(for resource: ImageResource) -> some View {
        Image(resource)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: 300)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 5)
    }
}

// MARK: - Preview

#Preview {
    GridView()
}

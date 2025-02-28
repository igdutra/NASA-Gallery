import SwiftUI

#if DEBUG
extension View {
    func debugChanges() -> Self {
        Self._printChanges()
        return self
    }
    
    func debugPrint(_ value: Any) -> Self {
        print("\(value)")
        return self
    }
    
    func debugBorder(_ color: Color = .red, width: CGFloat = 3) -> some View {
        border(color, width: width)
    }
    
    func debugBackground(_ color: Color = .red) -> some View {
        background(color)
    }
    
    func debugSize(_ message: String = .init()) -> some View {
        modifier(SizeLogger(message: message))
    }
}

struct SizeLogger: ViewModifier {
    let message: String
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        // swiftlint:disable:next no_print
                        print("\n\nView size for \(message): width \(geometry.size.width) height \(geometry.size.height) \n\n")
                    }
            })
    }
}
#endif

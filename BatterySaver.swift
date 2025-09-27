import SwiftUI

struct BatterySaver: View {
    var action: () -> ()
    var resume: () -> ()
    
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    
    var body: some View {
        let isCompact = hSizeClass == .compact || vSizeClass == .compact
        
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .blur(radius: 10)
            Button(action: {
                resume()
            }) {
                Image(systemName: "playpause.fill")
                    .font(.system(size: isCompact ? 40 : 80))
                    .foregroundColor(.gray)
                    .padding(isCompact ? 10 : 20)
                    .background(
                        GeometryReader { geometry in
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        })
            }
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        }
        .onAppear {
            action()
        }
    }
}

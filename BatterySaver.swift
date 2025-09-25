import SwiftUI

struct BatterySaver: View {
    var action: () -> ()
    var resume: () -> ()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .blur(radius: 10)
            Button(action: {
                resume()
            }) {
                Image(systemName: "playpause.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                    .padding(20)
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

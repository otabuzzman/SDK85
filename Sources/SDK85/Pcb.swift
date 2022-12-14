import SwiftUI

struct Pcb: View {
    var i8279: I8279
    var isPortrait: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("sdk85-pcb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    maxWidth: isPortrait ? UIScreen.main.bounds.width : nil,
                    maxHeight: isPortrait ? nil : UIScreen.main.bounds.height,
                    alignment: .bottomTrailing)
                .overlay(Credit(), alignment: .topLeading)
            
            VStack {
                Display(i8279: i8279)
                Keyboard(i8279: i8279)
            }
            .padding(8)
            .background(.pcbLabel.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

struct Credit: View {
    var body: some View {
        ZStack {
            Text("Credit: [SDK-85 printed cicuit board](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) photo by [Hans Otten](http://retro.hansotten.nl/contact/) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)")
                .foregroundColor(.pcbText)
                .accentColor(.pcbLink)
                .padding(4)
        }
        .background(.pcbLabel)
        .cornerRadius(12)
        .padding(4)
    }
}

struct OnRotate: ViewModifier {
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { orientation in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(OnRotate(action: action))
    }
}

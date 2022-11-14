import SwiftUI

struct Tty: View {
    @ObservedObject var intIO: IntIO
    
    var isPortrait: Bool
    
    var crtColor: Dictionary<String, Color> = [
        "Amber": .crtAmber,
        "Green": .crtGreen
    ]
    
    var body: some View {
        Text(intIO.SOD)
            .frame(
                width: UIScreen.main.bounds.width,
                height: UIScreen.main.bounds.height,
                alignment: .topLeading)
            .font(Font.custom("Glass_TTY_VT220", size: 42))
            .background(.black)
            .foregroundColor(crtColor[UserDefaults.standard.string(forKey: "crtColor") ?? Default.crtColor])
    }
}

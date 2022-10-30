import SwiftUI

struct Tty: View {
    @ObservedObject var ioPorts: IOPorts

    var crtColor: Dictionary<String, Color> = [
        "Amber": .crtAmber,
        "Green": .crtGreen
    ]
    
    var body: some View {
        Text(ioPorts.SOD)
            .font(Font.custom("Glass_TTY_VT220", size: 42))
            .background(.black)
            .foregroundColor(crtColor[UserDefaults.standard.string(forKey: "crtColor") ?? Default.crtColor])
    }
}

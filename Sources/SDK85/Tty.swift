import SwiftUI

private let crtColorMap: Dictionary<String, Color> = [
    "Amber": .crtAmber,
    "Green": .crtGreen
]

struct Tty: View {
    var intIO: IntIO
    var isPortrait: Bool

    let crtFont = UserDefaults.standard.string(forKey: "crtFont") ?? "Glass_TTY_VT220"
    let crtColor = crtColorMap[UserDefaults.standard.string(forKey: "crtColor") ?? "Green"]!

    var body: some View {
        VStack {
            Monitor(intIO: intIO, crtFont: crtFont, crtColor: crtColor)
            Keyboard(intIO: intIO, crtColor: crtColor)
        }
        .padding(16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}

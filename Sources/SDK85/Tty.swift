import SwiftUI

private let ttyColorMap: Dictionary<String, Color> = [
    "Amber": .ttyAmber,
    "Green": .ttyGreen
]

struct Tty: View {
    var isPortrait: Bool

    let ttyFont = UserDefaults.standard.string(forKey: "ttyFont") ?? "Glass_TTY_VT220"
    let ttyColor = ttyColorMap[UserDefaults.standard.string(forKey: "ttyColor") ?? "Green"]!

    var body: some View {
        VStack {
            Monitor(ttyFont: ttyFont, ttyColor: ttyColor)
            Keyboard(ttyColor: ttyColor)
        }
        .padding(16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}

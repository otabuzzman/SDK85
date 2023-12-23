import SwiftUI

private let ttyColorMap: Dictionary<String, Color> = [
    "Amber": .ttyAmber,
    "Green": .ttyGreen
]

struct Tty: View {
    var circuit: CircuitVM
    var intIO: IntIO
    var isPortrait: Bool

    let ttyFont = UserDefaults.standard.string(forKey: "ttyFont") ?? "Glass_TTY_VT220"
    let ttyColor = ttyColorMap[UserDefaults.standard.string(forKey: "ttyColor") ?? "Green"]!

    var body: some View {
        VStack {
            Monitor(intIO: intIO, ttyFont: ttyFont, ttyColor: ttyColor)
            Keyboard(intIO: intIO, ttyColor: ttyColor)
        }
        .padding(16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}

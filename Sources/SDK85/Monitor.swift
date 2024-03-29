import SwiftUI

private let ttyColorMap: Dictionary<String, Color> = [
    "Amber": .ttyAmber,
    "Green": .ttyGreen
]

struct Monitor: View {
    @EnvironmentObject var circuitIO: CircuitIO
    
    private let ttyFont = UserDefaults.standard.string(forKey: "ttyFont") ?? "Glass_TTY_VT220"
    private let ttyColor = ttyColorMap[UserDefaults.standard.string(forKey: "ttyColor") ?? "Green"]!

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            let characterUnitWidth = " ".width(withFont: UIFont(name: ttyFont, size: 1)!)
            let derivedFontSize = width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))

            ScrollView {
                Text(circuitIO.SOD)
                    .foregroundColor(ttyColor)
                    .font(Font.custom(ttyFont, size: derivedFontSize))
            }
        }
    }
}

extension String {
    func width(withFont font: UIFont) -> CGFloat {
        let attr = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attr)

        return size.width
    }
}

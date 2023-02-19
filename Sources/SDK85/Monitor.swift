import SwiftUI

private let crtColorMap: Dictionary<String, Color> = [
    "Amber": .crtAmber,
    "Green": .crtGreen
]

struct Monitor: View {
    @ObservedObject var intIO: IntIO

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            let crtFont = UserDefaults.standard.string(forKey: "crtFont") ?? "Glass_TTY_VT220"
            let crtColor = UserDefaults.standard.string(forKey: "crtColor") ?? "Green"

            let characterUnitWidth = " ".width(withFont: UIFont(name: crtFont, size: 1)!)
            let derivedFontSize = width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))

            Text(intIO.SOD)
                .foregroundColor(crtColorMap[crtColor])
                .font(Font.custom(crtFont, size: derivedFontSize))
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

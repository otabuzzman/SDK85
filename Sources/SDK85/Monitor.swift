import SwiftUI

struct Monitor: View {
    @ObservedObject var circuit: CircuitVM
    var ttyFont: String
    var ttyColor: Color

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            let characterUnitWidth = " ".width(withFont: UIFont(name: ttyFont, size: 1)!)
            let derivedFontSize = width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))

            ScrollView {
                Text(circuit.SOD)
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

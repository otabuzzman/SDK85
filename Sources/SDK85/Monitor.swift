import SwiftUI

struct Monitor: View {
    @ObservedObject var intIO: IntIO
    var crtFont: String
    var crtColor: Color

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            let characterUnitWidth = " ".width(withFont: UIFont(name: crtFont, size: 1)!)
            let derivedFontSize = width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))

            Text(intIO.SOD)
                .foregroundColor(crtColor)
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

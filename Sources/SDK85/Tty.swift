import SwiftUI

struct Tty: View {
    @ObservedObject var intIO: IntIO
    var isPortrait: Bool
    
    @Environment(\.horizontalSizeClass) var sizeClass
    private let characterUnitWidth = " "
        .width(withFont: UIFont(name: "Glass_TTY_VT220", size: 1)!)
    
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
            .font(Font.custom("Glass_TTY_VT220", size: UIScreen.main.bounds.width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))))
            .background(.black)
            .foregroundColor(crtColor[UserDefaults.standard.string(forKey: "crtColor") ?? Default.crtColor])
    }
}

extension String {
    func width(withFont font: UIFont) -> CGFloat {
        let attr = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attr)
        
        return size.width
    }
}

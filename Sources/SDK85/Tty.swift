import SwiftUI

private var crtColorMap: Dictionary<String, Color> = [
    "Amber": .crtAmber,
    "Green": .crtGreen
]

struct Tty: View {
    @ObservedObject var intIO: IntIO
    var isPortrait: Bool
    
    @Environment(\.horizontalSizeClass) private var sizeClass
        
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            let crtFont = UserDefaults.standard.string(forKey: "crtFont") ?? "Glass_TTY_VT220"
            let crtColor = UserDefaults.standard.string(forKey: "crtColor") ?? "Green"
            
            let characterUnitWidth = " ".width(withFont: UIFont(name: crtFont, size: 1)!)
                
            VStack { // https://swiftui-lab.com/geometryreader-bug/ (FB7971927)
                Text(intIO.SOD)
                    .padding(16)
                    .frame(width: width, height: height, alignment: .topLeading)
                    .font(Font.custom(crtFont, size: UIScreen.main.bounds.width / (characterUnitWidth * (sizeClass == .regular ? 80 : 54))))
                    .background { Color.black } // https://stackoverflow.com/a/71935851
                    .foregroundColor(crtColorMap[crtColor])
            }.frame(width: width, height: height)
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

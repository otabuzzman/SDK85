import SwiftUI
import z80

typealias KeyConfig = (title: String, subtitle1st: String?, subtitle2nd: String?, code: Byte)

let keyboardLayout: [KeyConfig] = [
    ("", "RESET", nil, 0xFF), ("", "VECT", "INTR", 0xFE), ("C", nil, nil, 0x0C), ("D", nil, nil, 0x0D), ("E", nil, nil, 0x0E), ("F", nil, nil, 0x0F),
    ("", "SINGLE", "STEP", 0x15), ("", "GO", nil, 0x12), ("8", "H", nil, 0x08), ("9", "L", nil, 0x09), ("A", nil, nil, 0x0A), ("B", nil, nil, 0x0B),
    ("", "SUBST", "MEM", 0x13), ("", "EXAM", "REG", 0x14), ("4", "SPH", nil, 0x04), ("5", "SPL", nil, 0x05), ("6", "PCH", nil, 0x06), ("7", "PCL", nil, 0x07),
    ("", "NEXT", ",", 0x11), ("", "EXEC", ".", 0x10), ("0", nil, nil, 0x00), ("1", nil, nil, 0x01), ("2", nil, nil, 0x02), ("3", "I", nil, 0x03)
]

struct Keyboard: View {
    @ObservedObject var i8279: I8279
    
    var body: some View {
        let wiggle: CGFloat = 2
        
        VStack(spacing: wiggle) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: wiggle) {
                    ForEach(0..<6, id: \.self) { col in
                        let keyConfig = keyboardLayout[row*6+col]
                        
                        Button(keyConfig.title) {
                            i8279.FIFO.enqueue(keyConfig.code)
                        }
                        .buttonStyle(Key(
                            subtitle1st: keyConfig.subtitle1st,
                            subtitle2nd: keyConfig.subtitle2nd))
                        .frame(maxWidth: 96, maxHeight: 96)
                        .rotationEffect(Angle(degrees: drand48()*wiggle-wiggle/2))
                    }
                }
            }
        }
    }
}

struct Key: ButtonStyle {
    let subtitle1st: String?
    let subtitle2nd: String?
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            let buttonSize = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                TriangledRectangle()
                    .border(.white)
                
                BarreledRectangle(barrelness: 0.12)
                    .fill(.white)
                    .scaleEffect(0.72)
                
                VStack {
                    configuration.label
                        .font(.system(size: buttonSize*0.5))
                        .foregroundColor(Color(white: 0.24))
                    
                    if let subtitle = subtitle1st {
                        Text(subtitle)
                            .font(.system(size: buttonSize*0.15))
                            .offset(y: -buttonSize*0.08)
                    }
                    
                    if let subtitle = subtitle2nd {
                        Text(subtitle)
                            .font(.system(size: buttonSize*0.15))
                            .offset(y: -buttonSize*0.08)
                    }
                }
            }
            // https://swiftui-lab.com/geometryreader-bug/ (FB7971927)
            .frame(width: buttonSize, height: buttonSize, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
        }
    }
}

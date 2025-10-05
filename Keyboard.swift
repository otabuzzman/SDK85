import SwiftUI
import z80

enum KeyLabel {
    case letter
    case control
    case twins
    case blank
}

enum KeyShape {
    case square
    case brick
    case sill
}

enum KeyType {
    case common
    // modifiers
    case shift
    case control
}

struct KeySound {
    var file: String
    var volume: Float = 1
}

typealias KeyConfig = (
    type: KeyType,
    title: String,
    label: KeyLabel,
    shape: KeyShape,
    code: Byte
)

struct Keyboard: View {
    @EnvironmentObject var watchdog: Watchdog
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @State private var shift = false
    @State private var control = false
    
    private let interval = UserDefaults.standard.double(forKey: "watchdogInterval")
    private let keyClick = UserDefaults.standard.bool(forKey: "keyClick")

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        let keySize: CGFloat = isCompact ? 35.05 : 56
        let spacing: CGFloat = isCompact ? 1 : 2
        
        VStack(spacing: spacing) {
            let layout = isCompact ? Keyboard.layoutCompact : Keyboard.layoutRegular
            
            ForEach(layout, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { key in
                        let config = Keyboard.keyList[key]
                        
                        let angle = Double(8 * (key % 8)) // light reflex position on tap area of key
                        
                        switch config.type {
                        case .shift:
                            Button(config.title) {}
                                .buttonStyle(Key(size: keySize, angle: angle, config: config))
                                .buttonActions { // onPress
                                    if keyClick {
                                        Sound.play(Keyboard.keySound[config.code]!)
                                    }
                                    watchdog.restart(interval)
                                    if shift || control { return }
                                    shift.toggle()
                                } onRelease: {
                                    shift.toggle()
                                }
                        case .control:
                            Button(config.title) {}
                                .buttonStyle(Key(size: keySize, angle: angle, config: config))
                                .buttonActions { // onPress
                                    if keyClick {
                                        Sound.play(Keyboard.keySound[config.code]!)
                                    }
                                    watchdog.restart(interval)
                                    if shift || control { return }
                                    control.toggle()
                                } onRelease: {
                                    control.toggle()
                                }
                        case .common:
                            Button(config.title) {
                                if keyClick {
                                    Sound.play(Keyboard.keySound[config.code] ?? Keyboard.defaultKeySound)
                                }
                                watchdog.restart(interval)
                                Task { await i8155.SID(encode(config.code).uppercased()) }
                            }
                            .buttonStyle(Key(size: keySize, angle: angle, config: config))
                        }
                    }
                }
            }
        }
    }
    
    private func encode(_ code: Byte) -> Byte {
        let i = Int(code)
        if control { return Keyboard.encoding[i].control }
        if shift { return Keyboard.encoding[i].shift }
        return Keyboard.encoding[i].base
    }
}

private struct Key: ButtonStyle {
    let size: CGFloat!
    var angle: Double = 0
    let config: KeyConfig!
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    func makeBody(configuration: Configuration) -> some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        
        ZStack {
            let x = (45 - angle) / 90 * 0.4
            RoundedRectangle(cornerRadius: isCompact ? 4 : 8)
                .fill(EllipticalGradient(colors: [.gray, .black], center: .center, startRadiusFraction: 0, endRadiusFraction: 1))
            BezierRectangle()
                .fill(RadialGradient(colors: [.init( white: 0.3, opacity: 1), .init( white: 0.1, opacity: 1)], center: .init(x: 0.3 + x, y: 0.7), startRadius: 0, endRadius: 124))
                .shadow(using: BezierRectangle(), angle: .degrees(angle), color: .gray)
            
            switch config.label {
            case .letter:
                configuration.label
                    .font(.system(size: size * 0.42))
            case .control:
                configuration.label
                    .font(.system(size: size * 0.22))
            case .twins:
                configuration.label
                    .font(.system(size: size * 0.3))
            case .blank:
                configuration.label
            }
        }
        .frame(width: config.shape, height: size)
        .scaleEffect(configuration.isPressed ? 0.94 : 1)
        .foregroundStyle(.white)
    }
}

struct ButtonActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    onPress()
                }
                .onEnded { _ in
                    onRelease()
                })
    }
}

struct BezierRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        let a = min(rect.width, rect.height) * 0.164
        let b = a * 0.32
        let c = rect.width - a
        let d = rect.height - a
        
        return Path { path in
            path.move(to: .init(x: a, y: a))
            
            path.addCurve(to: .init(x: c, y: a),
                          control1: .init(x: a + b, y: a - b),
                          control2: .init(x: c - b, y: a - b))
            path.addCurve(to: .init(x: c, y: d),
                          control1: .init(x: c + b, y: a + b),
                          control2: .init(x: c + b, y: d - b))
            path.addCurve(to: .init(x: a, y: d),
                          control1: .init(x: c - b, y: d + b),
                          control2: .init(x: a + b, y: d + b))
            path.addCurve(to: .init(x: a, y: a),
                          control1: .init(x: a - b, y: d - b),
                          control2: .init(x: a - b, y: a + b))
        }
    }
}

struct KeyShapeWidth: ViewModifier {
    let shape: KeyShape!
    let height: CGFloat!
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    func body(content: Content) -> some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact
        switch shape {
        case .square:
            content
                .frame(width: height, height: height)
        case .brick:
            content
                .frame(width: height * (isCompact ? 1.25 : 1.5), height: height)
        case .sill:
            content
                .frame(width: height * (isCompact ? 5 : 7), height: height)
        case .none:
            content
        }
    }
}

extension View {
    // https://www.hackingwithswift.com/plus/swiftui-special-effects/shadows-and-glows
    func shadow<S: Shape>(using shape: S, angle: Angle = .degrees(0), color: Color = .black, width: CGFloat = 4, blur: CGFloat = 6) -> some View {
        let x = CGFloat(cos(angle.radians - .pi / 2))
        let y = CGFloat(sin(angle.radians - .pi / 2))
        
        return self
            .overlay(shape
                .stroke(color, lineWidth: width)
                .offset(x: x * width * 0.6, y: y * width * 0.6)
                .blur(radius: blur)
                .mask(shape)
            )
    }
    
    func frame(width: KeyShape, height: CGFloat) -> some View {
        self
            .modifier(KeyShapeWidth(shape: width, height: height))
    }
    
    func buttonActions(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self
            .modifier(ButtonActions(onPress: onPress, onRelease: onRelease))
    }
}

extension Byte {
    func uppercased() -> Byte {
        self > 0x60 && 0x7B > self ? self - 0x20 : self
    }
}

// https://www.vt100.net/docs/vt100-ug/chapter3.html#S3.1
extension Keyboard {
    private static let layoutRegular: [[Int]] = [
        // 1st keys row of slimmed down VT100 keyboard
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14],
        // 2nd keys row
        [16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28],
        // 3rd keys row
        [30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43],
        // 4th keys row
        [46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57],
        // 5th keys row 
        [11, 12, 59, 13, 44]
    ]
    
    private static let layoutCompact: [[Int]] = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        [17, 18, 19, 20, 21, 22, 23, 24, 25, 26],
        [32, 33, 34, 35, 36, 37, 38, 39, 40, 43],
        [46, 47, 48, 49, 50, 51, 52, 53, 54, 55],
        [11, 12, 59, 44, 56]
    ]
    
    // VT100 keys
    private static let keyList: [KeyConfig] = [
        // 1st keys row
        (.common, "ESC", .control, .square, 0x00),
        (.common, "!\n1", .twins, .square, 0x01),
        (.common, "@\n2", .twins, .square, 0x02),
        (.common, "#\n3", .twins, .square, 0x03),
        (.common, "$\n4", .twins, .square, 0x04),
        (.common, "%\n5", .twins, .square, 0x05),
        (.common, "^\n6", .twins, .square, 0x06),
        (.common, "&\n7", .twins, .square, 0x07),
        (.common, "*\n8", .twins, .square, 0x08),
        (.common, "(\n9", .twins, .square, 0x09),
        (.common, ")\n0", .twins, .square, 0x0A),
        (.common, "_\n-", .twins, .square, 0x0B),
        (.common, "+\n=", .twins, .square, 0x0C),
        (.common, "~\n`", .twins, .square, 0x0D),
        (.common, "BACK\nSPACE", .control, .square, 0x0E),
        (.common, "BREAK", .control, .square, 0x0F),
        // 2nd keys row
        (.common, "TAB", .control, .brick, 0x10),
        (.common, "Q", .letter, .square, 0x11),
        (.common, "W", .letter, .square, 0x12),
        (.common, "E", .letter, .square, 0x13),
        (.common, "R", .letter, .square, 0x14),
        (.common, "T", .letter, .square, 0x15),
        (.common, "Y", .letter, .square, 0x16),
        (.common, "U", .letter, .square, 0x17),
        (.common, "I", .letter, .square, 0x18),
        (.common, "O", .letter, .square, 0x19),
        (.common, "P", .letter, .square, 0x1A),
        (.common, "{\n[", .twins, .square, 0x1B),
        (.common, "}\n]", .twins, .square, 0x1C),
        (.common, "DELETE", .control, .square, 0x1C),
        // 3rd keys row
        (.control, "CTRL", .control, .square, 0x1E),
        (.common, "CAPS\nLOCK", .control, .brick, 0x1F),
        (.common, "A", .letter, .square, 0x20),
        (.common, "S", .letter, .square, 0x21),
        (.common, "D", .letter, .square, 0x22),
        (.common, "F", .letter, .square, 0x23),
        (.common, "G", .letter, .square, 0x24),
        (.common, "H", .letter, .square, 0x25),
        (.common, "J", .letter, .square, 0x26),
        (.common, "K", .letter, .square, 0x27),
        (.common, "L", .letter, .square, 0x28),
        (.common, ":\n;", .twins, .square, 0x29),
        (.common, "\"\n'", .twins, .square, 0x2A),
        (.common, "RETURN", .control, .brick, 0x2B),
        (.common, "|\n\\", .twins, .square, 0x2C),
        // 4th keys row
        (.shift, "NO\nSCROLL", .control, .brick, 0x2D),
        (.shift, "SHIFT", .control, .brick, 0x2E),
        (.common, "Z", .letter, .square, 0x2F),
        (.common, "X", .letter, .square, 0x30),
        (.common, "C", .letter, .square, 0x31),
        (.common, "V", .letter, .square, 0x32),
        (.common, "B", .letter, .square, 0x33),
        (.common, "N", .letter, .square, 0x34),
        (.common, "M", .letter, .square, 0x35),
        (.common, "<\n,", .twins, .square, 0x36),
        (.common, ">\n.", .twins, .square, 0x37),
        (.common, "?\n/", .twins, .square, 0x38),
        (.shift, "SHIFT", .control, .brick, 0x39),
        (.common, "LINE\nFEED", .control, .square, 0x3A),
        // 5th keys row
        (.common, "", .blank, .sill, 0x3B)
    ]
    
    // ASCII encoding https://en.cppreference.com/w/cpp/language/ascii
    private static let encoding: [(base: Byte, shift: Byte, control: Byte)] = [
        // 1st keys row
        (base: 0x1B, shift: 0x1B, control: 0x1B),
        (base: 0x31, shift: 0x21, control: 0x11),
        (base: 0x32, shift: 0x40, control: 0x12),
        (base: 0x33, shift: 0x23, control: 0x13),
        (base: 0x34, shift: 0x24, control: 0x14),
        (base: 0x35, shift: 0x25, control: 0x15),
        (base: 0x36, shift: 0x5E, control: 0x16),
        (base: 0x37, shift: 0x26, control: 0x17),
        (base: 0x38, shift: 0x2A, control: 0x18),
        (base: 0x39, shift: 0x28, control: 0x19),
        (base: 0x30, shift: 0x29, control: 0x10),
        (base: 0x2D, shift: 0x5F, control: 0x0D),
        (base: 0x3D, shift: 0x2B, control: 0x1D),
        (base: 0x60, shift: 0x7E, control: 0x00),
        (base: 0x08, shift: 0x08, control: 0x08),
        (base: 0x00, shift: 0x00, control: 0x00), // BREAK, no function
        // 2nd keys row
        (base: 0x09, shift: 0x09, control: 0x09),
        (base: 0x71, shift: 0x51, control: 0x11),
        (base: 0x77, shift: 0x57, control: 0x17),
        (base: 0x65, shift: 0x45, control: 0x05),
        (base: 0x72, shift: 0x52, control: 0x12),
        (base: 0x74, shift: 0x54, control: 0x14),
        (base: 0x79, shift: 0x59, control: 0x19),
        (base: 0x75, shift: 0x55, control: 0x15),
        (base: 0x69, shift: 0x49, control: 0x09),
        (base: 0x6F, shift: 0x4F, control: 0x0F),
        (base: 0x70, shift: 0x50, control: 0x10),
        (base: 0x5B, shift: 0x7B, control: 0x1B),
        (base: 0x5D, shift: 0x7D, control: 0x1D),
        (base: 0x7F, shift: 0x7F, control: 0x7F),
        // 3rd keys row
        (base: 0x00, shift: 0x00, control: 0x00), // CTRL
        (base: 0x00, shift: 0x00, control: 0x00), // CAPS LOCK, no function
        (base: 0x61, shift: 0x41, control: 0x01),
        (base: 0x73, shift: 0x53, control: 0x13),
        (base: 0x64, shift: 0x44, control: 0x04),
        (base: 0x66, shift: 0x46, control: 0x06),
        (base: 0x67, shift: 0x47, control: 0x07),
        (base: 0x68, shift: 0x48, control: 0x08),
        (base: 0x6A, shift: 0x4A, control: 0x0A),
        (base: 0x6B, shift: 0x4B, control: 0x0B),
        (base: 0x6C, shift: 0x4C, control: 0x0C),
        (base: 0x3B, shift: 0x3A, control: 0x1B),
        (base: 0x27, shift: 0x22, control: 0x07),
        (base: 0x0D, shift: 0x0D, control: 0x0D),
        (base: 0x5C, shift: 0x7C, control: 0x1C),
        // 4th keys row
        (base: 0x00, shift: 0x00, control: 0x00), // NO SCROLL, no function
        (base: 0x00, shift: 0x00, control: 0x00), // SHIFT
        (base: 0x7A, shift: 0x5A, control: 0x1A),
        (base: 0x78, shift: 0x58, control: 0x18),
        (base: 0x63, shift: 0x43, control: 0x03),
        (base: 0x76, shift: 0x56, control: 0x16),
        (base: 0x62, shift: 0x52, control: 0x02),
        (base: 0x6E, shift: 0x5E, control: 0x0E),
        (base: 0x6D, shift: 0x5D, control: 0x0D),
        (base: 0x2C, shift: 0x3C, control: 0x0C),
        (base: 0x2E, shift: 0x3E, control: 0x0E),
        (base: 0x2F, shift: 0x3F, control: 0x0F),
        (base: 0x00, shift: 0x00, control: 0x00), // SHIFT
        (base: 0x0A, shift: 0x0A, control: 0x0A),
        // 5th keys row
        (base: 0x20, shift: 0x20, control: 0x20)
    ]
}

extension Keyboard {
    private static let defaultKeySound = KeySound(file: "vt100-keyprease-alpha.mp3", volume: 0.4)

    private static let keySound: Dictionary<Byte, KeySound> = [
        0x1E: KeySound(file: "vt100-keypress-shift.mp3", volume: 0.2), // modifier: control
        0x2E: KeySound(file: "vt100-keypress-shift.mp3", volume: 0.2), // modifier: shift (left)
        0x39: KeySound(file: "vt100-keypress-shift.mp3", volume: 0.2), // modifier: shift (right)
        0x3B: KeySound(file: "vt100-keyprease-space.mp3", volume: 0.2), // common: space
        0x2B: KeySound(file: "vt100-keyprease-enter.mp3", volume: 0.2), // common: enter
    ]
}

let asciiList: [String] = ["NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT", "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4", "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS", "US", "SPACE", "!", "\"", "#", "$", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "\\", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "{", "|", "}", "~", "DEL"]

extension Sound {
    static func play(_ keySound: KeySound) {
        Self.play(soundfile: keySound.file, volume: keySound.volume)
    }
}

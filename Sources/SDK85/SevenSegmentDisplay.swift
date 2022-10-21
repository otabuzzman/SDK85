import SwiftUI
import z80

struct SevenSegmentDisplay: View {
    var dcbapgfe: Byte
    var on: Color
    var off: Color
    
    // segments and decimal point enclosed by a bounding box
    // bounding box origin at upper left corner, width 1
    // all dimensions given as fractions of width (1)
    let glyphWidth : CGFloat = 0.76
    let glyphHeight: CGFloat = 1.25
    let glyphSlope = Angle(degrees: 5.5)
    let thickness: CGFloat = 0.13
    let segmentGap: CGFloat = 0.019
    
    init(dcbapgfe: Byte, on: Color = .redLedOn, off: Color = .redLedOff) {
        self.dcbapgfe = dcbapgfe
        self.on = on
        self.off = off
    }
    
    var body: some View {
        Text("8.")
            .foregroundColor(.clear)
            .overlay() {
                GeometryReader { geometry in
                    let w = geometry.size.width
                    let h = w*glyphHeight
                    
                    Parallelogram(slope: glyphSlope) // a
                        .fill((~dcbapgfe & 0x10)>0 ? on : off)
                        .frame(width: w*barSize.width, height: w*barSize.height)
                        .position(x: w*aPosition.x, y: w*aPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x10)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x10)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // b
                        .fill((~dcbapgfe & 0x20)>0 ? on : off)
                        .frame(width: w*pinSize.width, height: w*pinSize.height)
                        .position(x: w*bPosition.x, y: w*bPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x20)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x20)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // c
                        .fill((~dcbapgfe & 0x40)>0 ? on : off)
                        .frame(width: w*pinSize.width, height: w*pinSize.height)
                        .position(x: w*cPosition.x, y: w*cPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x40)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x40)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // d
                        .fill((~dcbapgfe & 0x80)>0 ? on : off)
                        .frame(width: w*barSize.width, height: w*barSize.height)
                        .position(x: w*dPosition.x, y: w*dPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x80)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x80)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // e
                        .fill((~dcbapgfe & 0x01)>0 ? on : off)
                        .frame(width: w*pinSize.width, height: w*pinSize.height)
                        .position(x: w*ePosition.x, y: w*ePosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x01)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x01)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // f
                        .fill((~dcbapgfe & 0x02)>0 ? on : off)
                        .frame(width: w*pinSize.width, height: w*pinSize.height)
                        .position(x: w*fPosition.x, y: w*fPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x02)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x02)>0 ? 3 : 0)
                    Parallelogram(slope: glyphSlope) // g
                        .fill((~dcbapgfe & 0x04)>0 ? on : off)
                        .frame(width: w*barSize.width, height: w*barSize.height)
                        .position(x: w*gPosition.x, y: w*gPosition.y)
                        .glow(
                            color: (~dcbapgfe & 0x04)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x04)>0 ? 3 : 0)
                    Circle() // dp
                        .fill((~dcbapgfe & 0x08)>0 ? on : off)
                        .frame(width: w*thickness, height: w*thickness)
                        .position(x: w-w*thickness/2, y: h-w*thickness/2)
                        .glow(
                            color: (~dcbapgfe & 0x08)>0 ? .red : .clear,
                            radius: (~dcbapgfe & 0x08)>0 ? 3 : 0)
                }
            }
    }
}

extension SevenSegmentDisplay {
    var tanSlope: CGFloat {
        get { tan(glyphSlope.radians) }
    }
    
    var barSize: CGSize {
        get {
            let w = glyphWidth-2*(thickness+segmentGap)+tanSlope*thickness
            
            return CGSize(width: w, height: thickness) }
    }
    
    var pinSize: CGSize {
        get {
            let w = thickness+tanSlope*(glyphHeight-3*segmentGap)/2
            let h = (glyphHeight-3*segmentGap)/2
            
            return CGSize(width: w, height: h) }
    }
    
    var aPosition: CGPoint {
        get {
            let t = thickness
            let g = segmentGap
            let w = barSize.width
            // let W = pinSize.width
            let h = pinSize.height
            let s = tanSlope
            // t+g+w/2+s*(2(h+g)-t), t/2
            let x = t+g+w/2+s*(2*(h+g)-t)
            
            return CGPoint(x: x, y: t/2) }
    }
    
    var bPosition: CGPoint {
        get {
            let t = thickness
            let g = segmentGap
            let w = barSize.width
            let W = pinSize.width
            let h = pinSize.height
            let s = tanSlope
            // W/2+s(h+g)+2g+w-st+t, h/2+g
            let x = W/2+s*(h+g)+2*g+w-s*t+t
            
            return CGPoint(x: x, y: h/2+g) }
    }
    
    var cPosition: CGPoint {
        get {
            let t = thickness
            let g = segmentGap
            let w = barSize.width
            let W = pinSize.width
            let h = pinSize.height
            let s = tanSlope
            // W/2+2g+w-st+t, 1.5h+2g
            let x = W/2+2*g+w-s*t+t
            let y = 1.5*h+2*g
            
            return CGPoint(x: x, y: y) }
    }
    
    var dPosition: CGPoint {
        get {
            let t = thickness
            let g = segmentGap
            let w = barSize.width
            // let W = pinSize.width
            // let h = pinSize.height
            let s = tanSlope
            // t+g-sg+w/2, y-t/2
            let x = t+g-s*g+w/2
            
            return CGPoint(x: x, y: glyphHeight-t/2) }
    }
    
    var ePosition: CGPoint {
        get {
            // let t = thickness
            let g = segmentGap
            // let w = barSize.width
            let W = pinSize.width
            let h = pinSize.height
            // let s = tanSlope
            // W/2, 1.5h+2g
            let y = 1.5*h+2*g
            
            return CGPoint(x: W/2, y: y) }
    }
    
    var fPosition: CGPoint {
        get {
            // let t = thickness
            let g = segmentGap
            // let w = barSize.width
            let W = pinSize.width
            let h = pinSize.height
            let s = tanSlope
            // W/2+s(h+g), h/2+g
            let x = W/2+s*(h+g)
            
            return CGPoint(x: x, y: h/2+g) }
    }
    
    var gPosition: CGPoint {
        get {
            let t = thickness
            let g = segmentGap
            let w = barSize.width
            // let W = pinSize.width
            let h = pinSize.height
            let s = tanSlope
            // t+g+w/2+(h+(g-t)/2)/s, y/2
            let x = t+g+w/2+s*(h+(g-t)/2)
            
            return CGPoint(x: x, y: glyphHeight/2) }
    }
}

struct Parallelogram: Shape {
    let slope: CGFloat
    let flip: Bool
    
    init(slope: Angle, flip: Bool = false) {
        self.slope = tan(slope.radians)
        self.flip = flip
    }
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let slope = rect.maxY*self.slope
            
            if flip {
                path.move(to: CGPoint(x: slope, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX-slope, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: slope, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX-slope, y: rect.maxY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: slope, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            }
        }
    }
}

extension Color {
    static let redLedOn = Color(hue: 1/360, saturation: 0.1, brightness: 1)
    static let redLedOff = Color(hue: 354/360, saturation: 0.84, brightness: 0.55)
    
    static let display = Color(hue: 13/360, saturation: 1, brightness: 0.27)
    static let package = Color(hue: 13/360, saturation: 1, brightness: 0.22)
    
    static let pcbLink = Color(hue: 168/360, saturation: 0.8, brightness: 0.69)
    static let pcbLabel = Color(hue: 132/360, saturation: 0.37, brightness: 0.32)
    static let pcbText = Color(hue: 123/360, saturation: 0.25, brightness: 0.59)
    
    // sRGB
    static let crtAmber = Color(red: Double(0xFD)/255, green: Double(0x93)/255, blue: Double(0x09)/255)
    static let crtGreen = Color(red: 0, green: Double(0xCA)/255, blue: 0)
    // P3
    // static let crtAmber = Color(red: Double(0xEF)/255, green: Double(0x98)/255, blue: Double(0x39)/255)
    // static let crtGreen = Color(red: Double(0x5A)/255, green: Double(0xC6)/255, blue: Double(0x3A)/255)
}

extension ShapeStyle where Self == Color {
    static var display: Color { .display }
    static var package: Color { .package }
    
    static var pcbLabel: Color { .pcbLabel }
    static var pcbText: Color { .pcbText }
}

extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self
            .shadow(color: color, radius: radius/1)
            .shadow(color: color, radius: radius/2)
            .shadow(color: color, radius: radius/3)
    }
}

import SwiftUI
import z80

typealias I8085 = Task<(), Never>

enum Control: Int {
    case pcb
    case tty
}

struct Circuit: View {
    @ObservedObject private var circuitIO = CircuitIO()
    
    @State private var loadCustomMonitor = UserDefaults.standard.bool(forKey: "loadCustomMonitor")
    @State private var loadUserProgram = false
    
    @State private var thisControl: Control = .pcb
    @State private var pastControl: Control = .pcb
    @State private var controlOffset: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isPortrait = UIScreen.main.bounds.isPortrait
    
    @State private var rotateToLandscapeShow = false
    @State private var rotateToLandscapeSeen = false
    
    var body: some View {
        // https://habr.com/en/post/476494/
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                Pcb()
                    .frame(width: UIScreen.main.bounds.width)
                Tty()
                    .frame(width: UIScreen.main.bounds.width)
            }
            .onAnimated(for: controlOffset) {
                guard
                    thisControl != pastControl
                else { return }
                
                circuitIO.control = thisControl
                circuitIO.reset()
            }
        }
        .content.offset(x: controlOffset)
        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
        .gesture(DragGesture()
            .onChanged() { value in
                controlOffset = value.translation.width - UIScreen.main.bounds.width * CGFloat(thisControl.rawValue)
            }
            .onEnded() { value in
                pastControl = thisControl
                if
                    -value.predictedEndTranslation.width > UIScreen.main.bounds.width / 2,
                     let nextDevice = Control(rawValue: thisControl.rawValue + 1)
                {
                    thisControl = nextDevice
                }
                if
                    value.predictedEndTranslation.width > UIScreen.main.bounds.width / 2,
                    let nextDevice = Control(rawValue: thisControl.rawValue - 1)
                {
                    thisControl = nextDevice
                }
                if
                    !rotateToLandscapeSeen,
                    sizeClass == .compact && isPortrait
                {
                    rotateToLandscapeShow = true
                }
                withAnimation {
                    controlOffset = -UIScreen.main.bounds.width * CGFloat(thisControl.rawValue)
                }
            })
        .gesture(TapGesture(count: 2)
            .onEnded {
                loadUserProgram = true
            })
        .onRotate(isPortrait: $isPortrait) { _ in
            controlOffset = -UIScreen.main.bounds.height * CGFloat(thisControl.rawValue)
        }
        .sheet(isPresented: $loadCustomMonitor) {
            BinFileLoader() { result in
                switch result {
                case .success(let monitor):
                    circuitIO.monitor = monitor
                    circuitIO.reset()
                default:
                    break
                }
            }
        }
        .sheet(isPresented: $loadUserProgram) {
            BinFileLoader() { result in
                switch result {
                case .success(let program):
                    circuitIO.program = program
                    circuitIO.reset()
                default:
                    break
                }
            }
        }
        .alert("Rotate to landscape", isPresented: $rotateToLandscapeShow) {
            Button("Good to know") {
                rotateToLandscapeSeen = true
            }
        }
        .environmentObject(circuitIO)
    }
}

// must live outside CircuitIO
var i8155: IntIO!
var i8279: I8279!

@MainActor
class CircuitIO: ObservableObject {
    private var i8085: I8085?
    
    var monitor = try! Data(fromBinFile: "sdk85-0000")!
    var program: Data?
    
    var control: Control = .pcb
    
    init() {
        i8155 = IntIO(self)
        i8279 = I8279(0x1800...0x19FF, self)
        
        reset()
    }
    
    func reset() {
        i8085?.cancel()
        
        i8155.reset()
        i8279.reset()
        
        self.SOD = ""
        i8155.SID = control == .tty ? 0x80 : 0x00
        
        i8085 = Task { await boot(monitor, loadRamWith: program, self) }
    }
    
    // I8085
    // clock output
    @Published var CLK: Double = 0
    // serial output data
    @Published var SOD = ""
    
    // I8279
    // address fields 1...4
    @Published var AF1: Byte = ~0x67 // H
    @Published var AF2: Byte = ~0x77 // A
    @Published var AF3: Byte = ~0x83 // L
    @Published var AF4: Byte = ~0x8F // t.
    // data fields 1...2
    @Published var DF1: Byte = ~0x00
    @Published var DF2: Byte = ~0x00
}

// https://developer.apple.com/documentation/xcode/improving-app-responsiveness
func boot(_ rom: Data, loadRamWith uram: Data?, at addr: UShort = 0x2000, _ circuit: CircuitIO) async {
    var ram = Array<Byte>(repeating: 0, count: 0x10000)
    ram.replaceSubrange(0..<rom.count, with: rom)
    if let uram = uram, addr >= rom.count, uram.count > 0 {
        let a = Int(addr)
        let o = a + uram.count
        ram.replaceSubrange(a..<o, with: uram)
    }
    
    let mem = Memory(ram, 0x1000, [i8279])
    let z80 = Z80(mem, i8155,
                  traceMemory: UserDefaults.traceMemory,
                  traceOpcode: UserDefaults.traceOpcode,
                  traceNmiInt: UserDefaults.traceNmiInt)
    
    var tStatesSum: UInt = 0
    let t0 = Date.timeIntervalSinceReferenceDate
    
    while (!z80.Halt) {
//        let t1 = Date.timeIntervalSinceReferenceDate
        
        let tStates = z80.parse()
        tStatesSum += UInt(tStates)
        
        if i8155.TIMER_IN(pulses: UShort(tStates)) {
            i8155.NMI = true
            if _isDebugAssertConfiguration() { print(z80.dumpStateCompact()) }
        }
        
        /*
         with clock adjustment, the cpu is faster in debug than in release configuration: the reason for this is that no adjustment is required in debug configuration because the CPU is already too slow, but at least it runs at about 1.4 MHz. in release configuration, the adaptation is active, but the sleep nanosecond lasts up to 500ms, at least about 50ms, even if only say 300ms is requested, which causes the CPU to effectively run much slower than requested, also as in the debug configuration.
         */
        
//        let t2 = Date.timeIntervalSinceReferenceDate - t1
//        let t3 = Double(tStates) / 3_072_000 - t2
//        if t3 > 0 {
//            try? await Task.sleep(nanoseconds: UInt64(t3 * 1_000_000_000))
//        }
        
        let t4 = Date.timeIntervalSinceReferenceDate - t0
        if tStatesSum % 10000 == 0 {
            await MainActor.run { [tStatesSum] in circuit.CLK = Double(tStatesSum) / t4 }
        }
        
        if Task.isCancelled { break }
    }
    
    await MainActor.run {
        circuit.AF1 = ~0x67 // H
        circuit.AF2 = ~0x77 // A
        circuit.AF3 = ~0x83 // L
        circuit.AF4 = ~0x87 // t
        
        circuit.DF1 = ~0x70 // 7
        circuit.DF2 = ~0xD7 // 6
    }
}

// https://www.avanderlee.com/swiftui/withanimation-completion-callback/
struct OnAnimatedModifier<Value>: ViewModifier, Animatable where Value: VectorArithmetic {
    var animatableData: Value {
        didSet {
            notifyCompletionFinished()
        }
    }
    
    private var value: Value
    private var completion: () -> Void
    
    init(value: Value, completion: @escaping () -> Void) {
        animatableData = value
        self.value = value
        self.completion = completion
    }
    
    func body(content: Content) -> some View {
        return content
    }
    
    private func notifyCompletionFinished() {
        guard
            animatableData == value
        else { return }
        
        DispatchQueue.main.async {
            completion()
        }
    }
}

struct OnRotate: ViewModifier {
    @Binding var isPortrait: Bool
    let action: (UIDeviceOrientation) -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { orientation in
                // https://stackoverflow.com/a/65586833/9172095
                // UIDevice.orientation not save on app launch
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                
                guard
                    let isPortrait = windowScene?.interfaceOrientation.isPortrait
                else { return }
                
                // interface orientation not affected when rotated to flat 
                if self.isPortrait == isPortrait { return }
                
                self.isPortrait = isPortrait
                
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onAnimated<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) ->  ModifiedContent<Self, OnAnimatedModifier<Value>> {
        return modifier(OnAnimatedModifier(value: value, completion: completion))
    }
    
    func onRotate(isPortrait: Binding<Bool>, action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(OnRotate(isPortrait: isPortrait, action: action))
    }
}

@main 
struct Sdk85: App {
    init() {
        UserDefaults.registerSettingsBundle()
    }
    
    var body: some Scene {
        WindowGroup {
            Circuit()
        }
    }
}

extension Data {
    init?(fromBinFile: String) throws {
        guard
            let binFile = Bundle.main.url(forResource: fromBinFile, withExtension: ".bin")
        else { return nil }
        try self.init(contentsOf: binFile)
    }
}

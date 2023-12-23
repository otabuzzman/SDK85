import SwiftUI
import z80

typealias I8085 = Task<(), Never>

enum Control: Int {
    case pcb
    case tty
}

struct Circuit: View {
    @ObservedObject var circuit = CircuitVM()
    
    @State var monitor = try! Data(fromBinFile: "sdk85-0000")!
    @State private var loadCustomMonitor = UserDefaults.standard.bool(forKey: "loadCustomMonitor")

    @State private var program = Data()
    @State private var loadUserProgram = false

    @State private var i8085: I8085?
    @StateObject private var intIO = IntIO() // interupts and I8155
    @StateObject private var i8279 = I8279(0x1800...0x19FF)

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
                Pcb(circuit: circuit, intIO: intIO, i8279: i8279, isPortrait: isPortrait)
                    .frame(width: UIScreen.main.bounds.width)
                Tty(circuit: circuit, intIO: intIO, isPortrait: isPortrait)
                    .frame(width: UIScreen.main.bounds.width)
            }
            .onAnimated(for: controlOffset) {
                guard
                    thisControl != pastControl
                else { return }

                i8085?.cancel()

                intIO.reset()
                i8279.reset()

                switch thisControl {
                case .pcb:
                    intIO.tty = false
                    intIO.SID = 0x00
                case .tty:
                    intIO.tty = true
                    intIO.SID = 0x80
                }

                i8085 = boot(monitor, loadRamWith: program)
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
        .onAppear {
            i8085 = boot(monitor, loadRamWith: nil)
        }
        .sheet(isPresented: $loadCustomMonitor) {
            BinFileLoader(binData: $monitor) { result in
                switch result {
                case .success(let monitor):
                    i8085?.cancel()
                    i8085 = boot(monitor, loadRamWith: program)
                default:
                    break
                }
            }
        }
        .sheet(isPresented: $loadUserProgram) {
            BinFileLoader(binData: $program) { result in
                switch result {
                case .success(let program):
                    i8085?.cancel()
                    i8085 = boot(monitor, loadRamWith: program)
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
    }
}

class CircuitVM: ObservableObject {
    private var state = NSLock()
    
    // I8085
    private var i8085: I8085?
    // serial IO
    private var _SID: Byte = 0
    var SID: Byte {
        get {
            state.lock()
            defer { state.unlock() }
            return _SID
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _SID = value
        }
    }
    @Published var SOD = ""
    // interrupt flag
    private var _INT = false
    var INT: Bool {
        get {
            state.lock()
            defer { state.unlock() }
            let tmp = _INT
            _INT = false
            return tmp
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _INT = value
        }
    }
    // interrupt data (IM0 and IM2)
    private var _data: Byte = 0x00
    var data: Byte {
        get {
            state.lock()
            defer { state.unlock() }
            let tmp = _data
            _data = 0x00
            return tmp
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _data = value
        }
    }
    
    // I8279
    // address fields 1...4
    @Published var AF1: Byte = ~0x67 // H
    @Published var AF2: Byte = ~0x77 // A
    @Published var AF3: Byte = ~0x83 // L
    @Published var AF4: Byte = ~0x8F // t.
    // data fields 1...2
    @Published var DF1: Byte = ~0x00
    @Published var DF2: Byte = ~0x00
    
    // miscellaneous
    var control: Control = .pcb
    @Published var MHz: Double = 0
}

// https://developer.apple.com/documentation/xcode/improving-app-responsiveness
private func boot(_ rom: Data, loadRamWith uram: Data?, at addr: UShort = 0x2000, _ circuit: CircuitVM) async {
    var ram = Array<Byte>(repeating: 0, count: 0x10000)
    ram.replaceSubrange(0..<rom.count, with: rom)
    if let uram = uram, addr >= rom.count, uram.count > 0 {
        let a = Int(addr)
        let o = a + uram.count
        ram.replaceSubrange(a..<o, with: uram)
    }
    
    let i8155 = IntIO()
    let i8279 = I8279(0x1800...0x19FF)
    let mem = Memory(ram, 0x1000, [i8279])
    let z80 = Z80(mem, i8155,
                        traceMemory: UserDefaults.traceMemory,
                        traceOpcode: UserDefaults.traceOpcode,
                        traceNmiInt: UserDefaults.traceNmiInt)
    
    while (!z80.Halt) {
        let tStates = z80.parse()
        
        if i8155.TIMER_IN(pulses: UShort(tStates)) {
            i8155.NMI = true
            if _isDebugAssertConfiguration() { print(z80.dumpStateCompact()) }
        }
        
        if Task.isCancelled { break }
    }
    
    await MainActor.run() {
        circuit.AF1 = ~0x67 // H
        circuit.AF2 = ~0x77 // A
        circuit.AF3 = ~0x83 // L
        circuit.AF4 = ~0x87 // t
        
        circuit.DF1 = ~0x70 // 7
        circuit.DF2 = ~0xD7 // 6
    }
}

extension Circuit {
    private func boot(_ rom: Data, loadRamWith uram: Data?, at addr: UShort = 0x2000) -> I8085? {
        let fastCPU = UserDefaults.standard.bool(forKey: "fastCPU")
        let priority: TaskPriority = fastCPU ? .medium : .background

        return Task.detached(priority: priority) {
            var ram = Array<Byte>(repeating: 0, count: 0x10000)
            ram.replaceSubrange(0..<rom.count, with: rom)
            if let uram = uram, addr >= rom.count, uram.count > 0 {
                let a = Int(addr)
                let o = a + uram.count
                ram.replaceSubrange(a..<o, with: uram)
            }

            let mem = await Memory(ram, 0x1000, [i8279])
            let c80 = await C80(mem, intIO,
                                traceMemory: UserDefaults.traceMemory,
                                traceOpcode: UserDefaults.traceOpcode,
                                traceNmiInt: UserDefaults.traceNmiInt)

            while (!c80.Halt) {
                c80.parse()
                if Task.isCancelled { break }
            }

            await MainActor.run() {
                i8279.AF1 = ~0x67 // H
                i8279.AF2 = ~0x77 // A
                i8279.AF3 = ~0x83 // L
                i8279.AF4 = ~0x87 // t

                i8279.DF1 = ~0x70 // 7
                i8279.DF2 = ~0xD7 // 6
            }
        }
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

import SwiftUI
import z80

enum Control: Int {
    case pcb
    case tty
}

struct Circuit: View {
    @StateObject private var watchdog = Watchdog()
    private let interval = UserDefaults.standard.double(forKey: "watchdogInterval")
    
    @StateObject private var circuitIO = CircuitIO()
    
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
            ZStack {
                HStack(spacing: 0) {
                    Pcb(isPortrait: isPortrait)
                        .frame(width: UIScreen.main.bounds.width)
                    Tty(isPortrait: isPortrait)
                        .frame(width: UIScreen.main.bounds.width)
                }
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
                withAnimation {
                    controlOffset = -UIScreen.main.bounds.width * CGFloat(thisControl.rawValue)
                }
                
                guard
                    thisControl != pastControl
                else { return }
                
                if
                    !rotateToLandscapeSeen,
                    sizeClass == .compact && isPortrait
                {
                    rotateToLandscapeShow = true
                }
                
                Task {
                    circuitIO.control = thisControl
                    await circuitIO.reset()
                }
                watchdog.alarm = false
                watchdog.restart(interval)
            })
        .gesture(LongPressGesture()
            .onEnded { _ in 
                loadUserProgram = true
            })
        .onRotate(isPortrait: $isPortrait) { _ in
            withAnimation {
                controlOffset = -UIScreen.main.bounds.height * CGFloat(thisControl.rawValue)
            }
        }
        .sheet(isPresented: $loadCustomMonitor) {
            BinFileLoader() { result in
                switch result {
                case .success(let monitor):
                    Task {
                        circuitIO.load(bytes: monitor)
                        await circuitIO.reset()
                    }
                    watchdog.alarm = false
                    watchdog.restart(interval)
                default:
                    break
                }
            }
        }
        .sheet(isPresented: $loadUserProgram) {
            BinFileLoader() { result in
                switch result {
                case .success(let program):
                    Task {
                        circuitIO.load(bytes: program, atMemoryAddress: 0x2000)
                        await circuitIO.reset()
                    }
                    watchdog.alarm = false
                    watchdog.restart(interval)
                default:
                    break
                }
                loadUserProgram = false
            }
        }
        .alert("Rotate to landscape", isPresented: $rotateToLandscapeShow) {
            Button("Good to know") {
                rotateToLandscapeSeen = true
            }
        }
        .onAppear() {
            Task {
                await circuitIO.reset()
                watchdog.restart(interval)
            }
        }
        .environmentObject(watchdog)
        .environmentObject(circuitIO)
    }
}

class Watchdog: ObservableObject {
    @Published var alarm = false
    private var timer: Timer?
    
    func restart(_ interval: TimeInterval) {
        guard interval > 0 else { return }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                withAnimation {
                    self.alarm = true
                }
            }
    }
}

// must live outside CircuitIO
var i8155: IntIO!
var i8279: I8279!

typealias I8085 = Z80

var mem: Memory!
var i8085: I8085!

@MainActor
class CircuitIO: ObservableObject {
    private var runner: Task<(), Never>?
    
    var control: Control = .pcb
    
    init() {
        i8155 = IntIO(self)
        i8279 = I8279(0x1800...0x19FF, self)
        
        mem = Memory(count: 65536, firstRamAddress: 0x1000, [i8279])
        i8085 = I8085(mem, i8155,
                      traceMemory: UserDefaults.traceMemory,
                      traceOpcode: UserDefaults.traceOpcode,
                      traceNmiInt: UserDefaults.traceNmiInt)
        
        let monitor = try! Data(fromBinFile: "sdk85-0000")!
        load(bytes: monitor)
    }
    
    func reset() async {
        cancel()
        
        i8085.reset()
        i8085.Halt = false
        await i8155.reset()
        await i8279.reset()
        
        self.SOD = ""
        await i8155.SID(control == .tty ? 0x80 : 0x00)
        
        resume()
    }
    
    func load(bytes: Data, atMemoryAddress addr: UShort = 0) {
        mem.replaceSubrange(Int(addr)..<bytes.count, with: bytes)
    }
    
    func cancel() {
        runner?.cancel()
    }
    
    func resume() {
        runner = Task { await AppModule.resume(self) }
    }

    // I8085
    // clock output
    @Published var CLK: Double = 0
    // serial output data
    @Published var SOD = ""
    
    // I8279
    // address fields 1...4 (half-bytes swapped, positive logic)
    @Published var AF1: Byte = SevenSegmentDisplay.pgfedcba(for: "H")
    @Published var AF2: Byte = SevenSegmentDisplay.pgfedcba(for: "A")
    @Published var AF3: Byte = SevenSegmentDisplay.pgfedcba(for: "L")
    @Published var AF4: Byte = SevenSegmentDisplay.pgfedcba(for: "t") | 0x80 // append '.'
    // data fields 1...2 (pgfedcba)
    @Published var DF1: Byte = 0x00
    @Published var DF2: Byte = 0x00
}

// https://developer.apple.com/documentation/xcode/improving-app-responsiveness
func resume(_ circuit: CircuitIO) async {
    var tStatesSum: UInt = 0
    let t0 = Date.timeIntervalSinceReferenceDate
    
    while (!i8085.Halt) {
        // let t1 = Date.timeIntervalSinceReferenceDate
        
        let tStates = i8085.parse()
        tStatesSum += UInt(tStates)
        
        if await i8155.TIMER_IN(pulses: UShort(tStates)) {
            await i8155.NMI(true)
            if _isDebugAssertConfiguration() { print(i8085.dumpStateCompact()) }
        }
        
        /*
         with clock adjustment, the cpu is faster in debug than in release configuration: the reason for this is that no adjustment is required in debug configuration because the CPU is already too slow, but at least it runs at about 1.4 MHz. in release configuration, the adaptation is active, but the sleep nanosecond lasts up to 500ms, at least about 50ms, even if only say 300ms is requested, which causes the CPU to effectively run much slower than requested, also as in the debug configuration.
         */
        
        // let t2 = Date.timeIntervalSinceReferenceDate - t1
        // let t3 = Double(tStates) / 3_072_000 - t2
        // if t3 > 0 {
        //     try? await Task.sleep(nanoseconds: UInt64(t3 * 1_000_000_000))
        // }
        
        let t4 = Date.timeIntervalSinceReferenceDate - t0
        if 0...3 ~= tStatesSum % 10000 {
            await MainActor.run { [tStatesSum] in circuit.CLK = Double(tStatesSum) / t4 }
        }
        
        if Task.isCancelled { return }
    }
    
    await MainActor.run {
        circuit.AF1 = SevenSegmentDisplay.pgfedcba(for: "H")
        circuit.AF2 = SevenSegmentDisplay.pgfedcba(for: "A")
        circuit.AF3 = SevenSegmentDisplay.pgfedcba(for: "L")
        circuit.AF4 = SevenSegmentDisplay.pgfedcba(for: "t")
        
        circuit.DF1 = SevenSegmentDisplay.pgfedcba(for: "7")
        circuit.DF2 = SevenSegmentDisplay.pgfedcba(for: "6")
    }
}

// https://www.avanderlee.com/swiftui/withanimation-completion-callback/
struct OnAnimated<Value>: ViewModifier, Animatable where Value: VectorArithmetic {
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
    func onAnimated<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) ->  ModifiedContent<Self, OnAnimated<Value>> {
        self.modifier(OnAnimated(value: value, completion: completion))
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

extension Memory {
    convenience init(count: Int, firstRamAddress: UShort = 0, _ ports: [MPorts]? = nil) {
        let ram = Array<Byte>(repeating: 0, count: Int(count))
        self.init(ram, firstRamAddress, ports)
    }
}

extension SevenSegmentDisplay {
    private static let ASCIIpgfedcbaMap: [Byte] = [
        //         0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
        /* 0 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        /* 1 */ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        /* 2 */ 0x00, 0x86, 0x22, 0x00, 0x6d, 0x00, 0x6f, 0x02, 0x39, 0x0f, 0x63, 0x70, 0x10, 0x40, 0x80, 0x52,
        /* 3 */ 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x09, 0x0d, 0x61, 0x48, 0x43, 0x5b,
        /* 4 */ 0x5b, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71, 0x3d, 0x76, 0x06, 0x1e, 0x00, 0x38, 0x00, 0x37, 0x3f,
        /* 5 */ 0x73, 0x67, 0x50, 0x6d, 0x78, 0x3e, 0x3e, 0x00, 0x76, 0x6e, 0x5b, 0x39, 0x64, 0x0f, 0x23, 0x08,
        /* 6 */ 0x02, 0x5f, 0x7c, 0x58, 0x5e, 0x7b, 0x71, 0x6f, 0x74, 0x04, 0x0e, 0x00, 0x30, 0x00, 0x54, 0x5c,
        /* 7 */ 0x73, 0x67, 0x50, 0x6d, 0x78, 0x1c, 0x1c, 0x00, 0x76, 0x6e, 0x5b, 0x46, 0x06, 0x70, 0x01, 0x00
    ]
    
    static func pgfedcba(for c: Character) -> Byte {
        guard
            let byte = c.asciiValue, byte < 128
        else { return 0x00 }
        return ASCIIpgfedcbaMap[Int(byte)]
    }
}

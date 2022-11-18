import SwiftUI
import z80

typealias I8085 = Task<(), Never>

enum Device: Int {
    case pcb
    case tty
}

struct Hmi: View {
    @State var monitor = try! Data(contentsOf: Bundle.main.url(forResource: "sdk85-0000.bin", withExtension: nil)!)
    @State private var loadCustomMonitor = UserDefaults.standard.bool(forKey: "loadCustomMonitor")
    
    @State private var program = Data()
    @State private var loadUserProgram = false
    
    @State private var i8085: I8085?
    @StateObject private var intIO = IntIO()
    @StateObject private var i8279 = I8279(0x1800...0x19FF)
    
    private var device: [Device] = [.pcb, .tty]
    @State private var thisDeviceIndex = 0
    @State private var prevDeviceIndex = 0
    @State private var deviceOffset: CGFloat = 0
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isPortrait = UIScreen.main.bounds.isPortrait

    @State private var rotateToLandscapeShow = false
    @State private var rotateToLandscapeSeen = false
  
    var body: some View {
        // https://habr.com/en/post/476494/
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                Pcb(i8279: i8279, isPortrait: isPortrait)
                    .frame(width: UIScreen.main.bounds.width)
                Tty(intIO: intIO, isPortrait: isPortrait)
                    .frame(width: UIScreen.main.bounds.width)
            }
            .onAnimated(for: deviceOffset) {
                guard
                    thisDeviceIndex != prevDeviceIndex
                else { return }
                
                i8085?.cancel()
                
                intIO.reset()
                i8279.reset()
                
                switch device[thisDeviceIndex] {
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
        .content.offset(x: deviceOffset)
        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
        .gesture(DragGesture()
            .onChanged() { value in
                deviceOffset = value.translation.width - UIScreen.main.bounds.width * CGFloat(thisDeviceIndex)
            }
            .onEnded() { value in
                prevDeviceIndex = thisDeviceIndex
                if
                    -value.predictedEndTranslation.width > UIScreen.main.bounds.width / 2,
                     thisDeviceIndex < device.count - 1
                {
                    thisDeviceIndex += 1
                }
                if
                    value.predictedEndTranslation.width > UIScreen.main.bounds.width / 2,
                    thisDeviceIndex > 0
                {
                    thisDeviceIndex -= 1
                }
                if
                    !rotateToLandscapeSeen,
                    sizeClass == .compact && isPortrait
                {
                    rotateToLandscapeShow = true
                }
                withAnimation {
                    deviceOffset = -UIScreen.main.bounds.width * CGFloat(thisDeviceIndex)
                }
            })
        .gesture(TapGesture(count: 2)
            .onEnded {
                loadUserProgram = true
            })
        .onRotate { _ in
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
            deviceOffset = -UIScreen.main.bounds.height * CGFloat(thisDeviceIndex)
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
            Button("OK") {
                rotateToLandscapeSeen = true
            }
        }
    }
}

extension Hmi {
    private func boot(_ rom: Data, loadRamWith uram: Data?, at addr: UShort = 0x2000) -> I8085? {
        Task.detached(priority: .background) {
            var ram = Array<Byte>(repeating: 0, count: 0x10000)
            ram.replaceSubrange(0..<rom.count, with: rom)
            if let uram = uram, addr >= rom.count, uram.count > 0 {
                let a = Int(addr)
                let o = a + uram.count
                ram.replaceSubrange(a..<o, with: uram)
            }
            
            let mem = await Memory(ram, 0x1000, [i8279])
            var z80 = await Z80(mem, intIO,
                                traceMemory: Default.traceMemory,
                                traceOpcode: Default.traceOpcode,
                                traceTiming: Default.traceTiming,
                                traceNmiInt: Default.traceNmiInt)
            
            while (!z80.Halt) {
                if Task.isCancelled {
                    break
                }
                let tStates = z80.parse()
                if await intIO.TIMER_IN(pulses: UShort(tStates)) == .elapsed {
                    print(z80.dumpStateCompact())
                    await MainActor.run() { intIO.NMI = true }
                }
                if let key = await i8279.FIFO.dequeue() {
                    switch key {
                    case 0xFF:
                        z80.reset()
                    case 0xFE:
                        await MainActor.run() {
                            intIO.INT = true
                            intIO.data = 0xFF // RST 7
                        }
                    default:
                        await i8279.RL07.enqueue(key)
                        await MainActor.run() {
                            intIO.INT = true
                            intIO.data = 0xEF // RST 5
                        }
                    }
                }
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

extension View {
    func onAnimated<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) ->  ModifiedContent<Self, OnAnimatedModifier<Value>> {
        return modifier(OnAnimatedModifier(value: value, completion: completion))
    }
}

@main 
struct Sdk85: App {
    init() {
        UserDefaults.registerSettingsBundle()
    }
    
    var body: some Scene {
        WindowGroup {
            Hmi()
        }
    }
}

extension UserDefaults {
    static func registerSettingsBundle() {
        if !UserDefaults.standard.bool(forKey: "firstLaunch") {
            UserDefaults.registerDefaultSettings()
            
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
            let build = Bundle.main.infoDictionary?["CFBundleVersion"]
            let versionInfo = "\(version!) (\(build!))"
            UserDefaults.standard.set(versionInfo, forKey: "versionInfo")
            
            UserDefaults.standard.set(true, forKey: "firstLaunch")
        }
    }
    
    static func registerDefaultSettings() {
        guard
            let settingsBundleFile = Bundle.main.url(forResource: "Root.plist", withExtension: nil),
            let settingsBundleData = NSDictionary(contentsOf: settingsBundleFile),
            let preferenceDictionaries = settingsBundleData.object(
                forKey: "PreferenceSpecifiers") as? [[String: AnyObject]]
        else { return }
        
        var defaultSettings = [String : AnyObject]()
        for preferenceDictionary in preferenceDictionaries {
            if
                let key = preferenceDictionary["Key"] as? String,
                let value = preferenceDictionary["DefaultValue"]
            {
                defaultSettings[key] = value
            }
        }
        
        UserDefaults.standard.register(defaults: defaultSettings)
    }
}

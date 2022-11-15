import SwiftUI
import z80

import UniformTypeIdentifiers

enum Device: Int {
    case pcb
    case tty
}

struct Hmi: View {
    var rom: Data
    
    @State var i8085: Task<(), Never>?
    @StateObject var intIO = IntIO()
    @StateObject var i8279 = I8279(0x1800...0x19FF)
    
    private let device: [Device] = [.pcb, .tty]
    @State private var thisDeviceIndex = 0
    @State private var prevDeviceIndex = 0
    @State private var deviceOffset: CGFloat = 0
    
    @State private var isPortrait = UIScreen.main.bounds.isPortrait
    
    init(with rom: Data) {
        self.rom = rom
    }
    
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
                
                i8085 = boot(rom)
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
                withAnimation {
                    deviceOffset = -UIScreen.main.bounds.width * CGFloat(thisDeviceIndex)
                }
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
            i8085 = boot(rom)
        }
    }
}

extension Hmi {
    private func boot(_ rom: Data) -> Task<(), Never> {
        Task.detached(priority: .background) {
            var ram = Array<Byte>(repeating: 0, count: 0x10000)
            ram.replaceSubrange(0..<rom.count, with: rom)
            
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
    @State private var loadCustomMonitor: Bool
    @State private var monitor: Data
    
    init() {
        UserDefaults.registerSettingsBundle()
        
        loadCustomMonitor = UserDefaults.standard.bool(forKey: "loadCustomMonitor")
        
        let url = Bundle.main.url(forResource: "sdk85-0000.bin", withExtension: nil)!
        monitor = try! Data(contentsOf: url)
    }
    
    var body: some Scene {
        WindowGroup {
            Hmi(with: monitor)
                .fileImporter(isPresented: $loadCustomMonitor,
                              allowedContentTypes: [.bin],
                              allowsMultipleSelection: false) { files in
                    guard
                        let monitorFile = try? files.get().first,
                        monitorFile.startAccessingSecurityScopedResource()
                    else { return }
                    defer { monitorFile.stopAccessingSecurityScopedResource() }
                    
                    guard
                        let monitor = try? Data(contentsOf: monitorFile)
                    else { return }
                    
                    self.monitor = monitor
                }
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
                let value = preferenceDictionary["DefaultValue"] {
                defaultSettings[key] = value
            }
        }
        
        UserDefaults.standard.register(defaults: defaultSettings)
    }
}

extension UTType {
    static var bin: UTType {
        UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)!
    }
}

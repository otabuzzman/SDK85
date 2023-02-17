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
    @StateObject private var intIO = IntIO() // interupts and I8155
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
                Pcb(intIO: intIO, i8279: i8279, isPortrait: isPortrait)
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
        .onRotate(isPortrait: $isPortrait) { _ in
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
            Button("Good to know") {
                rotateToLandscapeSeen = true
            }
        }
    }
}

extension Hmi {
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
                                traceMemory: Default.traceMemory,
                                traceOpcode: Default.traceOpcode,
                                traceNmiInt: Default.traceNmiInt)

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
    static var appLaunchedBefore: Bool {
        if UserDefaults.standard.bool(forKey: "launchedBefore") {
            return true
        } else {
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            return false
        }
    }

    static func registerSettingsBundle() {
        if !UserDefaults.appLaunchedBefore {
            UserDefaults.registerUserDefaults(fromPlistFiles: ["Root", "Tty"])

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
            let build = Bundle.main.infoDictionary?["CFBundleVersion"]
            let versionInfo = "\(version!) (\(build!))"
            UserDefaults.standard.set(versionInfo, forKey: "versionInfo")
        }
    }

    static func registerUserDefaults(fromPlistFiles files: [String] = ["Root"]) {
        guard
            let settingsBundle = Bundle.main.url(forResource: "Settings.bundle", withExtension: nil)
        else { return }

        for plist in files {
            let sbUrl = settingsBundle
            guard
                let settingsBundleData =
                    NSDictionary(contentsOf: sbUrl
                        .appendingPathComponent(plist)
                        .appendingPathExtension("plist")),
                let preferenceSpecifiers =
                    settingsBundleData.object(forKey: "PreferenceSpecifiers") as? [[String: AnyObject]]
            else { return }

            var userDefaults = [String : AnyObject]()
            for preferenceSpecifier in preferenceSpecifiers {
                if
                    let key = preferenceSpecifier["Key"] as? String,
                    let value = preferenceSpecifier["DefaultValue"]
                {
                    userDefaults[key] = value
                }
            }

            UserDefaults.standard.register(defaults: userDefaults)
        }
    }
}

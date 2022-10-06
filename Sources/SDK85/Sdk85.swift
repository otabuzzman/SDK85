import SwiftUI
import z80

import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject var i8279 = I8279(0x1800...0x19FF, traceIO: Default.traceIO)
    
    @State private var monitorNotInPlace = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("sdk85-pcb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    maxWidth: UIScreen.main.bounds.width,
                    alignment: .bottomTrailing)
                .overlay(Credit(), alignment: .topLeading)
            
            VStack {
                Display(i8279: i8279)
                Keyboard(i8279: i8279)
            }
            .padding(8)
            .background(.pcbLabel.opacity(0.8))
            .cornerRadius(16)
        }.task {
            Task.detached(priority: .background) {
                guard
                    let url = Bundle.main.url(forResource: "sdk85-0000.bin", withExtension: nil)
                else { return }
                
                let rom = try? Data(contentsOf: url)
                var ram = Array<Byte>(repeating: 0, count: 0x10000)
                ram.replaceSubrange(0..<rom!.count, with: rom!)
                
                let ioPorts = IOPorts(traceIO: Default.traceIO)
                let mem = await Memory(ram, 0x1000, [i8279])
                var z80 = Z80(mem, ioPorts,
                              traceMemory: Default.traceMemory,
                              traceOpcode: Default.traceOpcode,
                              traceTiming: Default.traceTiming,
                              traceNmiInt: Default.traceNmiInt)
                
                while (!z80.Halt) {
                    let tStates = z80.parse()
                    if ioPorts.TIMER_IN(pulses: UShort(tStates)) == .elapsed {
                        print(z80.dumpStateCompact())
                        ioPorts.NMI = true
                    }
                    if let key = await i8279.FIFO.dequeue() {
                        switch key {
                        case 0xFF:
                            z80.reset()
                        case 0xFE:
                            ioPorts.INT = true
                            ioPorts.data = 0xFF // RST 7
                        default:
                            await i8279.RL07.enqueue(key)
                            ioPorts.INT = true
                            ioPorts.data = 0xEF // RST 5
                        }
                    }
                }
            }
        }
        .fileImporter(isPresented: $monitorNotInPlace,
                      allowedContentTypes: [.bin],
                      allowsMultipleSelection: false) { result in
            guard
                let monitorFile = try? result.get().first,
                monitorFile.startAccessingSecurityScopedResource()
            else { return }
            // defer { monitorFile.stopAccessingSecurityScopedResource() }
        }
    }
}

@main 
struct MyApp: App {
    init() {
        UserDefaults.registerSettingsBundle()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct Credit: View {
    var body: some View {
        ZStack {
            Text("Credit: [SDK-85 printed cicuit board](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) photo by [Hans Otten](http://retro.hansotten.nl/contact/) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)")
                .foregroundColor(.pcbText)
                .accentColor(.pcbLink)
                .padding(4)
        }
        .background(.pcbLabel)
        .cornerRadius(12)
        .padding(4)
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

import SwiftUI
import z80

extension UserDefaults {
    static func registerSettingsBundle(fromPlistNamed plist: String = "Root") {
        guard
            let settingsBundleURL = Bundle.main.url(forResource: "Settings", withExtension: "bundle")
        else { return }
        
        func registerDefaults(fromPlistNamed plist: String) {
            let bundle = settingsBundleURL.appendingPathComponent("\(plist).plist")
            
            guard
                let preferenceDictionary = NSDictionary(contentsOf: bundle),
                let preferenceSpecifiers = preferenceDictionary["PreferenceSpecifiers"] as? [[String: Any]]
            else { return }
            
            var defaults = [String: Any]()
            
            for pspec in preferenceSpecifiers {
                // only keys with default values
                if let key = pspec["Key"] as? String,
                   let defaultValue = pspec["DefaultValue"] {
                    defaults[key] = defaultValue
                }
                // recurse child panes
                if let type = pspec["Type"] as? String,
                   type == "PSChildPaneSpecifier",
                   let file = pspec["File"] as? String {
                    registerDefaults(fromPlistNamed: file)
                }
            }
            
            if !defaults.isEmpty {
                UserDefaults.standard.register(defaults: defaults)
            }
        }
        
        registerDefaults(fromPlistNamed: plist)

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        let build = Bundle.main.infoDictionary?["CFBundleVersion"]
        let versionInfo = "\(version!) (\(build!))"
        UserDefaults.standard.set(versionInfo, forKey: "versionInfo")
    }
}

// app specific
extension UserDefaults {
    static let traceMemory: Z80.TraceMemory = { addr, data in
        let debug = _isDebugAssertConfiguration()
        let prefs = UserDefaults.standard.bool(forKey: "traceMemory")
        if !(debug && prefs) { return }

        print(String(format: "  %04X %02X ", addr, data))
    }

    static let traceOpcode: Z80.TraceOpcode = { prefix, opcode, imm, imm16, dimm in
        let debug = _isDebugAssertConfiguration()
        let prefs = UserDefaults.standard.bool(forKey: "traceOpcode")
        if !(debug && prefs) { return }

        print(Z80Mne.mnemonic(prefix, opcode, imm, imm16, dimm))
    }

    static let traceNmiInt: Z80.TraceNmiInt = { interrupt, addr, instruction in
        let debug = _isDebugAssertConfiguration()
        let prefs = UserDefaults.standard.bool(forKey: "traceNmiInt")
        if !(debug && prefs) { return }

        switch interrupt {
        case .Nmi:
            print(String(format: "NMI PC: 0x%04X", addr))
        case .Int0:
            print(String(format: "IM0 instruction: 0x%02X", instruction))
        case .Int1:
            print(String(format: "IM1 PC: 0x%04X", addr))
        case .Int2:
            print(String(format: "IM2 PC: 0x%04X", addr))
        }
    }

    static let traceIO: TraceIO = { rdPort, port, data in
        let debug = _isDebugAssertConfiguration()
        let prefs = UserDefaults.standard.bool(forKey: "traceIO")
        if !(debug && prefs) { return }

        if rdPort {
            print(String(format: "  IN 0x%04X : 0x%02X", port, data))
        } else {
            print(String(format: "  OUT 0x%04X : 0x%02X (%@)", port, data, data.bitsToString))
        }
    }
}

extension Byte {
    var bitsToString: String {
        let b = String(self, radix: 2)
        let a = Array<Character>(repeating: "0", count: 8 - b.count)
        return String("0b" + a + b)
    }

    var reverseBits: Byte {
        var a = (self & 0xF0) >> 4 | (self & 0x0F) << 4
        a = (a & 0xCC) >> 2 | (a & 0x33) << 2
        a = (a & 0xAA) >> 1 | (a & 0x55) << 1
        return a
    }
} 

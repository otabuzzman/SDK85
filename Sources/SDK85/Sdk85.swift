import Foundation
import z80

struct Sdk85 {
}

class I8155 {
}

class I8279 {
    private var _RL07: Byte?

    var RL07: Byte? {
        get {
            let ret = _RL07
            _RL07 = nil
            return ret
        }
        set(newRL07) {
            _RL07 = newRL07
        }
    }
}

final class IOPorts: IPorts
{
    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00

    func rdPort(_ port: UShort) -> Byte
    {
        print(String(format: "  \(#function) : IN 0x%04X", port))
        return 0
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        print(String(format: "  \(#function) : OUT 0x%04X : 0x%02X", port, data))
    }

    var NMI: Bool {
            get {
                let ret = _NMI
                _NMI = false
                return ret
            }
            set(newNMI) {
                _NMI = newNMI
            }
        }
    var INT: Bool {
            get {
                let ret = _INT
                _INT = false
                return ret
            }
            set(newINT) {
                _INT = newINT
            }
        }
    var data: Byte {
            get {
                let ret = _data
                _data = 0x00
                return ret
            }
            set(newData) {
                _data = newData
            }
        }
}

final class MMPorts: MPorts
{
    var i8279 = I8279()

    init(_ mmap: ClosedRange<UShort>) {
        self.mmap = mmap
    }

    func rdPort(_ port: UShort) -> Byte
    {
        var data: Byte = 0
        switch port {
            case 0x1800:
                data = i8279.RL07 ?? 0
            case 0x1900:
                break
            default:
                break
        }

        print(String(format: "  \(#function) : IN 0x%04X (memory mapped) : 0x%02X", port, data))
        return data
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        print(String(format: "  \(#function) : OUT 0x%04X (memory mapped) : 0x%02X", port, data))
    }

    var mmap: ClosedRange<UShort>
}

#if os(Windows)

let kmap: Dictionary<Byte, Byte> = [
    0x30: 0x00, // 0
    0x31: 0x01, // 1
    0x32: 0x02, // 2
    0x33: 0x03, // 3
    0x34: 0x04, // 4
    0x35: 0x05, // 5
    0x36: 0x06, // 6
    0x37: 0x07, // 7
    0x38: 0x08, // 8
    0x39: 0x08, // 9
    0x61: 0x0A, // a
    0x62: 0x0B, // b
    0x63: 0x0C, // c
    0x64: 0x0D, // d
    0x65: 0x0E, // e
    0x66: 0x0F, // f

    0x73: 0x15, // s (SINGLE STEP)
    0x67: 0x12, // g (GO)
    0x6D: 0x13, // m (SUBST MEM)
    0x78: 0x14, // x (EXAM REG)
    0x2C: 0x11, // , (NEXT)
    0x2E: 0x10, // . (EXEC)
]

@main
extension Sdk85 {
    static func main() {
        var ram = Array<Byte>(repeating: 0, count: 0x10000)
        let rom = NSData(contentsOfFile: "Resources/sdk85-0000.bin")
        ram.replaceSubrange(0..<rom!.count, with: rom!)

        let ioports = IOPorts()
        let mmports = MMPorts(0x1800...0x19FF)
        let mem = Memory(ram, 0x1000, [mmports])
        var z80 = Z80(mem, ioports)

        _ = Task { Stdwin.shared.recordUntilEof() }
        defer {
            try? FileManager.default.removeItem(atPath: Stdwin.recordFilePath)
        }

        while (!z80.Halt)
        {
            z80.parse()
            if let key = Stdwin.shared.getKeyPressed() {
                switch key {
                    case 0x04: // ^D
                        return
                    case 0x72: // r (RESET)
                        z80.reset()
                    case 0x76: // v (VECT INTR)
                        ioports.INT = true
                        ioports.data = 0xFF // RST 7
                    default:
                        mmports.i8279.RL07 = kmap[key]
                        ioports.INT = true
                        ioports.data = 0xEF // RST 5
                }
            }
        }
    }
}

// band-aid single char stdin input on Winos
struct Stdwin {
    static var shared: Stdwin = {
        let this = Stdwin()
        FileManager.default.createFile(atPath: recordFilePath, contents: nil)
        return this
    }()

    private init(forRecordingAtPath recordFilePath: String = ".stdwin") {
        Stdwin.recordFilePath = recordFilePath
    }

    private(set) static var recordFilePath = ".stdwin"

    private var recordFileOffset: UInt64 = 0

    func recordUntilEof() {
        while true {
            guard
                let line = readLine()
            else {
                return
            }
            if let fh = FileHandle(forWritingAtPath: Stdwin.recordFilePath) {
                fh.seekToEndOfFile()
                fh.write(line.data(using: .utf8)!)
                try? fh.close()
            }
        }
    }

    mutating func getKeyPressed() -> UInt8? {
        var key: UInt8? = nil
        guard
            let fh = FileHandle(forReadingAtPath: Stdwin.recordFilePath)
        else {
            return nil
        }
        if hasKeyPressed() {
            try? fh.seek(toOffset: recordFileOffset)
            let data = try? fh.read(upToCount: 1)
            try? fh.close()

            recordFileOffset += 1
            key = data![0]
        }

        return key
    }

    func hasKeyPressed() -> Bool {
        guard
            let fa = try? FileManager.default.attributesOfItem(atPath: Stdwin.recordFilePath)
        else {
            return false
        }
        let recordFileSize = fa[.size] as! UInt64

        return recordFileSize>recordFileOffset
    }
}

#endif

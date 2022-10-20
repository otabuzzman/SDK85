import Foundation
import z80

enum TimerState {
    case reset
    case started
    case elapsed // transient
    case stopped
    case pending
    case abort
}

typealias TraceIO = (_ rdPort: Bool, _ addr: UShort, _ data: Byte) -> ()

final class IOPorts: IPorts {
    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00

    private var timerState = TimerState.reset
    private var timerCount: UShort = 0
    private var timerValue: UShort = 0

    private var bots: UInt = 0
    private var _SOD: Byte = 0
    var SOD: Byte = 0

    private var bits: UInt = 0
    var SID: Byte = 0x80

    private var traceIO: TraceIO?

    init(traceIO: TraceIO? = nil) {
        self.traceIO = traceIO
    }

    func TIMER_IN(pulses: UShort) -> TimerState {
        var returnState = timerState
        if timerState == .started || timerState == .pending {
            for _ in 1...pulses {
                timerCount -= 1
                if timerCount == 0 {
                    switch timerState {
                        case .started:
                            timerCount = timerValue
                        case .pending:
                            timerState = .stopped
                        default:
                            break
                    }
                    returnState = .elapsed
                }
            }
        }
        return returnState
    }

    func rdPort(_ port: UShort) -> Byte
    {
        var data: Byte = 0
        switch port & 0xFF {
            case 0xFF:
                if SID & 0x80 == 0 {
                    if 8 > bits {
                        data = Byte(((UShort(SID) * 256) >> bits) & 0x80)
                        bits += 1
                    } else {
                        SID |= 0x80
                        bits = 0
                    }
                } else {
                    data = 0x80
                }
            default:
                break
        }

        traceIO?(true, port, data)
        return data
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        switch port & 0xFF {
            case 0x20:
                // timer command
                switch data & 0xC0 {
                    case 0x00:
                        break
                    case 0x40:
                        timerState = .abort
                    case 0x80:
                        timerState = .pending
                    case 0xC0:
                        timerCount = timerValue
                        timerState = .started
                    default:
                        break
                }
            case 0x24:
                timerValue = (timerValue & 0xFF00) + (data)
            case 0x25:
                timerValue = (timerValue & 0x00FF) + (UShort(data & 0x3F) << 8)
            case 0xFF:
                // SOE (serial output enabled)
                if data & 0x40 == 0 {
                    break
                }
                if 8 > bots {
                    _SOD = (_SOD | (~data & 0x80)) >> 1
                    bots += 1
                } else {
                    SOD = _SOD
                    bots = 0
                    print("SOD: ", SOD > 0x20 ? Character(UnicodeScalar(SOD)) : SOD.bitsToString)
                }
            default:
                break
        }

        traceIO?(false, port, data)
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

final class I8279: MPorts {
    var FIFO: Byte?

    // map glyph codes of SDK-85 to ASCII
    static let glyphMap: Dictionary<Byte, String> = [
        0xF3: "0",
        0xFB: "0.",
        0x60: "1", // and "I"
        0x68: "1.",
        0xB5: "2",
        0xBD: "2.",
        0xF4: "3",
        0xFC: "3.",
        0x66: "4",
        0x6E: "4.",
        0xD6: "5",
        0xDE: "5.",
        0xD7: "6",
        0xDF: "6.",
        0x70: "7",
        0x78: "7.",
        0xF7: "8",
        0xFF: "8.",
        0x76: "9",
        0x7E: "9.",
        0x77: "A",
        0x7F: "A.",
        0xC7: "b",
        0xCF: "b.",
        0x93: "C",
        0x9B: "C.",
        0xE5: "d",
        0xED: "d.",
        0x97: "E",
        0x9F: "E.",
        0x17: "F",
        0x1F: "F.",
        0x67: "H",
        0x6F: "H.",
        0x83: "L",
        0x8B: "L.",
        0x37: "P",
        0x3F: "P.",
        0x05: "r",
        0x0D: "r.",
        0x00: " ",
        0x04: "-",
        0x08: ".",
    ]

    private var traceIO: TraceIO?

    init(_ mmap: ClosedRange<UShort>, traceIO: TraceIO? = nil) {
        self.mmap = mmap
        self.traceIO = traceIO
    }

    func rdPort(_ port: UShort) -> Byte
    {
        var data: Byte = 0
        switch port {
            case 0x1800:
                data = FIFO ?? 0
            case 0x1900:
                break
            default:
                break
        }

        traceIO?(true, port, data)
        return data
    }

    func wrPort(_ port: UShort, _ data: Byte)
    {
        switch port {
            case 0x1800:
                break
            case 0x1900:
                break
            default:
                break
        }

        traceIO?(false, port, data)
    }

    var mmap: ClosedRange<UShort>
}

// https://developer.apple.com/forums/thread/715288
struct Sdk85 {
}

@main
extension Sdk85 {
    static func main() {
        // map PC keyboard codes to those of SDK-85
        let keyboardMap: Dictionary<Byte, Byte> = [
            0x30: 0x00, // 0
            0x31: 0x01, // 1
            0x32: 0x02, // 2
            0x33: 0x03, // 3
            0x34: 0x04, // 4
            0x35: 0x05, // 5
            0x36: 0x06, // 6
            0x37: 0x07, // 7
            0x38: 0x08, // 8
            0x39: 0x09, // 9
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

        var ram = Array<Byte>(repeating: 0, count: 0x10000)
        let rom = NSData(contentsOfFile: "Intel/sdk85-0000.bin")
        ram.replaceSubrange(0..<rom!.count, with: rom!)

        let ioports = IOPorts() { rdPort, port, data in
            if 0xFF > port {
                print(String(format: "  IOPorts : %@ 0x%04X : 0x%02X", rdPort ? "IN" : "OUT", port, data))
            }
        }
        let i8279 = I8279(0x1800...0x19FF) { rdPort, port, data in
            if rdPort {
                print(String(format: "  I8279 : IN 0x%04X : 0x%02X", port, data))
            } else {
                let glyph = port == 0x1800 ? I8279.glyphMap[~data, default: "\\0"] : " "
                print(String(format: "  I8279 : OUT 0x%04X : 0x%02X (%@) \"%@\"", port, data, data.bitsToString, glyph))
            }
        }
        let mem = Memory(ram, 0x1000, [i8279])
        var z80 = Z80(mem, ioports,
        traceNmiInt: { interrupt, addr, instruction in
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
        })

        _ = Task { Stdwin.shared.recordUntilEof() }
        defer {
            try? FileManager.default.removeItem(atPath: Stdwin.recordFilePath)
        }

        while (!z80.Halt)
        {
            let tStates = z80.parse()
            if ioports.TIMER_IN(pulses: UShort(tStates)) == .elapsed {
                print(z80.dumpStateCompact())
                ioports.NMI = true
            }
            if let key = Stdwin.shared.getKeyPressed() {
                switch key {
                    case 0x72: // r (RESET)
                        z80.reset()
                    case 0x76: // v (VECT INTR)
                        ioports.INT = true
                        ioports.data = 0xFF // RST 7
                    default:
                        ioports.SID = key == 0x2E ? 0x0D : key
//                        i8279.FIFO = keyboardMap[key]
//                        ioports.INT = true
//                        ioports.data = 0xEF // RST 5
                }
            }
        }
    }
}

// band-aid single char stdin input on Winos
struct Stdwin {
    static var shared: Stdwin = {
        FileManager.default.createFile(atPath: recordFilePath, contents: nil)
        return Stdwin()
    }()

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

extension Byte {
    // return byte as 8-bit string
    var bitsToString: String {
        let b = String(self, radix: 2)
        let a = Array<Character>(repeating: "0", count: 8 - b.count)
        return String(a + b)
    }

    var reverseBits: Byte {
        var a = (self & 0xF0) >> 4 | (self & 0x0F) << 4
        a = (a & 0xCC) >> 2 | (a & 0x33) << 2
        a = (a & 0xAA) >> 1 | (a & 0x55) << 1
        return a
    }
}

import SwiftUI
import z80

struct Timer {
    enum State {
        case started
        case pending
        case stopped
        case abort
    }

    var state: State { didSet { if state == .started { count = value } } }
    var value: UShort
    var count: UShort

    mutating func state(_ state: State) { self.state = state }
    mutating func value(LOB: Byte) { value = (value & 0xFF00) + LOB }
    mutating func value(HOB: Byte) { value = (value & 0x00FF) + (UShort(HOB & 0x3F) << 8) }
    mutating func count(minus: UShort) -> Bool {
        var elapsed = false
        if state == .started || state == .pending {
            for _ in 1...minus {
                count -= 1
                if count == 0 {
                    switch state {
                    case .started:
                        count = value
                    case .pending:
                        state = .stopped
                    default:
                        break
                    }
                    elapsed = true
                    break
                }
            }
        }
        return elapsed
    }
}

typealias TraceIO = (_ rdPort: Bool, _ addr: UShort, _ data: Byte) -> ()

final class IntIO: ObservableObject, IPorts {
    private var state = NSLock()
    
    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00

    private var _RESET = false

    private(set) var timer = Timer(state: .abort, value: 0, count: 0)

    private var ttyOn = false // TTY connected
    
    private var bots: UInt = 0
    private var sod: Byte = 0
    @Published var SOD = ""

    private var bits: UInt = 0
    private var sid: Byte = 0
    var SID: Byte {
        get {
            state.lock()
            defer { state.unlock() }
            return sid
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            sid = value
        }
    }

    @Published var MHz: Double = 0

    private var traceIO: TraceIO?
    private var circuit: CircuitVM!
    
    init(traceIO: TraceIO? = UserDefaults.traceIO) {
        self.traceIO = traceIO
    }

    init(traceIO: TraceIO? = UserDefaults.traceIO, _ circuit: CircuitVM) {
        self.circuit = circuit
        self.traceIO = traceIO
    }
    
    func reset() {
        _NMI = false
        _INT = false
        _data = 0x00

        timer = Timer(state: .abort, value: 0, count: 0)

        bots = 0
        sod = 0
        SOD = ""

        bits = 0
        ttyOn = false
        sid = 0
    }

    func TIMER_IN(pulses: UShort) -> Bool {
        timer.count(minus: pulses)
    }

    func rdPort(_ port: UShort) -> Byte {
        var data: Byte = 0
        switch port & 0xFF {
        case 0xFF:
            if SID == 0x00 && ttyOn {
                ttyOn.toggle()
            }
            if SID == 0x80 && !ttyOn {
                ttyOn.toggle()
            }
            if !ttyOn {
                break
            }
            data = SID & 0x80
            if data == 0 {
                if 8 > bits {
                    data = Byte(((UShort(SID) * 256) >> bits) & 0x80)
                    bits += 1
                } else {
                    SID |= 0x80
                    bits = 0
                }
            }
        default:
            break
        }

        traceIO?(true, port, data)
        return data
    }

    func wrPort(_ port: UShort, _ data: Byte) {
        switch port & 0xFF {
        case 0x20:
            // timer command
            switch data & 0xC0 {
            case 0x00:
                break
            case 0x40:
                timer.state(.abort)
            case 0x80:
                timer.state(.pending)
            case 0xC0:
                timer.state(.started)
            default:
                break
            }
        case 0x24:
            timer.value(LOB: data)
        case 0x25:
            timer.value(HOB: data)
        case 0xFF:
            // SOE (serial output enabled)
            if data & 0x40 == 0 {
                break
            }
            if 8 > bots {
                sod = (sod | (~data & 0x80)) >> 1
                bots += 1
            } else {
                Task { @MainActor in SOD.append(Character(UnicodeScalar(sod))) }
                bots = 0
            }
        default:
            break
        }

        traceIO?(false, port, data)
    }

    var NMI: Bool {
        get {
            state.lock()
            defer { state.unlock() }
            let tmp = _NMI
            _NMI = false
            return tmp
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _NMI = value
        }
    }
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

    var RESET: Bool {
        get {
            state.lock()
            defer { state.unlock() }
            let tmp = _RESET
            _RESET = false
            return tmp
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _RESET = value
        }
    }
}

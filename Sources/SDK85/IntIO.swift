import SwiftUI
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

final class IntIO: ObservableObject, IPorts
{
    private var state = NSLock()

    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00

    private var timerState = TimerState.reset
    private var timerCount: UShort = 0
    private var timerValue: UShort = 0

    private var bots: UInt = 0
    private var sod: Byte = 0
    @Published var SOD = ""

    private var bits: UInt = 0
    var tty = false
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

    private var traceIO: TraceIO?

    init(traceIO: TraceIO? = Default.traceIO) {
        self.traceIO = traceIO
    }

    func reset() {
        _NMI = false
        _INT = false
        _data = 0x00

        timerState = TimerState.reset
        timerCount = 0
        timerValue = 0

        bots = 0
        sod = 0
        SOD = ""

        bits = 0
        tty = false
        sid = 0
    }

    func TIMER_IN(pulses: UShort) -> TimerState {
        var state = timerState
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
                    state = .elapsed
                }
            }
        }
        return state
    }

    func rdPort(_ port: UShort) -> Byte
    {
        var data: Byte = 0
        switch port & 0xFF {
        case 0xFF:
            if !tty {
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
            timerValue = (timerValue & 0xFF00) + data
        case 0x25:
            timerValue = (timerValue & 0x00FF) + (UShort(data & 0x3F) << 8)
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
            let ret = _NMI
            _NMI = false
            return ret
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
            let ret = _INT
            _INT = false
            return ret
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
            let ret = _data
            _data = 0x00
            return ret
        }
        set(value) {
            state.lock()
            defer { state.unlock() }
            _data = value
        }
    }
}

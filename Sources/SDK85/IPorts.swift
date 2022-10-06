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

final class IOPorts: IPorts
{
    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00
    
    private var timerState = TimerState.reset
    private var timerCount: UShort = 0
    private var timerValue: UShort = 0
    
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
        traceIO?(true, port, 0)
        return 0
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

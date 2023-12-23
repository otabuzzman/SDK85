import SwiftUI
import z80

final class I8279: MPorts {
    private var CNTRL: Byte = 0x08

    private var fieldCount = 1

    var RL07 = Fifo()

    var mmap: ClosedRange<UShort>
    private var traceIO: TraceIO?
    private var circuit: CircuitVM!
    
    init(_ mmap: ClosedRange<UShort>, traceIO: TraceIO? = UserDefaults.traceIO) {
        self.mmap = mmap
        self.traceIO = traceIO
    }

    init(_ mmap: ClosedRange<UShort>, traceIO: TraceIO? = UserDefaults.traceIO, _ circuit: CircuitVM) {
        self.mmap = mmap
        self.traceIO = traceIO
        self.circuit = circuit
    }
    
    func reset() {
        CNTRL = 0x08

        fieldCount = 1

        RL07.removeAll()
    }

    func rdPort(_ port: UShort) -> Byte {
        var data: Byte = 0x00
        switch port {
        case 0x1800:
            data = RL07.dequeue() ?? 0x00
        case 0x1900:
            break
        default:
            break
        }

        traceIO?(true, port, data)
        return data
    }

    func wrPort(_ port: UShort, _ data: Byte) {
        switch port {
        case 0x1800:
            if CNTRL == 0x90 {
                switch fieldCount {
                case 1:
                    Task { @MainActor in circuit.AF1 = data }
                case 2:
                    Task { @MainActor in circuit.AF2 = data }
                case 3:
                    Task { @MainActor in circuit.AF3 = data }
                case 4:
                    Task { @MainActor in circuit.AF4 = data }
                default:
                    break
                }
                fieldCount += 1
            }
            if CNTRL == 0x94 {
                switch fieldCount {
                case 1:
                    Task { @MainActor in circuit.DF1 = data }
                case 2:
                    Task { @MainActor in circuit.DF2 = data }
                default:
                    break
                }
                fieldCount += 1
            }
        case 0x1900:
            CNTRL = data
            fieldCount = 1
        default:
            break
        }

        traceIO?(false, port, data)
    }
}

class Fifo: Queue<Byte> {
    private var state = NSLock()

    override func enqueue(_ element: Byte) {
        state.lock()
        defer { state.unlock() }
        super.enqueue(element)
    }

    override func dequeue() -> Byte? {
        state.lock()
        defer { state.unlock() }
        return super.dequeue()
    }
}

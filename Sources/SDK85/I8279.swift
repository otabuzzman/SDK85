import SwiftUI
import z80

final class I8279: ObservableObject, MPorts {
    var CNTRL: Byte = 0x08
    
    // address fields 1...4
    @Published var AF1: Byte = ~0x67 // H
    @Published var AF2: Byte = ~0x77 // a
    @Published var AF3: Byte = ~0x83 // L
    @Published var AF4: Byte = ~0x8F // t.
    // data fields 1...2
    @Published var DF1: Byte = ~0x00
    @Published var DF2: Byte = ~0x00
    private var fieldCount = 1
    
    var FIFO = Fifo()
    var RL07 = Fifo()
    
    init(_ mmap: ClosedRange<UShort>) {
        self.mmap = mmap
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
        
        // print(String(format: "  \(self) : IN 0x%04X : 0x%02X", port, data))
        return data
    }
    
    func wrPort(_ port: UShort, _ data: Byte) {
        switch port {
        case 0x1800:
            if CNTRL == 0x90 {
                switch fieldCount {
                case 1:
                    Task { @MainActor in AF1 = data }
                case 2:
                    Task { @MainActor in AF2 = data }
                case 3:
                    Task { @MainActor in AF3 = data }
                case 4:
                    Task { @MainActor in AF4 = data }
                default:
                    break
                }
                fieldCount += 1
            }
            if CNTRL == 0x94 {
                switch fieldCount {
                case 1:
                    Task { @MainActor in DF1 = data }
                case 2:
                    Task { @MainActor in DF2 = data }
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
        
        // print(String(format: "  \(self) : OUT 0x%04X : 0x%02X (%@)", port, data, data.bits))
    }
    
    var mmap: ClosedRange<UShort>
}

extension Byte {
    var bits: String {
        let b = String(self, radix: 2)
        let a = Array<Character>(repeating: "0", count: 8 - b.count)
        return String(a + b)
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

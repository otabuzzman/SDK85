import SwiftUI
import z80

final class IOPorts: IPorts
{
    private var _NMI = false
    private var _INT = false
    private var _data: Byte = 0x00
    
    func rdPort(_ port: UShort) -> Byte
    {
        print(String(format: "  \(self) : IN 0x%04X", port))
        return 0
    }
    
    func wrPort(_ port: UShort, _ data: Byte)
    {
        print(String(format: "  \(self) : OUT 0x%04X : 0x%02X", port, data))
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

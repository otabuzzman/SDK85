import z80

class C80: Z80 { // custom Z80
    private var intIO: IntIO!
    
    init(_ mem: Memory, _ intIO: IntIO, traceMemory: TraceMemory? = nil, traceOpcode: TraceOpcode? = nil, traceNmiInt: TraceNmiInt? = nil) {
        self.intIO = intIO
        super.init(mem, intIO,
                   traceMemory: traceMemory,
                   traceOpcode: traceOpcode,
                   traceNmiInt: traceNmiInt)
    }
    
    @discardableResult
    override func parse() -> Int {
        let tStates = super.parse()
        if intIO.RESET {
            reset()
        }
        if intIO.TIMER_IN(pulses: UShort(tStates)) {
            intIO.NMI = true
            if _isDebugAssertConfiguration() { print(super.dumpStateCompact()) }
        }
        return tStates
    }
}

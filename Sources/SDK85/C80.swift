import z80

class C80: Z80 { // custom Z80
    private var intIO: IntIO!
    
    init(_ mem: Memory, _ intIO: IntIO, traceMemory: TraceMemory? = nil, traceOpcode: TraceOpcode? = nil, traceNmiInt: TraceNmiInt? = nil)
    {
        self.intIO = intIO
        super.init(mem, intIO, traceMemory: traceMemory, traceOpcode: traceOpcode, traceNmiInt: traceNmiInt)
    }
    
    override func parse() -> Int {
        var tStates = 0
        if intIO.RESET {
            reset()
        } else {
            tStates = super.parse()
        }
        return tStates
    }
}

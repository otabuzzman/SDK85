import SwiftUI
import z80

struct ContentView: View {
    @StateObject var i8279 = I8279(0x1800...0x19FF)
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("sdk-85-pcb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    maxWidth: UIScreen.main.bounds.width,
                    alignment: .bottomTrailing)
                .overlay(Credit(), alignment: .topLeading)
            
            VStack {
                Display(i8279: i8279)
                Keyboard(i8279: i8279)
            }
            .padding(8)
            .background(.pcbLabel.opacity(0.8))
            .cornerRadius(16)
        }.task {
            Task.detached(priority: .background) {
                let url = Bundle.main.url(forResource: "sdk85-0000", withExtension: "bin")
                let rom = NSData(contentsOf: url!)
                var ram = Array<Byte>(repeating: 0, count: 0x10000)
                ram.replaceSubrange(0..<rom!.count, with: rom!)
                
                let ioPorts = IOPorts()
                let mem = await Memory(ram, 0x1000, [i8279])
                var z80 = Z80(mem, ioPorts)
                
                while (!z80.Halt) {
                    z80.parse()
                    if let key = await i8279.FIFO.dequeue() {
                        switch key {
                        case 0xFF:
                            z80.reset()
                        case 0xFE:
                            ioPorts.INT = true
                            ioPorts.data = 0xFF // RST 7
                        default:
                            await i8279.RL07.enqueue(key)
                            ioPorts.INT = true
                            ioPorts.data = 0xEF // RST 5
                        }
                    }
                }
            }
        }
    }
}

@main 
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct Credit: View {
    var body: some View {
        ZStack {
            Text("Credit: [SDK-85 printed cicuit board](http://retro.hansotten.nl/wp-content/uploads/2021/03/20210318_112214-scaled.jpg) photo by [Hans Otten](http://retro.hansotten.nl/contact/) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)")
                .foregroundColor(.pcbText)
                .accentColor(.pcbLink)
                .padding(4)
        }
        .background(.pcbLabel)
        .cornerRadius(12)
        .padding(4)
    }
}

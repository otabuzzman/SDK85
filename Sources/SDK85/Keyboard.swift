import SwiftUI
import z80

struct Keyboard: View {
    @EnvironmentObject var circuitIO: CircuitIO
    
    var ttyColor: Color

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State private var input = ""
    @FocusState private var focus: Bool

    var body: some View {
        let isCompact = horizontalSizeClass == .compact || verticalSizeClass == .compact

        if !focus {
            Button() {
                focus = true
            } label: {
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isCompact ? 56 : 96)
                    .foregroundColor(ttyColor)
                    .brightness(-0.2)
            }
        }

        TextField("", text: Binding<String>( // https://stackoverflow.com/a/60969666
            get: { self.input },
            set: { value in self.input = value.uppercased() }))
        .focused($focus)
        .onChange(of: input, perform: { value in
            if value.isEmpty { return }
            i8155.SID = input.last!.asciiValue!
        })
        .onSubmit {
            i8155.SID = 0x0D
            input = ""
            focus = true
        }
        .accentColor(.clear)
        .autocorrectionDisabled(true)
        // https://stackoverflow.com/questions/60967877
        .textInputAutocapitalization(.characters) // not working
    }
}

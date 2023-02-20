import SwiftUI
import z80

struct Keyboard: View {
    @ObservedObject var intIO: IntIO
    var crtColor: Color

    @State private var input = ""
    @FocusState private var focus: Bool

    var body: some View {
        if !focus {
            Button() {
                focus = true
            } label: {
                Image(systemName: "keyboard")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(crtColor)
                    .brightness(-0.2)
                    .frame(width: 96)
            }
        }
        TextField("", text: Binding<String>( // https://stackoverflow.com/a/60969666
            get: { self.input },
            set: { value in self.input = value.uppercased() }))
        .focused($focus)
        .onChange(of: input, perform: { value in
            if value.isEmpty { return }
            intIO.SID = input.last!.asciiValue!
        })
        .onSubmit {
            intIO.SID = 0x0D
            input = ""
            focus = true
        }
        .accentColor(.clear)
        .autocorrectionDisabled(true)
        // https://stackoverflow.com/questions/60967877
        .textInputAutocapitalization(.characters) // not working
    }
}

import SwiftUI

struct Tty: View {
    var body: some View {
        VStack {
            Monitor()
                .padding(16)
            Keyboard()
        }
        .padding(.bottom, 16)
        .background(Color.black) // https://stackoverflow.com/a/71935851
    }
}

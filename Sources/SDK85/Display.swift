import SwiftUI

struct Display: View {
    @ObservedObject var i8279: I8279
    
    var body: some View {
        VStack {
            HStack {
                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(dcbapgfe: i8279.AF1)
                        SevenSegmentDisplay(dcbapgfe: i8279.AF2)
                        SevenSegmentDisplay(dcbapgfe: i8279.AF3)
                        SevenSegmentDisplay(dcbapgfe: i8279.AF4)
                    }
                    .padding(8)
                    .background(.package)
                }
                .padding(.trailing, 16)
                
                HStack(spacing: 4) {
                    Group {
                        SevenSegmentDisplay(dcbapgfe: i8279.DF1)
                        SevenSegmentDisplay(dcbapgfe: i8279.DF2)
                    }
                    .padding(8)
                    .background(.package)
                }
                .padding(.leading, 16)
            }
            .font(.system(size: 64))
            .padding(32)
            .background(.display)
            .cornerRadius(4)
        }
    }
}

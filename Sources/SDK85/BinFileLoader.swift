import SwiftUI
import UniformTypeIdentifiers

struct BinFileLoader: UIViewControllerRepresentable {
    @Binding var binData: Data
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<BinFileLoader>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.bin])
        controller.delegate = context.coordinator
        controller.allowsMultipleSelection = false
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<BinFileLoader>) {
    }
    
    func makeCoordinator() -> BinFileLoaderCoordinator {
        BinFileLoaderCoordinator($binData)
    }
}

class BinFileLoaderCoordinator: NSObject, UINavigationControllerDelegate {
    @Binding var binData: Data
    
    init(_ binFileData: Binding<Data>) {
        _binData = binFileData
    }
}

extension BinFileLoaderCoordinator: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let binFile = urls[0]
     
        guard
            binFile.startAccessingSecurityScopedResource()
        else { return }
        defer { binFile.stopAccessingSecurityScopedResource() }
        
        guard
            let binFileData = try? Data(contentsOf: binFile)
        else { return }
        
        self.binData = binFileData
    }
}

extension UTType {
    static var bin: UTType {
        UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)!
    }
}

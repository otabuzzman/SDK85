import SwiftUI
import UniformTypeIdentifiers

enum BinFileLoaderError: Error {
    case canceled
}

struct BinFileLoader: UIViewControllerRepresentable {
    @Binding var binData: Data
    var completion: ((Result<Data, BinFileLoaderError>) -> Void)?

    func makeUIViewController(context: UIViewControllerRepresentableContext<BinFileLoader>) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.bin])
        controller.delegate = context.coordinator
        controller.allowsMultipleSelection = false

        return controller
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<BinFileLoader>) {
    }

    func makeCoordinator() -> BinFileLoaderCoordinator {
        BinFileLoaderCoordinator($binData, completion)
    }
}

class BinFileLoaderCoordinator: NSObject, UINavigationControllerDelegate {
    @Binding var binData: Data
    var completion: ((Result<Data, BinFileLoaderError>) -> Void)?

    init(_ binData: Binding<Data>, _ completion: ((Result<Data, BinFileLoaderError>) -> Void)?) {
        _binData = binData
        self.completion = completion
    }
}

extension BinFileLoaderCoordinator: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(.failure(.canceled))
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let binFile = urls[0]

        guard
            binFile.startAccessingSecurityScopedResource()
        else { return }
        defer { binFile.stopAccessingSecurityScopedResource() }

        guard
            let binData = try? Data(contentsOf: binFile)
        else { return }

        self.binData = binData
        completion?(.success(binData))
    }
}

extension UTType {
    static var bin: UTType {
        UTType(tag: "bin", tagClass: .filenameExtension, conformingTo: nil)!
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The DirectoryEncryptionDecryption content view.
*/

import UniformTypeIdentifiers
import SwiftUI
import CryptoKit

// The app represents its user interface state with the `Mode` enumeration.
enum Mode: Equatable {
    case idle
    case encrypting
    case awaitingInput(url: URL)
    case decrypting
    
    var awaitingInput: Bool {
        switch self {
        case .awaitingInput(_):
            return true
        default:
            return false
        }
    }
    
    var isProcessing: Bool {
        switch self {
        case .decrypting, .encrypting:
            return true
        default:
            return false
        }
    }
}

struct DirectoryDropDelegate: DropDelegate {
    
    // The `consoleMessages` array contains the messages displayed to the
    // user in the app's console.
    var consoleMessages: Binding<[ConsoleMessage]>
    
    // The `mode` variable represents the app's current state.
    var mode: Binding<Mode>
    
    // The app calls `DirectoryDropDelegate.performDrop(info:)` when the user
    // drops an item on the drop target. The function iterates over each dropped
    // item and either encrypts or decrypts the item as appropriate.
    func performDrop(info: DropInfo) -> Bool {
        func addConsoleMessage(_ message: ConsoleMessage) {
            consoleMessages.wrappedValue.append(message)
        }
        
        for itemProvider in info.itemProviders(for: [ UTType.fileURL]) {
        
            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier,
                                  options: nil) { (rawData, error) in
                
                guard let data = rawData as? Data,
                      let url = URL(dataRepresentation: data,
                                    relativeTo: nil) else {
                          return
                      }
                
                if url.hasDirectoryPath {
                    // If the item is a directory, the app passes the URL to
                    // the `static ArchiverEncryptor.encrypt(sourceURL:)`
                    // function.
                    mode.wrappedValue = .encrypting
                    
                    addConsoleMessage(ConsoleMessage(
                        status: .info,
                        message: "Archiving and encrypting directory '\(url.lastPathComponent)'"))
                    
                    let message = ArchiverEncryptor.encrypt(sourceURL: url)
                    
                    addConsoleMessage(message)
                    mode.wrappedValue = .idle
                } else if url.pathExtension.lowercased() == "aea" {
                    // If the item is an archived directory, the app sets the
                    // mode to `awaitingInput(url:)` and the UI displays an
                    // input allowing the user to enter a Base64 encoded
                    // represenation of the key.
                    //
                    // The decryption is done in the
                    // `ContentView.submitBase64EncodedKeyData()` function.
                    mode.wrappedValue = .awaitingInput(url: url)
                } else {
                    addConsoleMessage(ConsoleMessage(
                        status: .error,
                        message: "'\(url.lastPathComponent)' isn't a directory or archive file."))
                }
            }
        }
        
        return true
    }
}

struct ContentView: View {
    
    @State private var base64EncodedKeyData: String = ""
    @State private var mode = Mode.idle
    @State private var consoleMessages: [ConsoleMessage] = [
        ConsoleMessage(status: .info,
                       message: "Apple Archive Demo App")]
    
    // The `ContentView.submitBase64EncodedKeyData()` function generates a
    // `SymmetricKey` from the Base64 encoded key data and passes the URL to
    // the `static ArchiverEncryptor.decrypt(sourceURL:encryptionKey:)` function.
    func submitBase64EncodedKeyData() {
        defer {
            $mode.wrappedValue = .idle
        }
        
        let decryptingURL: URL
        switch mode {
        case .awaitingInput(let url):
            decryptingURL = url
        default:
            return
        }
        
        $mode.wrappedValue = .decrypting
        
        guard let encryptionKey = SymmetricKey(fromBase64EncodedString: base64EncodedKeyData) else {
            consoleMessages.append(ConsoleMessage(status: .error,
                                                  message: "Unable to create key from string"))
            return
        }
        
        let message = ArchiverEncryptor.decrypt(sourceURL: decryptingURL,
                                                encryptionKey: encryptionKey)
        consoleMessages.append(message)
    }
    
    func copyToPasteboard(_ item: String) {
        NSPasteboard.general.declareTypes([.string],
                                          owner: nil)
        let success = NSPasteboard.general.setString(item,
                                                     forType: .string)
        
        let message: ConsoleMessage
        if success {
            message = ConsoleMessage(status: .info,
                                     message: "Saved key to pasteboard")
        } else {
            message = ConsoleMessage(status: .error,
                                     message: "Failed to save key to pasteboard")
        }
        consoleMessages.append(message)
    }
    
    var body: some View {
        let columns: [GridItem] = [GridItem(.fixed(50)),
                                   GridItem(.flexible()),
                                   GridItem(.fixed(50))]
        
        GeometryReader { geometry in
            VStack() {
                Rectangle()
                    .fill(Color.gray)
                    .onDrop(of: [UTType.fileURL],
                            delegate: DirectoryDropDelegate(consoleMessages: $consoleMessages,
                                                            mode: $mode))
                    .overlay(Text("Drop directory or Apple Archive file")
                                .opacity(mode.awaitingInput ? 0 : 1))
                    .overlay(
                        SecureField("Enter key", text: $base64EncodedKeyData) {
                            submitBase64EncodedKeyData()
                        }
                            .opacity(mode.awaitingInput ? 1 : 0)
                            .padding()
                            .onChange(of: mode) { value in
                                if mode.awaitingInput {
                                    base64EncodedKeyData = ""
                                }
                            }
                            .onExitCommand {
                                $mode.wrappedValue = .idle
                            }
                    )
                    .frame(height: geometry.size.height * 0.5, alignment: .top)
             
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(consoleMessages) { message in
                                Image(systemName: message.status.imageSystemName)
                                    .renderingMode(.original)
                                
                                Text(message.message)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button() {
                                    copyToPasteboard(message.base64EncodedKeyData ?? "")
                                } label: {
                                    Image(systemName: "doc.on.doc.fill")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .opacity(message.base64EncodedKeyData != nil ? 1 : 0)
                            }
                        }
                    }
                    .onChange(of: consoleMessages) { _ in
                        proxy.scrollTo(consoleMessages.last!.id)
                    }
                }
                .padding(.bottom)
                .frame(height: geometry.size.height * 0.5, alignment: .top)
                .blur(radius: mode.awaitingInput ? 2 : 0)
                
            }
            .opacity(mode.isProcessing ? 0.75 : 1)
            .overlay(
                ProgressView()
                    .opacity(mode.isProcessing ? 1 : 0)
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

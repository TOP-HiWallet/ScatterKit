Scatter Kit 
==============
ScatterKit simulates Scatter plugin for EOS blockchain in WKWebView, and allows client apps to:
- Retrieve account
- Sign transactions
- Sign arbitrary messages
 
## Installation
### Step 1: Add framework 
##### CocoaPods
1. Add `pod 'ScatterKit'` to Podfile
2. Run `pod install`

### Step 2: Configure ScatterKit in WKWebView
Setup ScatterKit for WKWebView in UIViewController
```swift
import ScatterKit

class YourViewController: BaseViewController {

    private var scatterKit: ScatterKit!

    override func viewDidLoad() {
        super.viewDidLoad()
        // create webview with configuration
        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        // webView.navigationDelegate = self
        // ... other setup
        
        // configure ScatterKit after WKWebView configuration 
        scatterKit = ScatterKit(webView: webView)
        scatterKit.delegate = self
    }
}

// Implement supported Scatter callbacks
extension YourViewController: ScatterKitDelegate { 
    // ...
}
```

## Usage examples

### Send EOS account to Scatter
```swift
extension YourViewController: ScatterKitDelegate {
    func scatterDidRequestAccountName(_ completionHandler: @escaping SKCallback<String>) throws {
        completionHandler(.success("myeosaccount"))
    }
}
```

### Sign arbitrary message
```swift
extension YourViewController: ScatterKitDelegate {
    func scatterDidRequestMessageSignature(_ request: ScatterKit.Request.MessageSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.MessageSignature>) throws {
            var data = Data(result.info.signature.data.utf8)
            if !result.info.signature.isHash {
                data = makeSha256(data)
            }
            let signature = makeSignature(privateKey: self.privateKey, digest: data)
            let response = ScatterKit.Response.MessageSignature(message: "Success!", signature: signature)
            completionHandler(.success(response))
    }
}
```
### Sign transaction
```swift
extension YourViewController: ScatterKitDelegate {
    func scatterDidRequestTransactionSignature(_ request: ScatterKit.Request.TransactionSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.TransactionSignature>) throws {
        // try to make transaction
        let transaction = try makeTransaction(from: request, privateKey: self.privateKey)
        let signatureInfo = ScatterKit.Response.TransactionSignature(signatures: transaction.signatures, returnedFields: [:])
        completionHandler(.success(signatureInfo))
    }
}
```
### Send customized errors to Scatter 
```swift
// Create class, that handles Scatter errors
enum ScatterErrors: Error {
    case messageSignatureCancel
    case transactionSignatureCancel
    case signatureFailed
}

// Implement ScatterKitErrorConvertible protocol
extension ScatterErrors: ScatterKitErrorConvertible {
    var scatterErrorMessage: String? {
        switch self {
        case .transactionSignatureCancel,
             .messageSignatureCancel:
            return "Signature cancelled"
        case .signatureFailed:
            return "Signature failed"
        }
    }
    
    var scatterErrorKind: ScatterKitError.Kind? {
        switch self {
        case .transactionSignatureCancel,
             .messageSignatureCancel:
            return .signatureRejected
        case .signatureFailed:
            return .malicious
        }
    }
    
    var scatterErrorCode: ScatterKitError.Code? {
        switch self {
        case .transactionSignatureCancel,
             .messageSignatureCancel:
            return .noSignature
        case .signatureFailed:
            return .forbidden
        }
    }
}

extension YourViewController: ScatterKitDelegate {
    func scatterDidRequestTransactionSignature(_ request: ScatterKit.Request.TransactionSignature, completionHandler: @escaping SKCallback<ScatterKit.Response.TransactionSignature>) throws {
        do {
            // try to make transaction
        } catch {
             completionHandler(.error(ScatterErrors.signatureFailed))
        }
    }
}
```



import UIKit

/// A subclass of UIImageView which displays a JPEG progressively while it is downloaded
public class CCBufferedImageView : UIImageView, NSURLConnectionDataDelegate {
    private weak var connection: NSURLConnection?
    private let defaultContentLength = 5 * 1024 * 1024
    private var data: Data?
    private let queue = DispatchQueue(label: "com.contentful.Concorde")

    /// Optional handler which is called after an image has been successfully downloaded
    public var loadedHandler: (() -> ())?

    deinit {
        connection?.cancel()
    }

    /// Initialize a new image view with the given frame
    public override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.gray
    }

    /// Initialize a new image view and start loading a JPEG from the given URL
    public init(URL: URL) {
        super.init(image: nil)

        backgroundColor = UIColor.gray
        load(URL: URL)
    }

    /// Required initializer, not implemented
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.gray
    }

    /// Load a JPEG from the given URL
    public func load(URL: URL) {
        connection?.cancel()
        connection = NSURLConnection(request: URLRequest(url: URL), delegate: self)
    }

    /// see NSURLConnectionDataDelegate
    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.data?.append(data as Data)
        
        queue.sync() {
            let decoder = CCBufferedImageDecoder(data: self.data)
            decoder?.decompress()
            
            guard let decodedImage = decoder?.toImage() else {
                return
            }
            
            let size = CGSize(width: 1, height: 1)
            let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
            UIGraphicsBeginImageContext(size)
            let context = UIGraphicsGetCurrentContext()
            context?.draw(decodedImage.cgImage!, in: rect)
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async() {
                self.image = decodedImage
            }
        }
    }

    /// see NSURLConnectionDataDelegate
    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        var contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = defaultContentLength
        }
        
        data = Data(capacity: contentLength)
    }

    /// see NSURLConnectionDataDelegate
    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        data = nil
        
        if let loadedHandler = loadedHandler {
            loadedHandler()
        }
    }
}

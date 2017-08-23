//
//  IncrementallyImage.swift
//  ProgressiveJPEG
//
//  Created by Adolph on 2017/8/22.
//  Copyright © 2017年 iceboxi. All rights reserved.
//

import UIKit
import ImageIO

class IncrementallyImage: NSObject, NSURLConnectionDataDelegate {
    private weak var connection: NSURLConnection?
    private var contentLength = 0
    private var data: Data?
    private let queue = DispatchQueue(label: "com.iceboxi.incrementallyimage")
    
    public var image: UIImage?
    public var thumbnail: UIImage?
    public var loadedHandler: (() -> ())?
    
    deinit {
        connection?.cancel()
    }
    
    public init(url: URL) {
        super.init()
        load(url: url)
    }
    
    public func load(url: URL) {
        connection?.cancel()
        connection = NSURLConnection(request: URLRequest(url: url), delegate: self)
    }
    
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.data?.append(data as Data)
        
        queue.sync() {
            let d = [
                kCGImageSourceShouldCache as String : true as NSNumber,
                kCGImageSourceShouldAllowFloat as String : true as NSNumber,
                kCGImageSourceCreateThumbnailWithTransform as String : true as NSNumber,
                kCGImageSourceCreateThumbnailFromImageIfAbsent as String : true as NSNumber,
                kCGImageSourceThumbnailMaxPixelSize as String : 100 as NSNumber
                ] as CFDictionary
            
            let source = CGImageSourceCreateIncremental(nil)
            let isFinish = CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete
            CGImageSourceUpdateData(source, self.data! as CFData, isFinish)
            let imageRef = CGImageSourceCreateImageAtIndex(source, 0, d)
            let thumbnailRef = CGImageSourceCreateThumbnailAtIndex(source, 0, d)
            if let cgImage = imageRef {
                self.image = UIImage(cgImage: cgImage)
            }
            if let cgImage = thumbnailRef {
                self.thumbnail = UIImage(cgImage: cgImage)
            }
            
            DispatchQueue.main.async() {
                if let loadedHandler = self.loadedHandler {
                    loadedHandler()
                }
            }
        }
    }
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = 5 * 1024 * 1024
        }
        
        data = Data(capacity: contentLength)
    }
    
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        data = nil
        
        if let loadedHandler = loadedHandler {
            loadedHandler()
        }
    }
}

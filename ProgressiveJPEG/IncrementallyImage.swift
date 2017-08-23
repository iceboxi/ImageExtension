//
//  IncrementallyImage.swift
//  ProgressiveJPEG
//
//  Created by Adolph on 2017/8/22.
//  Copyright © 2017年 iceboxi. All rights reserved.
//

import UIKit
import ImageIO

class IncrementallyImage: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    private var session: URLSession?
    private var contentLength = 0
    private var data: Data?
    private let queue = DispatchQueue(label: "com.iceboxi.incrementallyimage")
    
    public var image: UIImage?
    public var thumbnail: UIImage?
    public var loadedHandler: (() -> ())?
    
    deinit {
        session?.invalidateAndCancel()
    }
    
    public init(url: URL) {
        super.init()
        load(url: url)
    }
    
    public func load(url: URL) {
        session?.invalidateAndCancel()
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session?.dataTask(with: url).resume()
    }
    
    // MARK: - URLSessionDataDelegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.data?.append(data as Data)
        
        queue.sync() {
            let scale = UIScreen.main.scale
            let d = [
                kCGImageSourceShouldCache as String : true as NSNumber,
                kCGImageSourceShouldAllowFloat as String : true as NSNumber,
                kCGImageSourceCreateThumbnailWithTransform as String : true as NSNumber,
                kCGImageSourceCreateThumbnailFromImageIfAbsent as String : true as NSNumber,
                kCGImageSourceThumbnailMaxPixelSize as String : 50*scale as NSNumber
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
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        contentLength = Int(response.expectedContentLength)
        if contentLength < 0 {
            contentLength = 5 * 1024 * 1024
        }
        
        data = Data(capacity: contentLength)
        
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    // MARK: - URLSessionDelegate
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        data = nil
        if let loadedHandler = loadedHandler {
            loadedHandler()
        }
    }
}


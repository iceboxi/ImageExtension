//
//  ViewController.swift
//  ProgressiveJPEG
//
//  Created by Adolph on 2017/8/21.
//  Copyright © 2017年 iceboxi. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import Concorde
import APNGKit

class ViewController: UIViewController, APNGImageViewDelegate {
//    let imageView = CCBufferedImageView(frame: CGRect(x: 0, y: 100, width: 320, height: 240))
    let imageView = UIImageView(frame: CGRect(x: 0, y: 100, width: 320, height: 240))
    let thumbView = UIImageView(frame: CGRect(x: 120, y: 350, width: 80, height: 60))
    var apngImageView: APNGImageView?
    var incImage: IncrementallyImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.addSubview(imageView)
        self.view.addSubview(thumbView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let path = Bundle.main.path(forResource: "APNG-cube", ofType: "apng")
        if let path = path {
            let image = APNGImage(contentsOfFile: path, saveToCache: true, progressive: true)
            apngImageView = APNGImageView(image: image)
            apngImageView?.frame = CGRect(x: 20, y: 350, width: 80, height: 80)
            apngImageView?.startAnimating()
            image?.repeatCount = 2
            view.addSubview(apngImageView!)
        }
        
        let jeremyGif = UIImage.gifImageWithName("funny")
        let imageView = UIImageView(image: jeremyGif)
        imageView.frame = CGRect(x: 20.0, y: 450.0, width: 150, height: 80.0)
        view.addSubview(imageView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func downloadPJpeg(_ sender: Any) {
//        if let url = URL(string: "http://www.pooyak.com/p/progjpeg/jpegload.cgi?o=1") {
//            self.imageView.load(URL: url)
//        }
        
        if let url = URL(string: "http://www.pooyak.com/p/progjpeg/jpegload.cgi?o=1") {
            incImage = IncrementallyImage(url: url)
            incImage?.loadedHandler = {
                self.imageView.image = self.incImage?.image
                self.thumbView.image = self.incImage?.thumbnail
            }
        }
    }
    
    func saveImageAsPJpeg(image: UIImage) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let targetUrl = documentsUrl.appendingPathComponent("progressive.jpg") as CFURL
        
        let destination = CGImageDestinationCreateWithURL(targetUrl, kUTTypeJPEG, 1, nil)!
        let jfifProperties = [kCGImagePropertyJFIFIsProgressive: kCFBooleanTrue] as NSDictionary
        let properties = [
            kCGImageDestinationLossyCompressionQuality: 0.6,
            kCGImagePropertyJFIFDictionary: jfifProperties
            ] as NSDictionary
        
        CGImageDestinationAddImage(destination, image.cgImage!, properties)
        CGImageDestinationFinalize(destination)
    }
}


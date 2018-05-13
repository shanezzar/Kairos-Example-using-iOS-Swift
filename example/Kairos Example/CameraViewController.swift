//
//  CameraViewController.swift
//  Kairos Example
//
//  Created by Shanezzar Sharon on 13/05/2018.
//  Copyright © 2018 Shanezzar Sharon. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON

class CameraViewController: UIViewController {

    var app_id = ""
    var app_key = ""
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet var dataTextView: UITextView!
    
    var captureSession:AVCaptureSession?
    var videoPreviewayer:AVCaptureVideoPreviewLayer?
    var photoOutput = AVCapturePhotoOutput()
    var inputDevice:AVCaptureDeviceInput?
    var flash: AVCaptureDevice.FlashMode = .off
    var usingFrontCamera = false
    var usingFlash = false
    
    var receivedGalleryName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                self.loadCamera()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func getFrontCamera() -> AVCaptureDevice?{
        return AVCaptureDevice.default(.builtInWideAngleCamera, for:AVMediaType.video, position: AVCaptureDevice.Position.front)!
    }
    
    func getBackCamera() -> AVCaptureDevice{
        return AVCaptureDevice.default(.builtInWideAngleCamera, for:AVMediaType.video, position: AVCaptureDevice.Position.back)!
    }
    
    func loadCamera() {
        var isFirst = false
        
        DispatchQueue.global().async {
            if(self.captureSession == nil){
                isFirst = true
                self.captureSession = AVCaptureSession()
                self.captureSession!.sessionPreset = AVCaptureSession.Preset.high
            }
            var error: NSError?
            var input: AVCaptureDeviceInput!
            
            let currentCaptureDevice = (self.usingFrontCamera ? self.getFrontCamera() : self.getBackCamera())
            
            do {
                input = try AVCaptureDeviceInput(device: currentCaptureDevice!)
            } catch let error1 as NSError {
                error = error1
                input = nil
                print(error!.localizedDescription)
            }
            
            for i : AVCaptureDeviceInput in (self.captureSession?.inputs as! [AVCaptureDeviceInput]) {
                self.captureSession?.removeInput(i)
            }
            
            for i : AVCaptureOutput in (self.captureSession!.outputs) {
                self.captureSession?.removeOutput(i)
            }
            
            if error == nil && self.captureSession!.canAddInput(input) {
                self.captureSession!.addInput(input)
            }
            
            if (self.captureSession?.canAddOutput(self.photoOutput))! {
                self.captureSession?.addOutput(self.photoOutput)
            } else {
                print("Error: Couldn't add meta data output")
                return
            }
            
            DispatchQueue.main.async {
                if isFirst {
                    self.videoPreviewayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
                    self.videoPreviewayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    self.videoPreviewayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                    self.videoPreviewayer?.frame = self.cameraPreview.layer.bounds
                    self.cameraPreview.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                    self.cameraPreview.layer.addSublayer(self.videoPreviewayer!)
                    self.captureSession!.startRunning()
                }
            }
        }
        
    }
    
    @objc func capture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flash
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @IBAction func captureAction(_ sender: Any) {
        capture()
    }
    
    @IBAction func rotateAction(_ sender: Any) {
        self.usingFrontCamera = !self.usingFrontCamera
        self.loadCamera()
    }
    
    @IBAction func flashAction(_ sender: Any) {
        self.usingFlash = !self.usingFlash
        
        if(self.usingFlash) {
            flash = .on
        } else {
            flash = .off
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func recognize(imageBase64: String) {
        var request = URLRequest(url: URL(string: "https://api.kairos.com/recognize")!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(app_id, forHTTPHeaderField: "app_id")
        request.setValue(app_key, forHTTPHeaderField: "app_key")
        
        let params : NSMutableDictionary? = [
            "image" : imageBase64,
            "gallery_name" : receivedGalleryName,
            ]
        
        let data = try! JSONSerialization.data(withJSONObject: params!, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        request.httpBody = json!.data(using: String.Encoding.utf8.rawValue);
        
        Alamofire.request(request).responseJSON { (response) in
            if((response.result.value) != nil) {
                let json = JSON(response.result.value!)
                
                self.dataTextView.text = "\(json)"
            }
        }
    }
}

extension CameraViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        let image = UIImage(data: imageData!)
        
        let imagedata = UIImageJPEGRepresentation(image!, 1.0)
        let base64String : String = imagedata!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        let imageStr : String = base64String.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        recognize(imageBase64: imageStr)
    }
}

//
//  ViewController.swift
//  Kairos Example
//
//  Created by Shanezzar Sharon on 13/05/2018.
//  Copyright © 2018 Shanezzar Sharon. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    var app_id = ""
    var app_key = ""

    let imagePicker = UIImagePickerController()
    
    @IBOutlet var galleryEnrollTextfield: UITextField!
    @IBOutlet var idEnrollTextfield: UITextField!
    @IBOutlet weak var galleryRecognizeTextField: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    func enroll(imageBase64: String) {
        var request = URLRequest(url: URL(string: "https://api.kairos.com/enroll")!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.setValue(app_id, forHTTPHeaderField: "app_id")
        request.setValue(app_key, forHTTPHeaderField: "app_key")
        
        let params : NSMutableDictionary? = [
            "image" : imageBase64,
            "gallery_name" : galleryEnrollTextfield.text!,
            "subject_id" : idEnrollTextfield.text!
        ]
        
        let data = try! JSONSerialization.data(withJSONObject: params!, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        request.httpBody = json!.data(using: String.Encoding.utf8.rawValue);
        
        Alamofire.request(request).responseJSON { (response) in
            if((response.result.value) != nil) {
                let json = JSON(response.result.value!)
                
                let alert = UIAlertController(title: "Kairos", message: "\(json)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func chooseEnrollButtonAction(_ sender: Any) {
        if(galleryEnrollTextfield.text != "" && idEnrollTextfield.text != "") {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Kairos", message: "Enter all fields...", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func recognizeButtonAction(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let cameraController = storyBoard.instantiateViewController(withIdentifier: "camera_view") as! CameraViewController
        cameraController.receivedGalleryName = galleryRecognizeTextField.text!
        self.present(cameraController, animated:true, completion:nil)
    }

}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let imagedata = UIImageJPEGRepresentation(pickedImage, 1.0)
            let base64String : String = imagedata!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let imageStr : String = base64String.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            enroll(imageBase64: imageStr)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

//
//  EditAreaViewController.swift
//  tagger
//
//  Created by Paolo Longato on 27/07/2015.
//  Copyright (c) 2015 Paolo Longato. All rights reserved.
//

import UIKit

class EditAreaViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var des: UITextView!
    @IBOutlet weak var picture: UIImageView!
    var area:Area?
    var updateTable:(()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = area {
            name.text = area!.name
            des.text = area!.des
            picture.image = area!.picture
            
            name.delegate = self
            des.delegate = self
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(EditAreaViewController.dismissKeyboard))
            self.view.addGestureRecognizer(tap)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Text editing actions, functions and delegate methods
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        area!.name = name.text!
        if let a = updateTable {a()}
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        area!.des = des.text
    }
    
    // MARK: - Image picker delegate methods and take a photo actions and methods
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.camera
        self.present(picker, animated:true, completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let chosenImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.picture.image = chosenImage
            area?.picture = chosenImage
            if let a = updateTable {a()}
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
}

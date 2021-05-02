//
//  inputViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 8/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {

    @IBOutlet weak var inputFirstName: UITextField!
    @IBOutlet weak var inputLastName: UITextField!
    @IBOutlet weak var barcodeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Input Name"
               
        self.setupHideKeyboardOnTap()
        // Do any additional setup after loading the view.
    }
    
    func setupHideKeyboardOnTap() {
        self.view.addGestureRecognizer(self.endEditingRecognizer())
        self.navigationController?.navigationBar.addGestureRecognizer(self.endEditingRecognizer())
    }

    /// Dismisses the keyboard from self.view
    private func endEditingRecognizer() -> UIGestureRecognizer {
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(self.view.endEditing(_:)))
        tap.cancelsTouchesInView = false
        return tap
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        if segue.identifier == "ToInputNames"{
            let destVC = segue.destination as! ViewController
            destVC.inputFirstName = self.inputFirstName.text!
            destVC.inputLastName = self.inputLastName.text!
            destVC.includeBarcode = self.barcodeSwitch.isOn
            
        }
    }

}

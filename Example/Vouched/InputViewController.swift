//
//  inputViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 8/3/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {

    @IBOutlet private weak var inputFirstName: UITextField!
    @IBOutlet private weak var inputLastName: UITextField!
    @IBOutlet private weak var barcodeSwitch: UISwitch!
    @IBOutlet private weak var helperSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Input Name"
               
        self.setupHideKeyboardOnTap()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?) {
        switch segue.destination {
        case let destVC as IdViewController:
            destVC.inputFirstName = self.inputFirstName.text!
            destVC.inputLastName = self.inputLastName.text!
            destVC.includeBarcode = self.barcodeSwitch.isOn
        case let destVC as IdViewControllerV2:
            destVC.inputFirstName = self.inputFirstName.text!
            destVC.inputLastName = self.inputLastName.text!
            destVC.includeBarcode = self.barcodeSwitch.isOn
        default:
            break
        }
    }
    
    @IBAction func onContinue(_ sender: Any) {
        if self.helperSwitch.isOn {
            performSegue(withIdentifier: "ToInputNamesWithHelper", sender: self)
        } else {
            performSegue(withIdentifier: "ToInputNames", sender: self)
        }
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
}

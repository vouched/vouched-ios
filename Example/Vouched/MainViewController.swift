//
//  MainViewController.swift
//  Vouched_Example
//
//  Copyright © 2025 Vouched.id. All rights reserved.
//

import UIKit
import VouchedCore

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        // set up default session if we are doing a liveness job, as
        // we are reusing the FaceViewController
        if segue.identifier == "ToLivenessSession" {
            let destVC = segue.destination as! FaceViewController
            destVC.isLivenessJob = true
            destVC.session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters())
        }
    }

}

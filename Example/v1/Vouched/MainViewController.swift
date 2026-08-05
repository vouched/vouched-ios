//
//  MainViewController.swift
//  Vouched_Example
//
//  Copyright © 2021 Vouched.id. All rights reserved.
//

import UIKit
import VouchedCore

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToLivenessSession" {
            guard let destVC = segue.destination as? FaceViewController else { return }
            destVC.isLivenessJob = true
            destVC.session = VouchedSession(apiKey: getValue(key:"API_KEY"), sessionParameters: VouchedSessionParameters(), apiUrl: getValue(key: "API_URL"))
        }
    }
}

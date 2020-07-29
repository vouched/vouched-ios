//
//  LastViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 7/27/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class LastViewController: UIViewController {
    var userIDPhoto: UIImage = UIImage()
    var userSelfie: UIImage = UIImage()
    
    var result: String = ""
    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resultLabel.text = result
        var d  = self.navigationController!.viewControllers[0] as! MainViewController
//        d.textLabel.text = "david"
//        d.photoImage.image = UIImage(named:"IMG_0202")
//        d.returnedImage = UIImage(named:"IMG_0202")!

        
    }
 
    
}

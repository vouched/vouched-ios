//
//  ResultsViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 7/28/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import VouchedCore

class ResultsViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var resultName:String = ""
    var resultSuccess:Bool = false
    var resultId: Float = 0.0
    var resultSelfie: Float = 0.0
    var resultFaceMatch:Float = 0.0
    var resultNameMatch:Float = 0.0
    
    var arr:[String] = []
    var job: Job?
    var session: VouchedSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.title = "Verification Results"
        
        tableView.dataSource = self
        
        do {
            let job = try session!.postConfirm()
            print(job)
            self.job = job
            self.populateData(job: job)
        } catch {
            print("Error info: \(error)")
        }

    }
    
    func populateData(job: Job) {
        let jobResult = job.result
        resultSuccess = jobResult.success

        if jobResult.firstName != nil && jobResult.lastName != nil{
            resultName = jobResult.firstName! + " " + jobResult.lastName!
        }

        if jobResult.confidences.id != nil {
            resultId = jobResult.confidences.id!
        }
        if jobResult.confidences.selfie != nil {
            resultSelfie = jobResult.confidences.selfie!
        }
        if jobResult.confidences.faceMatch != nil {
            resultFaceMatch = jobResult.confidences.faceMatch!
        }
        if jobResult.confidences.nameMatch != nil {
            resultNameMatch = jobResult.confidences.nameMatch!
        }

        populateArray()
    }
    
    func populateArray(){
        arr.append(String(resultId >= 0.9))
        arr.append(String(resultSelfie >= 0.9))
        arr.append(String(resultSuccess))
        arr.append(resultName)
        arr.append(String(resultFaceMatch >= 0.9))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        if indexPath.row == 0 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Valid ID - " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            } else {
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 1 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Valid Selfie - " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            } else {
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 2 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Valid Match -  " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            } else {
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 3 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Name -  " + text
            if resultNameMatch >= 0.9 {
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            } else {
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 4 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Face Match - " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            } else {
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
 
        let text = arr[indexPath.row]
        cell.textLabel?.text = text
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender:Any?){
        if segue.identifier == "ToAuthenticate"{
            let destVC = segue.destination as! AuthenticateViewController
            destVC.jobId = self.job!.id
            destVC.session = self.session
        }
    }
}

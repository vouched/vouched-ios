//
//  ResultsViewController.swift
//  Vouched_Example
//
//  Created by David Woo on 7/28/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
import Vouched

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
    
    func populateData(job: Job){
        resultSuccess = job.result.success
        
        if job.result.firstName != nil && job.result.lastName != nil{
            resultName = job.result.firstName! + " " + job.result.lastName!
        }

        if job.result.confidences.id != nil {
            resultId = job.result.confidences.id!
        }
        if job.result.confidences.selfie != nil {
            resultSelfie = job.result.confidences.selfie!
        }
        if job.result.confidences.faceMatch != nil {
            resultFaceMatch = job.result.confidences.faceMatch!
        }
        if job.result.confidences.nameMatch != nil {
            resultNameMatch = job.result.confidences.nameMatch!
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
        return 5
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

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
    
    var resultsReceieved: Bool = true
    var resultName:String = ""
    var resultSuccess:Bool = false
    var resultType:String = ""
    var resultIssueDate:String = ""
    var resultExpireDate:String = ""
    var resultCountry:String = ""
    var resultState:String = ""
    var resultFaceMatch:Float = 0.0
    var resultId: Float = 0.0
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
        if job.result.confidences.faceMatch != nil{
            resultFaceMatch = job.result.confidences.faceMatch!
        }
        if job.result.confidences.idQuality != nil{
            resultId = job.result.confidences.id!
        }
        populateArray()
    }
    func populateArray(){
        if resultSuccess == true{
            arr.append("true")
            arr.append("true")
            arr.append("true")
        }
        else{
            arr.append("false")
            arr.append("false")
            arr.append("false")
        }
        arr.append(resultName)
        arr.append(String(resultFaceMatch))
        arr.append(String(resultId))
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        if indexPath.row == 0 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Valid ID - " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            }else{
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
            }else{
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 2 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Face Match - " + text
            if text == "true"{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            }else{
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }
            return cell
        }
        if indexPath.row == 3 {
            let text = arr[indexPath.row]
            
            if self.job!.result.confidences.nameMatch == nil || self.job!.result.confidences.nameMatch! < 0.8{
                cell.textLabel?.text = "Name - "
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }else{
                cell.textLabel?.text = "Name -  " + text
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            }
            return cell
        }
        if indexPath.row == 4 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Face Match Confidence -  " + text
            if (Double(text)?.isLess(than: 0.9))!{
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }else{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
            }
            return cell
        }
        if indexPath.row == 5 {
            let text = arr[indexPath.row]
            cell.textLabel?.text = "Overall Id Confidence -  " + text
            if (Double(text)?.isLess(than: 0.9))!{
                cell.accessoryView = UIImageView(image:UIImage(named: "x.jpg"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:22,height:22)
            }else{
                cell.accessoryView = UIImageView(image:UIImage(named: "check.png"))
                cell.accessoryView?.frame = CGRect(x:0,y:0,width:24,height:22)
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

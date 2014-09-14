//
//  ViewController.swift
//  TouchIDDemo
//
//  Created by Yi Wang on 9/12/14.
//  Copyright (c) 2014 Yi. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, EditNoteViewControllerDelegate {
    
    @IBOutlet var tblNotes: UITableView!
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    var dataArray: NSMutableArray! // Declared as an optional, if no data exists, array remains nil
    var noteIndexToEdit: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tblNotes.delegate = self;
        self.tblNotes.dataSource = self;
        authenticateUser()
        loadData()
        
        
        if (dataArray != nil){
            NSLog("dataArray.count:%i", dataArray!.count)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new vc, pass selected object to the new vc
        if segue.identifier == "idSegueEditNote" {
            var editNoteViewController : EditNoteViewController = segue.destinationViewController as EditNoteViewController
            editNoteViewController.delegate = self;
            if (noteIndexToEdit != nil) {
                editNoteViewController.indexOfEditedNote  = noteIndexToEdit
                noteIndexToEdit = nil
            }
            
        }
    }
    
    
    func authenticateUser () {
        // Get local authentication context
        let context : LAContext = LAContext ()
        
        // Declare a NSError variable, declared as optional because if no error, it will be nil
        var error: NSError?
        
        // Set the reason string that will appear on the authentication alert
        var reasonString = "Authentication is needed to access your notes."
        
        // Check if the device an evaluate the policy, error is passed by reference
        if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
            [context .evaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString, reply: { (success: Bool, evalPolicyError: NSError?) -> Void in
                
                if success {
                    // must use main thread for loading and displaying data
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        self.loadData()
                    })
                    
                    
                } else {
                    // If Authentication failed then show a message to the console with short description
                    // In case that the error is a user fallback, the show the password alert view
                    
                    println(evalPolicyError?.localizedDescription)
                    
                    switch evalPolicyError!.code {
                    case LAError.SystemCancel.toRaw() :   // if we dont convert to int compiler doesnt throw error
                        println("Authentication was cancelled by the system")
                    case LAError.UserCancel.toRaw() :
                        println("Authentication was canceled by user")
                    case LAError.UserFallback.toRaw() :
                        println("User selected to enter custom password")
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.showPasswordAlert()
                        })
                    default :
                        println("Authentication failed")
                        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                            self.showPasswordAlert()
                        })
                        
                    }
                    
                }
                
            })]
            
        } else {
            // If security policy cannot be evaluated then show a short message depending on the error
            
            switch error!.code {
            
            case LAError.TouchIDNotEnrolled.toRaw() :
                println("TouchID is not enrolled")
            case LAError.PasscodeNotSet.toRaw() :
                println("A passcode as not been set")
            default :
                // The LAError.TouchIDNotAvailable case
                println("TouchID not available")
            }
            
            // Optionally the error description can be displayed on the console.
            println(error?.localizedDescription)
            
            // Show the custom alert view to allow users to enter the password
            self.showPasswordAlert()
        }
        
        
    }
    
    
    func showPasswordAlert () {
        var passwordAlert : UIAlertView = UIAlertView (title: "TouchID Demo", message: "Please type your password", delegate: self, cancelButtonTitle: "Calcel", otherButtonTitles: "Okay")
        passwordAlert.alertViewStyle = UIAlertViewStyle.SecureTextInput
        passwordAlert.show()
        
    }
    
    func alertView(alertView: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            if !alertView.textFieldAtIndex(0)!.text.isEmpty {
                if alertView.textFieldAtIndex(0)!.text == "swift" {
                    loadData()
                } else {
                    showPasswordAlert()
                }
            }
        } else {
            showPasswordAlert()
        }
    }
    
    
    // MARK: TableView DataSource Delegate
    func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return 1
    }
    
    // dataArray was declared as an optional, so it could be nil
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        if let array = dataArray {
            return array.count
        } else {
            
            return 0
        }
    }
    
   
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        NSLog("came in to cellforrowatindexpath")
        
        var cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        
        let currentNote = self.dataArray.objectAtIndex(indexPath.row) as Dictionary<String, String>
        
        if (currentNote.isEmpty == false) {
            NSLog("currentnote.title", currentNote["title"]! as String)
        }
        
        
        
        cell.textLabel!.text = currentNote["title"];
        
        
        return cell

    }
    
    
    
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        noteIndexToEdit = indexPath.row
        performSegueWithIdentifier("idSegueEditNote", sender: self)
    }
    
    func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        
        if editingStyle == UITableViewCellEditingStyle.Delete {
            // Delete the respective object from the dataArray array
            dataArray.removeObjectAtIndex(indexPath.row)
            
            // Save array to disk
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            dataArray.writeToFile(appDelegate.getPathOfDataFile(), atomically: true)
            
            // Reload tableview
            tblNotes.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            
            
        }
        
        
    }
    
    
    // MARK: Helper
    func loadData (){
        if appDelegate.checkIfDataFileExists() {
            self.dataArray = NSMutableArray(contentsOfFile: appDelegate.getPathOfDataFile())
            self.tblNotes.reloadData()
        } else {
            println("File does not exist")
        }
    }
    
    // MARK: EditeNoteViewController Delegate
    func noteWasSaved() {
        // load the data and reload the tableview
        loadData()
    }
    
    
    
}


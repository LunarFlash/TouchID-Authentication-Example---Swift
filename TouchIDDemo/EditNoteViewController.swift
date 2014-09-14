//
//  EditNoteViewController.swift
//  TouchIDDemo
//
//  Created by Yi Wang on 9/12/14.
//  Copyright (c) 2014 Yi. All rights reserved.
//

import UIKit

protocol EditNoteViewControllerDelegate {
    func noteWasSaved()
}


class EditNoteViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var txtNoteTitle: UITextField!
    @IBOutlet var tvNoteBody: UITextView!
    // delegates must be optional bevause it is possible no object to be assigned to it.


    var delegate : EditNoteViewControllerDelegate?
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    
    var indexOfEditedNote : Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.txtNoteTitle.becomeFirstResponder()
        self.txtNoteTitle.delegate = self;
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (indexOfEditedNote != nil) {
            editNote()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func saveNote(sender: AnyObject) {
        if self.txtNoteTitle.text.isEmpty {
            println("No title for the note")
            return
        }
        
        // Create dictionary with note data
        var noteDict = ["title" : self.txtNoteTitle.text, "body" : self.tvNoteBody.text]
        
        // Decalre a NSMutableArray object
        var dataArray: NSMutableArray
        
        // If the notes data file exists then load its content and add the new note data too, otherwise just
        // initialize the dataArray array and add the new note data
        
        if appDelegate.checkIfDataFileExists() {
            // load any existing notes
            dataArray = NSMutableArray(contentsOfFile: appDelegate.getPathOfDataFile())
            
            if indexOfEditedNote == nil {
                dataArray.addObject(noteDict)
            } else {
                // replace the existing dictionary to the array
                dataArray.replaceObjectAtIndex(indexOfEditedNote, withObject: noteDict)
            }
            
        } else {
            // create new mutable array and add notedict to it
            dataArray = NSMutableArray(object: noteDict)
        }
        
        // Save array content to file
        dataArray.writeToFile(appDelegate.getPathOfDataFile(), atomically: true)
        
        //NSLog("filePath:%@", appDelegate.getPathOfDataFile())
        //NSLog("dataArray.count:%i", dataArray.count)
        
        // Notify delegate class that note was saved
        delegate?.noteWasSaved()
        
        // Pop the view controller
        self.navigationController!.popViewControllerAnimated(true)
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - TextField Delegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        // Resign the textfield from first responder
        textField.resignFirstResponder()
        
        // Make the textview the first responder
        self.tvNoteBody.becomeFirstResponder()
        return true
    }
    
    // MARK: - Helper
    func editNote () {
        // Load all notes
        var notesArray: NSArray = NSArray(contentsOfFile: appDelegate.getPathOfDataFile())
        
        // Get the dictionary at the specified index
        let noteDict : Dictionary = notesArray.objectAtIndex(indexOfEditedNote) as Dictionary <String, String>
        
        // Set textfield text
        txtNoteTitle.text = noteDict["title"]
        
        // set textview text
        tvNoteBody.text = noteDict["body"]
        
    }

}

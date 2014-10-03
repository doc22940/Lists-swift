//
//  ListsViewController.swift
//  SwiftLists
//
//  Created by Leah Culver on 9/27/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

import UIKit

class ListsViewController: UITableViewController {
    
    var isAddingList = false
    let sortDescriptors = [NSSortDescriptor(key: "mtime", ascending: false)] // Sort lists by most recently updated


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // No lists yet? Show row to add a list
        self.isAddingList = DBDatastoreManager.sharedManager().listDatastores(nil).count < 1
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Observe changes to datastore list (possibly from other devices)
        DBDatastoreManager.sharedManager().addObserver(self) { [unowned self] () -> Void in
            // Reload list of lists to get changes
            self.tableView.reloadData()
        }
        
        self.tableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop listening for changes to the datastores
        DBDatastoreManager.sharedManager().removeObserver(self)
    }
    

    // Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.isAddingList {
            return 2
        }
        
        return  1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isAddingList && section == 0 {
            return 1 // Add list cell
        }
        
        // List count
        return DBDatastoreManager.sharedManager().listDatastores(nil).count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.isAddingList && indexPath.section == 0 {
            // Add list cell
            let cell = self.tableView.dequeueReusableCellWithIdentifier("AddListCell") as? UITableViewCell
            return cell!
        }
        
        // List cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier("ListCell") as? UITableViewCell
        
        let datastores = (DBDatastoreManager.sharedManager().listDatastores(nil) as NSArray).sortedArrayUsingDescriptors(self.sortDescriptors)
        let datastoreInfo = datastores[indexPath.row] as DBDatastoreInfo
        
        cell!.textLabel!.text = datastoreInfo.title
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if self.isAddingList && indexPath.section == 0 {
            // Add list cell
            return false
        }
        
        return true // List cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            // Delete the row from the data source
            let datastores = (DBDatastoreManager.sharedManager().listDatastores(nil) as NSArray).sortedArrayUsingDescriptors(self.sortDescriptors)
            let datastoreInfo = datastores[indexPath.row] as DBDatastoreInfo
            
            DBDatastoreManager.sharedManager().deleteDatastore(datastoreInfo.datastoreId, error: nil)
            
            // Remove row from table view
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    
    // Table view delegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    
    // Text field delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if !textField.text.isEmpty {
            // Add new list / datastore
            let datastore = DBDatastoreManager.sharedManager().createDatastore(nil)
            datastore.title = textField.text
            datastore.sync(nil)
            
            // Close the datastore - potentially deleted, or re-opened in DBListViewController
            datastore.close()
        }
        
        // Clear text field
        textField.text = nil
        textField.resignFirstResponder()
        
        // Hide row for adding a list
        self.isAddingList = false
        self.tableView.reloadData()
        
        return true
    }
    
    
    // Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the selected datastoreInfo to the new view controller
        let indexPath = self.tableView.indexPathForSelectedRow()
        let datastores = (DBDatastoreManager.sharedManager().listDatastores(nil) as NSArray).sortedArrayUsingDescriptors(self.sortDescriptors)
        let datastoreInfo = datastores[indexPath!.row] as DBDatastoreInfo
        
        let viewController = segue.destinationViewController as? ListViewController
        viewController!.datastoreId = datastoreInfo.datastoreId
    }
    
    
    // IB actions
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        // Toggle row for adding a new list
        self.isAddingList = !self.isAddingList
        self.tableView.reloadData()
    }
    
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        // Show settings action sheet to link or unlink with a Dropbox account
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let account = DBAccountManager.sharedManager().linkedAccount
        
        if account == nil {
            // Link to Dropbox
            alertController.addAction(UIAlertAction(title: "Link to Dropbox", style: .Default, handler: { (action) -> Void in
                // Link
                DBAccountManager.sharedManager().linkFromController(self)
            }))
        } else {
            // Unlink from Dropbox
            alertController.title = "Linked with Dropbox account:"
            alertController.message = account.info.displayName
            alertController.addAction(UIAlertAction(title: "Unlink from Dropbox", style: .Destructive, handler: { (action) -> Void in
                
                // Unlink
                account.unlink()
                
                // Shutdown and stop listening for changes to the datastores
                DBDatastoreManager.sharedManager().shutDown()
                DBDatastoreManager.sharedManager().removeObserver(self)
                
                // Use local datastores
                DBDatastoreManager.setSharedManager(DBDatastoreManager.localManagerForAccountManager(DBAccountManager.sharedManager()))
                
                // No lists yet? Show row to add a list
                self.isAddingList = DBDatastoreManager.sharedManager().listDatastores(nil).count < 1
                
                // Observe changes to datastore list (possibly from other devices)
                DBDatastoreManager.sharedManager().addObserver(self, block: { [unowned self] () -> Void in
                    // Reload list of lists to get changes
                    self.tableView.reloadData()
                })
                
                // Reload list
                self.tableView.reloadData()
            }))
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // Display action sheet
        let popoverPresentationController = alertController.popoverPresentationController
        popoverPresentationController?.barButtonItem = sender as UIBarButtonItem
        presentViewController(alertController, animated: true, completion: nil)
    }
    
}


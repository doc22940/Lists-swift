//
//  ListViewController.swift
//  SwiftLists
//
//  Created by Leah Culver on 9/27/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

import UIKit

class ListViewController: UITableViewController {
    
    var datastoreId: String = ""
    var datastore: DBDatastore?
    let sortDescriptors = [NSSortDescriptor(key: "fields.date", ascending: true)] // Sort with newest items on the bottom
    var justLinkedToDropbox = false
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Open the datastore for this list
        self.datastore = DBDatastoreManager.sharedManager().openDatastore(self.datastoreId, error: nil)
        self.datastore!.sync(nil)
        self.tableView.reloadData()

        // Set the title to the title of the datastore
        self.title = self.datastore!.title
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Observe changes to datastore (possibly from other devices)
        self.datastore!.addObserver(self, block: { [unowned self] () -> Void in
            if self.datastore!.status.incoming {
                // Sync with updated data and reload
                self.datastore!.sync(nil)
                self.tableView.reloadData()
                
                // Update title if needed
                self.title = self.datastore!.title
            }
        })
        
        // Observe changes to datastore list (possibly from other devices)
        DBDatastoreManager.sharedManager().addObserver(self) { [unowned self] () -> Void in
            // Was this datastore deleted?
            if DBDatastoreManager.sharedManager().listDatastoreInfo(nil)[self.datastoreId] == nil {
                // Show friendly error message and go back.
                let alertController = UIAlertController(title: "Uh oh!", message: "List does not exist.", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }
        
        // Just linked to Dropbox? Go to sharing screen.
        let account = DBAccountManager.sharedManager().linkedAccount
        if account != nil && self.justLinkedToDropbox {
            self.performSegueWithIdentifier("ShareListSegue", sender: nil)
            self.justLinkedToDropbox = false
            return
        }
        
        self.datastore!.sync(nil)
        self.tableView.reloadData();
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop listening for changes to the datastore
        self.datastore?.close()
        self.datastore?.removeObserver(self)
        self.datastore = nil;
        
        // Stop listening for changes to the datastores
        DBDatastoreManager.sharedManager().removeObserver(self)
    }
    
    
    // Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.datastore != nil && self.datastore!.isWritable {
            return 2 // Add item cell
        }
        
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && self.datastore != nil {
            // Items count
            let itemsTable = self.datastore!.getTable("items")
            let items = itemsTable.query(nil, error: nil)
            return items.count
        }
        
        return 1 // Add item cell
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // Item cell
            let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell", forIndexPath: indexPath) as? UITableViewCell
            
            let itemsTable = self.datastore!.getTable("items")
            let items = (itemsTable.query(nil, error: nil) as NSArray).sortedArrayUsingDescriptors(self.sortDescriptors)
            let item = items[indexPath.row] as? DBRecord
            
            cell!.textLabel!.text = item!.fields["text"] as? NSString
            
            return cell!
        }
        
        // Add item cell
        let cell = self.tableView.dequeueReusableCellWithIdentifier("AddItemCell") as? UITableViewCell
        return cell!
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Item cell
        if indexPath.section == 0 && self.datastore!.isWritable {
            return true
        }
        
        return false // Add item cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            
            // Delete the row from the data source
            let itemsTable = self.datastore!.getTable("items")
            let items = (itemsTable.query(nil, error: nil) as NSArray).sortedArrayUsingDescriptors(self.sortDescriptors)
            let item = items[indexPath.row] as? DBRecord
            
            item?.deleteRecord()
            self.datastore!.sync(nil)
            
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
            // Add a new item to the list with text and date
            let itemsTable = self.datastore!.getTable("items")
            itemsTable.insert(["text" : textField.text, "date" : NSDate()])
            self.datastore!.sync(nil)
            
            // Reload table to show new item
            self.tableView.reloadData()
        }

        // Clear text field
        textField.text = nil
        textField.resignFirstResponder()

        return true
    }
    
    
    // Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        let account = DBAccountManager.sharedManager().linkedAccount
        
        if account == nil {
            // Dropbox account required in order to share a list
            let alertController = UIAlertController(title: "Link to Dropbox", message: "To share a list you'll need to link to Dropbox.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: { (action) -> Void in
                // Link to Dropbox
                self.justLinkedToDropbox = true
                DBAccountManager.sharedManager().linkFromController(self)
            }))
            presentViewController(alertController, animated: true, completion: nil)

            return false
        }
        
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the selected datastoreInfo to the new view controller
        let viewController = segue.destinationViewController as ShareViewController
        viewController.datastoreId = self.datastoreId
    }

}
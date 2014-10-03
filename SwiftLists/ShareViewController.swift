//
//  ShareViewController.swift
//  SwiftLists
//
//  Created by Leah Culver on 9/30/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

import UIKit
import MessageUI

class ShareViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    
    var datastoreId: String = ""
    var datastore: DBDatastore?
    
    override func viewWillAppear(animated: Bool) {
        // Open the datastore for this list
        self.datastore = DBDatastoreManager.sharedManager().openDatastore(self.datastoreId, error: nil)
        
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Observe changes to datastore (possibly from other devices)
        self.datastore!.addObserver(self, block: { [unowned self] () -> Void in
            if self.datastore!.status.incoming {
                // Sync with updated data and reload
                self.datastore!.sync(nil)
                self.tableView.reloadData()
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
    
    
    // Table view helpers
    
    func isTeamAccount() -> Bool {
        let account = DBAccountManager.sharedManager().linkedAccount
        
        return !account.info.orgName.isEmpty
    }
    
    func isSharePubliclySection(section: NSInteger) -> Bool {
        return section == 0
    }
    
    func isShareTeamSection(section: NSInteger) -> Bool {
        return self.isTeamAccount() && section == 1
    }
    
    func isShareViaSection(section: NSInteger) -> Bool {
        if self.isTeamAccount() {
            return section == 2
        }
        
        return section == 1
    }
    
    
    // Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var numSections: Int = 1
        
        // Show team role section if account is part of a team
        if self.isTeamAccount() {
            ++numSections
        }
        
        // Show messaging section if datastore is shared
        if self.datastore!.getRoleForPrincipal(DBPrincipalPublic) != .None || self.datastore!.getRoleForPrincipal(DBPrincipalTeam) != .None {
            ++numSections
        }
        
        return numSections
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isShareViaSection(section) {
            return 2
        }
        
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if self.isSharePubliclySection(indexPath.section) {
            let cell = tableView.dequeueReusableCellWithIdentifier("PickerCell", forIndexPath: indexPath) as PickerCell
            cell.principal = DBPrincipalPublic
            
            let role = self.datastore!.getRoleForPrincipal(DBPrincipalPublic)
            cell.updateRole(role, effectiveRole: self.datastore!.effectiveRole)
            
            return cell
        }
        
        if self.isShareTeamSection(indexPath.section) {
            let cell = tableView.dequeueReusableCellWithIdentifier("PickerCell", forIndexPath: indexPath) as PickerCell
            cell.principal = DBPrincipalTeam
            
            let role = self.datastore!.getRoleForPrincipal(DBPrincipalTeam)
            cell.updateRole(role, effectiveRole: self.datastore!.effectiveRole)
            
            return cell
        }
        
        // Share via section
        let identifier = indexPath.row == 0 ? "EmailCell" : "MessageCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as UITableViewCell
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.isSharePubliclySection(section) {
            return "Share Publicly"
        }
        
        if self.isShareTeamSection(section) {
            let account = DBAccountManager.sharedManager().linkedAccount
            return "Share with Team (\(account.info.orgName))"
        }
        
        if self.isShareViaSection(section) {
            return "Share via"
        }
        
        return nil
    }
    
    
    // Table view delegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.isShareViaSection(indexPath.section) {
            return 44.0
        }
        
        // Share publicly / Share team section picker
        return 88.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.isShareViaSection(indexPath.section) {
            
            println("Sharing datastore ID: " + self.datastoreId)
            
            let shareURL = "https://dslists.site44.com/#" + self.datastoreId
            
            if indexPath.row == 0 {
                
                // Share via email
                if MFMailComposeViewController.canSendMail() {
                    
                    let composeController = MFMailComposeViewController()
                    composeController.mailComposeDelegate = self
                    let account = DBAccountManager.sharedManager().linkedAccount
                    composeController.setSubject("\(account.info.userName) would like to share a list with you")
                    composeController.setMessageBody("Hi,\n\nI'd like to share a List with you!\n\n\(shareURL)\n\n\(account.info.userName)", isHTML: false)
                    
                    presentViewController(composeController, animated: true, completion: nil)
                    
                } else {
                    let alertController = UIAlertController(title: "Uh oh!", message: "Unable to send email.", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                    presentViewController(alertController, animated: true, completion: nil)
                }
            } else if indexPath.row == 1 {
                
                // Share via text message
                if MFMessageComposeViewController.canSendText() {
                    
                    let composeController = MFMessageComposeViewController()
                    composeController.messageComposeDelegate = self
                    composeController.body = "I'd like to share a List with you! " + shareURL
                    
                    presentViewController(composeController, animated: true, completion: nil)
                    
                } else {
                    let alertController = UIAlertController(title: "Uh oh!", message: "Unable to send text messages.", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                    presentViewController(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    // Picker view data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 3
    }

    
    // Picker view delegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        // Roles are None, Viewer, Editor, and Owner - but Owner cannot be picked.
        switch row {
        case 0:
            return "None"
        case 1:
            return "Viewable"
        case 2:
            return "Editable"
        default:
            break
        }
        
        return nil
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var newRole: DBRole = .None
        
        switch row {
        case 1:
            newRole = .Viewer
        case 2:
            newRole = .Editor
        default:
            break
        }
        
        var view = pickerView.superview
        do {
            if let cell = view as? PickerCell {
                
                // Update role for principal
                self.datastore?.setRoleForPrincipal(cell.principal, to: newRole)
                self.datastore?.sync(nil)
                
                // Reload to update sections
                self.tableView.reloadData()

                break
            }
            view = view?.superview
        } while view != nil
    }
    
    
    // Mail compose delegate

    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
        if result.value == MFMailComposeResultSent.value {
            let alertController = UIAlertController(title: "", message: "Email sent!", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        } else if result.value == MFMailComposeResultFailed.value {
            let alertController = UIAlertController(title: "Uh oh!", message: "Email failed to send.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    
    // Message compose delegate

    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
        if result.value == MessageComposeResultSent.value {
            let alertController = UIAlertController(title: "", message: "Message sent!", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        } else if result.value == MessageComposeResultFailed.value {
            let alertController = UIAlertController(title: "Uh oh!", message: "Message failed to send.", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
}

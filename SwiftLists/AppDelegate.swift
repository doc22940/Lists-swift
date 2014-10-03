//
//  AppDelegate.swift
//  SwiftLists
//
//  Created by Leah Culver on 9/27/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let accountManager = DBAccountManager(appKey: "gmd9bz0ihf8t30o", secret: "gt6onalc86cbetu")
        DBAccountManager.setSharedManager(accountManager)
        
        let account = DBAccountManager.sharedManager().linkedAccount
        
        if let account = account? {
            // Use Dropbox datastores
            DBDatastoreManager.setSharedManager(DBDatastoreManager(forAccount:account))
        } else {
            // Use local datastores
            DBDatastoreManager.setSharedManager(DBDatastoreManager.localManagerForAccountManager(DBAccountManager.sharedManager()))
        }

        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        let action = url.lastPathComponent
        
        if action == "connect" {
            // Account linked to Dropbox -- db-gmd9bz0ihf8t30o://1/connect
            let account = DBAccountManager.sharedManager().handleOpenURL(url)
            
            if let account = account? {
                // App linked successfully!
                
                // Migrate any local datastores to Dropbox
                let localDatastoreManager = DBDatastoreManager.localManagerForAccountManager(DBAccountManager.sharedManager())
                localDatastoreManager.migrateToAccount(account, error: nil)
                
                // Use Dropbox datastores
                DBDatastoreManager.setSharedManager(DBDatastoreManager(forAccount:account))
                
                return true
            }
        } else if action == "cancel" {
            // Do nothing if user cancels login
        } else {
            // Shared datastore -- Lists://
            let datastoreId = url.host
            
            println("Opening datastore ID: " + datastoreId!)
            
            // Return to root view controller
            let navigationController = self.window?.rootViewController as UINavigationController;
            navigationController.popToRootViewControllerAnimated(false)
            
            let account = DBAccountManager.sharedManager().linkedAccount
            
            if let account = account? {
                // Go to the shared list (will open the list)
                if DBDatastore.isValidShareableId(datastoreId) {
                    
                    let viewController = navigationController.storyboard?.instantiateViewControllerWithIdentifier("ListViewController") as ListViewController
                    viewController.datastoreId = datastoreId!
                    
                    navigationController.pushViewController(viewController, animated: false)
                } else {
                    // Notify user that this isn't a valid link
                    let alertController = UIAlertController(title: "Uh oh!", message: "Invalid List link.", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                    window?.rootViewController!.presentViewController(alertController, animated: true, completion: nil)
                }
            } else {
                // Notify user to link with Dropbox
                let alertController = UIAlertController(title: "Link to Dropbox", message: "To accept a shared list you'll need to link to Dropbox first.", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .Default, handler: nil))
                window?.rootViewController!.presentViewController(alertController, animated: true, completion: nil)
            }
            
            return true
        }
        
        return  false
    }

}


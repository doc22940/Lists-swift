//
//  PickerCell.swift
//  SwiftLists
//
//  Created by Leah Culver on 9/30/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

import UIKit

class PickerCell: UITableViewCell {

    var principal: String?

    @IBOutlet weak var picker: UIPickerView!
    
    
    func updateRole(role:DBRole, effectiveRole:DBRole) {
        self.picker.selectRow(role.toRaw(), inComponent: 0, animated: false)
        
        let isEnabled: Bool = effectiveRole.toRaw() >= DBRole.Editor.toRaw()
        self.picker.userInteractionEnabled = isEnabled
        self.picker.alpha = isEnabled ? 1.0 : 0.6
    }

}

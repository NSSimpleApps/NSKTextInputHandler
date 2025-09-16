//
//  NSKTextInputHandlerApp.swift
//  NSKTextInputHandler
//
//  Created by user on 03.09.2025.
//

import SwiftUI

@main
struct NSKTextInputHandlerApp: App {
    
    private let parentView: ParentView
    
    init() {
        let phoneNumberMasker = PhoneNumberMasker()
        let textFieldViewModel = TextFieldViewModel(
            text: "",
            masker: phoneNumberMasker
        )
        let textViewViewModel = TextViewViewModel(
            text: "",
            masker: phoneNumberMasker
        )
        
        self.parentView = ParentView(
            phoneNumberSingleLineViewModel: textFieldViewModel,
            phoneNumberMultiLineViewModel: textViewViewModel
        )
    }
    
    
    
    var body: some Scene {
        WindowGroup {
            self.parentView
        }
    }
}

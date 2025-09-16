//
//  NSKTextFieldDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 03.09.2025.
//

import UIKit

typealias NSKTextFieldDecisionHandler = @MainActor @Sendable (NSKTextFieldDelegate, NSKTextFieldDecisionInfo) -> Bool

final class NSKTextFieldDelegate: NSObject {
    private let decisionHandler: NSKTextFieldDecisionHandler
    
    weak var parentHandler: AnyObject?
    private weak var textFieldSystemDelegate: UITextFieldDelegate?
    
    init(decisionHandler: @escaping NSKTextFieldDecisionHandler) {
        self.decisionHandler = decisionHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:)) {
            return self
        } else {
            return self.textFieldSystemDelegate
        }
    }
    
    @MainActor
    func configure(textField: UITextField) {
        self.textFieldSystemDelegate = textField.delegate
        textField.delegate = self
    }
}

extension NSKTextFieldDelegate: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return self.decisionHandler(self, .init(textField: textField, range: range, replacementString: string))
    }
}

struct NSKTextFieldDecisionInfo {
    let textField: UITextField
    let range: NSRange
    let replacementString: String
}

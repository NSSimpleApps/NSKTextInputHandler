//
//  NSKTextInputDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 03.09.2025.
//

import UIKit

final class NSKTextInputDelegate: NSObject {
    private let decisionHandler: @MainActor @Sendable (NSKTextInputDelegate, NSKTextInputDecisionInfo) -> Bool
    
    weak var systemTextFieldDelegate: UITextFieldDelegate?
    weak var parentHandler: AnyObject?
    
    init(decisionHandler: @MainActor @Sendable @escaping (NSKTextInputDelegate, NSKTextInputDecisionInfo) -> Bool) {
        self.decisionHandler = decisionHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:)) {
            return self
        } else {
            return self.systemTextFieldDelegate
        }
    }
}

extension NSKTextInputDelegate: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return self.decisionHandler(self, .init(textField: textField, range: range, replacementString: string))
    }
}

struct NSKTextInputDecisionInfo {
    let textField: UITextField
    let range: NSRange
    let replacementString: String
}

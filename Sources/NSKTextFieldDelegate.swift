//
//  NSKTextFieldDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 03.09.2025.
//

import UIKit

typealias NSKTextFieldDecisionHandler = @MainActor @Sendable (NSKTextFieldDelegate, NSKTextFieldDecision) -> Bool

final class NSKTextFieldDelegate: NSObject {
    
    weak var parentHandler: AnyObject?
    
    private let decisionHandler: NSKTextFieldDecisionHandler
    private weak var textFieldSystemDelegate: UITextFieldDelegate?
    
    init(
        decisionHandler: @escaping NSKTextFieldDecisionHandler
    ) {
        self.decisionHandler = decisionHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if self.respondsDecision(for: aSelector) || self.respondsDecisionV26(for: aSelector) {
            return self
        } else {
            return self.textFieldSystemDelegate
        }
    }
    
    private func respondsDecision(
        for aSelector: Selector
    ) -> Bool {
        return aSelector == #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))
    }
    
    private func respondsDecisionV26(
        for aSelector: Selector
    ) -> Bool {
        if #available(iOS 26.0, *) {
            return aSelector == #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersInRanges:replacementString:))
        } else {
            return false
        }
    }
    
    @MainActor
    func configure(
        textField: UITextField
    ) {
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
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersInRanges ranges: [NSValue],
        replacementString string: String
    ) -> Bool {
        guard let range = ranges.first?.rangeValue else { return false }
        
        return self.textField(
            textField,
            shouldChangeCharactersIn: range,
            replacementString: string
        )
    }
}

struct NSKTextFieldDecision {
    
    let textField: UITextField
    let range: NSRange
    let replacementString: String
}

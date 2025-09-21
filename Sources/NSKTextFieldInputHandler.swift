//
//  NSKTextFieldInputHandler.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import UIKit

public typealias NSKTextFieldInputDecisionHandler<NSKTextInputWarning, NSKTextInputError: Error> =
@MainActor @Sendable (NSKTextFieldInputHandler<NSKTextInputWarning, NSKTextInputError>, NSKTextInputInfo) throws(NSKTextInputError) -> NSKTextInputDecision<NSKTextInputWarning>

public typealias NSKTextFieldInputResultHandler<NSKTextInputWarning, NSKTextInputError: Error> =
@MainActor @Sendable (NSKTextFieldInputHandler<NSKTextInputWarning, NSKTextInputError>, Result<NSKTextInputCustomText<NSKTextInputWarning>, NSKTextInputError>) -> Void


@MainActor
public final class NSKTextFieldInputHandler<NSKTextInputWarning, NSKTextInputError: Error> {
    
    private let textFieldAction: UIAction
    private let textFieldDelegate: NSKTextFieldDelegate
    public weak var parentHandler: AnyObject?
    private var textInputWarning: NSKTextInputWarning?
    
    public init(
        decisionHandler: @escaping NSKTextFieldInputDecisionHandler<NSKTextInputWarning, NSKTextInputError>,
        resultHandler: @escaping NSKTextFieldInputResultHandler<NSKTextInputWarning, NSKTextInputError>)
    {
        let identifier = UIAction.Identifier(rawValue: "ns.simple.apps.NSKTextFieldInputHandler")
        self.textFieldAction = UIAction(
            identifier: identifier,
            handler: { textFieldAction in
                guard let textField = textFieldAction.sender as? UITextField else { return }
                guard let textFieldDelegate = textField.delegate as? NSKTextFieldDelegate else { return }
                guard let self = textFieldDelegate.parentHandler as? Self else { return }
                
                let textInputWarning = self.textInputWarning
                self.textInputWarning = nil
                
                let text = textField.text ?? ""
                let beginningOfDocument = textField.beginningOfDocument
                let selectedPosition = textField.selectedTextRange?.start ?? beginningOfDocument
                let offset = textField.offset(from: beginningOfDocument, to: selectedPosition)
                let cursorPosition = text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
                
                let textInputCustomText = NSKTextInputCustomText(
                    text: text,
                    cursorPosition: cursorPosition,
                    warning: textInputWarning
                )
                resultHandler(self, .success(textInputCustomText))
            })
        
        self.textFieldDelegate = .init(
            decisionHandler: { textFieldDelegate, textInputDecisionInfo in
                guard let self = textFieldDelegate.parentHandler as? Self else {
                    return false
                }
                
                let textField = textInputDecisionInfo.textField
                let range = textInputDecisionInfo.range
                let replacementString = textInputDecisionInfo.replacementString
                let currentText = textField.text ?? ""
                
                guard let editRange = Range(range, in: currentText) else {
                    return false
                }
                
                let textInputAction: NSKTextInputAction
                
                if replacementString.isEmpty {
                    textInputAction = .delete(editRange)
                } else {
                    textInputAction = .insert(.init(
                        position: editRange.lowerBound,
                        replacementString: replacementString)
                    )
                }
                self.textInputWarning = nil
                
                do {
                    let textInputDecision =
                    try decisionHandler(self, .init(currentText: currentText, textInputAction: textInputAction))
                    
                    switch textInputDecision {
                    case .approve(let textInputWarning):
                        self.textInputWarning = textInputWarning
                        return true
                        
                    case .customText(let textInputCustomText):
                        self.textInputWarning = textInputCustomText.warning
                        
                        let customText = textInputCustomText.text
                        let cursorPosition = textInputCustomText.cursorPosition
                        let offset = NSRange(cursorPosition..<cursorPosition, in: customText).location
                        
                        let delegate = textField.delegate
                        textField.delegate = nil
                        
                        Task {
                            textField.text = customText
                            
                            let selectedTextRange: UITextRange?
                            if let cursorPosition = textField.position(from: textField.beginningOfDocument, offset: offset) {
                                selectedTextRange = textField.textRange(from: cursorPosition, to: cursorPosition)
                            } else {
                                selectedTextRange = nil
                            }
                            
                            if let selectedTextRange {
                                textField.selectedTextRange = selectedTextRange
                            }
                            textField.delegate = delegate
                            textField.sendActions(for: .editingChanged)
                        }
                        
                        return false
                    }
                } catch let textInputError as NSKTextInputError {
                    resultHandler(self, .failure(textInputError))
                    return false
                    
                } catch {
                    return false
                }
            })
        self.textFieldDelegate.parentHandler = self
    }
    
    public func configure(textField: UITextField) {
        textField.addAction(self.textFieldAction, for: .editingChanged)
        
        self.textFieldDelegate.configure(textField: textField)
    }
}

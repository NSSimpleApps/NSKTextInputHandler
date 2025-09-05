//
//  NSKTextInputHandler.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import UIKit

@MainActor
public final class NSKTextInputHandler<NSKTextInputWarning, NSKTextInputError: Error> {
    private let decisionHandler: @MainActor (NSKTextInputHandler, NSKTextInputInfo) throws(NSKTextInputError) -> NSKTextInputDecision<NSKTextInputWarning>
    private let resultHandler: @MainActor (NSKTextInputHandler, Result<NSKTextInputCustomText<NSKTextInputWarning>, NSKTextInputError>) -> Void
    private let textFieldAction: UIAction
    private let textInputDelegate: NSKTextInputDelegate
    
    public weak var parentHandler: AnyObject?
    private var textInputWarning: NSKTextInputWarning?
    
    public init(
        decisionHandler:
        @MainActor @Sendable @escaping (NSKTextInputHandler, NSKTextInputInfo) throws(NSKTextInputError) -> NSKTextInputDecision<NSKTextInputWarning>,
        
        resultHandler:
        @MainActor @Sendable @escaping (NSKTextInputHandler, Result<NSKTextInputCustomText<NSKTextInputWarning>, NSKTextInputError>) -> Void)
    {
        let identifier = UIAction.Identifier(rawValue: "ns.simple.apps.NSKTextInputHandler")
        self.textFieldAction = UIAction(
            identifier: identifier,
            handler: { action in
                guard let textField = action.sender as? UITextField else { return }
                guard let textInputDelegate = textField.delegate as? NSKTextInputDelegate else { return }
                guard let self = textInputDelegate.parentHandler as? Self else { return }
                
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
                self.resultHandler(self, .success(textInputCustomText))
            })
        
        self.decisionHandler = decisionHandler
        self.resultHandler = resultHandler
        
        self.textInputDelegate = .init(
            decisionHandler: { textInputDelegate, textInputDecisionInfo in
                guard let self = textInputDelegate.parentHandler as? Self else {
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
                    try self.decisionHandler(self, .init(currentText: currentText, textInputAction: textInputAction))
                    
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
                    self.resultHandler(self, .failure(textInputError))
                    return false
                    
                } catch {
                    return false
                }
            })
        self.textInputDelegate.parentHandler = self
    }
    
    public func configure(textField: UITextField) {
        textField.addAction(self.textFieldAction, for: .editingChanged)
        
        self.textInputDelegate.systemTextFieldDelegate = textField.delegate
        textField.delegate = self.textInputDelegate
    }
}

public struct NSKTextInputInfo {
    public let currentText: String
    public let textInputAction: NSKTextInputAction
}

public struct NSKTextInputInsert {
    public let position: String.Index
    public let replacementString: String
}

public enum NSKTextInputAction {
    case insert(NSKTextInputInsert)
    case delete(Range<String.Index>)
}

public struct NSKTextInputCustomText<NSKTextInputWarning> {
    public let text: String
    public let cursorPosition: String.Index
    public let warning: NSKTextInputWarning?
}

public enum NSKTextInputDecision<NSKTextInputWarning> {
    case approve(NSKTextInputWarning?)
    case customText(NSKTextInputCustomText<NSKTextInputWarning>)
}

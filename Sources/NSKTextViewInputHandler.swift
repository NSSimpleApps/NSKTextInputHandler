//
//  NSKTextViewInputHandler.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

@preconcurrency import UIKit

@MainActor
public final class NSKTextViewInputHandler<NSKTextInputWarning, NSKTextInputError: Error> {
    
    private let textViewDelegate: NSKTextViewDelegate
    private let textDidChangeBlock: @Sendable (Notification) -> Void
    
    public weak var parentHandler: AnyObject?
    
    private var deinitHandler: NSKDeinitHandler?
    private var textInputWarning: NSKTextInputWarning?
    
    public init(
        decisionHandler:
        @MainActor @Sendable @escaping (NSKTextViewInputHandler, NSKTextInputInfo) throws(NSKTextInputError) -> NSKTextInputDecision<NSKTextInputWarning>,
        
        resultHandler:
        @MainActor @Sendable @escaping (NSKTextViewInputHandler, Result<NSKTextInputCustomText<NSKTextInputWarning>, NSKTextInputError>) -> Void
    ) {
        
        self.textDidChangeBlock = { notification in
            guard let textView = notification.object as? UITextView else { return }
            
            Task { @MainActor in
                guard let textViewDelegate = textView.delegate as? NSKTextViewDelegate else { return }
                guard let self = textViewDelegate.parentHandler as? Self else { return }
                
                let textInputWarning = self.textInputWarning
                self.textInputWarning = nil
                
                let text = textView.text ?? ""
                let beginningOfDocument = textView.beginningOfDocument
                let selectedPosition = textView.selectedTextRange?.start ?? beginningOfDocument
                let offset = textView.offset(from: beginningOfDocument, to: selectedPosition)
                let cursorPosition = text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
                
                let textInputCustomText = NSKTextInputCustomText(
                    text: text,
                    cursorPosition: cursorPosition,
                    warning: textInputWarning
                )
                resultHandler(self, .success(textInputCustomText))
            }
        }
        
        self.textViewDelegate = .init(
            decisionHandler: { textViewDelegate, textViewDecisionInfo in
                guard let self = textViewDelegate.parentHandler as? Self else {
                    return false
                }
                
                let textView = textViewDecisionInfo.textView
                let range = textViewDecisionInfo.range
                let replacementString = textViewDecisionInfo.replacementString
                let currentText = textView.text ?? ""
                
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
                        
                        let delegate = textView.delegate
                        textView.delegate = nil
                        
                        Task {
                            textView.text = customText
                            
                            let selectedTextRange: UITextRange?
                            if let cursorPosition = textView.position(from: textView.beginningOfDocument, offset: offset) {
                                selectedTextRange = textView.textRange(from: cursorPosition, to: cursorPosition)
                            } else {
                                selectedTextRange = nil
                            }
                            
                            if let selectedTextRange {
                                textView.selectedTextRange = selectedTextRange
                            }
                            textView.delegate = delegate
                            NotificationCenter.default.post(
                                name: UITextView.textDidChangeNotification,
                                object: textView
                            )
                        }
                        
                        return false
                    }
                } catch let textInputError as NSKTextInputError {
                    resultHandler(self, .failure(textInputError))
                    return false
                    
                } catch {
                    return false
                }
            }
        )
        self.textViewDelegate.parentHandler = self
    }
    
    public func configure(textView: UITextView) {
        self.textViewDelegate.configure(textView: textView)
        
        let notificationCenter = NotificationCenter.default
        let token = notificationCenter.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: textView,
            queue: .main,
            using: self.textDidChangeBlock
        )
        
        let deinitHandler = NSKDeinitHandler(deinitBlock: {
            notificationCenter.removeObserver(token)
        })
        self.deinitHandler = deinitHandler
    }
}

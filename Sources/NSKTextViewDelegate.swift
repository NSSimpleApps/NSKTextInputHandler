//
//  NSKTextViewDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import UIKit

typealias NSKTextViewDecisionHandler = @MainActor @Sendable (NSKTextViewDelegate, NSKTextViewDecision) -> Bool

final class NSKTextViewDelegate: NSObject {
    
    weak var parentHandler: AnyObject?
    
    private let decisionHandler: NSKTextViewDecisionHandler
    private weak var textViewSystemDelegate: UITextViewDelegate?
    
    init(
        decisionHandler: @escaping NSKTextViewDecisionHandler
    ) {
        self.decisionHandler = decisionHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if self.respondsDecision(for: aSelector) || self.respondsDecisionV26(for: aSelector) {
            return self
        } else {
            return self.textViewSystemDelegate
        }
    }
    
    private func respondsDecision(
        for aSelector: Selector
    ) -> Bool {
        return aSelector == #selector(UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:))
    }
    
    private func respondsDecisionV26(
        for aSelector: Selector
    ) -> Bool {
        if #available(iOS 26.0, *) {
            return aSelector == #selector(UITextViewDelegate.textView(_:shouldChangeTextInRanges:replacementText:))
        } else {
            return false
        }
    }
    
    @MainActor
    func configure(
        textView: UITextView
    ) {
        self.textViewSystemDelegate = textView.delegate
        textView.delegate = self
    }
}

extension NSKTextViewDelegate: UITextViewDelegate {
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if range.location == 0, range.length == 0, text.isEmpty {
            return false
        }
        
        return self.decisionHandler(
            self,
            .init(
                textView: textView,
                range: range,
                replacementString: text
            )
        )
    }
    
    func textView(
        _ textView: UITextView,
        shouldChangeTextInRanges ranges: [NSValue],
        replacementText text: String
    ) -> Bool {
        guard let range = ranges.first?.rangeValue else { return false }
        
        return self.textView(
            textView,
            shouldChangeTextIn: range,
            replacementText: text
        )
    }
}

struct NSKTextViewDecision {
    
    let textView: UITextView
    let range: NSRange
    let replacementString: String
}

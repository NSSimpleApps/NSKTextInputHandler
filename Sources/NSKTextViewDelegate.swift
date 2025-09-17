//
//  NSKTextViewDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import UIKit

typealias NSKTextViewDecisionHandler = @MainActor @Sendable (NSKTextViewDelegate, NSKTextViewDecisionInfo) -> Bool

final class NSKTextViewDelegate: NSObject {
    private let decisionHandler: NSKTextViewDecisionHandler
    
    weak var parentHandler: AnyObject?
    private weak var textViewSystemDelegate: UITextViewDelegate?
    
    init(
        decisionHandler: @escaping NSKTextViewDecisionHandler
    ) {
        self.decisionHandler = decisionHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == #selector(UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:)) {
            return self
        } else {
            return self.textViewSystemDelegate
        }
    }
    
    @MainActor
    func configure(textView: UITextView) {
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
        return self.decisionHandler(self,
                                    .init(
                                        textView: textView,
                                        range: range,
                                        replacementString: text
                                    )
        )
    }
}

struct NSKTextViewDecisionInfo {
    let textView: UITextView
    let range: NSRange
    let replacementString: String
}

//
//  NSKTextViewDelegate.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import UIKit

typealias NSKTextViewDecisionHandler = @MainActor @Sendable (NSKTextViewDelegate, NSKTextViewDecisionInfo) -> Bool
typealias NSKTextViewResultHandler = @MainActor @Sendable (NSKTextViewDelegate, UITextView) -> Void

final class NSKTextViewDelegate: NSObject {
    private let decisionHandler: NSKTextViewDecisionHandler
    private let resultHandler: NSKTextViewResultHandler
    
    weak var parentHandler: AnyObject?
    private weak var textViewSystemDelegate: UITextViewDelegate?
    
    init(
        decisionHandler: @escaping NSKTextViewDecisionHandler,
        resultHandler: @escaping NSKTextViewResultHandler
    ) {
        self.decisionHandler = decisionHandler
        self.resultHandler = resultHandler
        super.init()
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if aSelector == #selector(UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:)) {
            return self
        } else {
            return self.textViewSystemDelegate
        }
        
        
//        if aSelector == #selector(UITextViewDelegate.textView(_:shouldChangeTextIn:replacementText:))
//            || aSelector == #selector(UITextViewDelegate.textViewDidChange(_:)) {
//            return self
//        } else {
//            return self.systemTextViewDelegate
//        }
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
        let result = self.decisionHandler(self, .init(textView: textView, range: range, replacementString: text))
        
        if result {
            textView.delegate = self.textViewSystemDelegate
            
            Task {
                textView.delegate = self
                self.resultHandler(self, textView)
            }
        }
        return result
    }
    
//    func textViewDidChange(_ textView: UITextView) {
//        print("AAAAAA", Date())
//        
//        textView.delegate = self.systemTextViewDelegate
//        //self.systemTextViewDelegate?.textViewDidChange?(textView)
//        
//        textView.delegate = nil
////        Task {
////            textView.delegate = self
////            self.resultHandler(self, textView)
////        }
//    }
}

struct NSKTextViewDecisionInfo {
    let textView: UITextView
    let range: NSRange
    let replacementString: String
}

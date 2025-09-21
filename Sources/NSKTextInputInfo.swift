//
//  NSKTextInputInfo.swift
//  NSKTextInputHandler
//
//  Created by user on 21.09.2025.
//

public struct NSKTextInputInsert {
    
    public let position: String.Index
    public let replacementString: String
}

public enum NSKTextInputAction {
    
    case insert(NSKTextInputInsert)
    case delete(Range<String.Index>)
}

public struct NSKTextInputInfo {
    
    public let currentText: String
    public let textInputAction: NSKTextInputAction
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

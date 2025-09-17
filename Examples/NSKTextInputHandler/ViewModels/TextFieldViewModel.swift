//
//  TextFieldViewModel.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import SwiftUI

struct MaskedTextFieldWarning {
    let warning: String
}

struct MaskedTextFieldError: Error {
    let reason: String
}

struct MaskedTextFieldSuggestion {
    let suggestion: String
    let color: Color
}

@MainActor
final class TextFieldViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var suggestion: MaskedTextFieldSuggestion?
    
    private let textFieldInputHandler: NSKTextFieldInputHandler<MaskedTextFieldWarning, MaskedTextFieldError>
    
    init(text: String, masker: MaskerProtocol) {
        let mastedText = masker.mask(string: text)
        
        self.text = mastedText
        
        self.textFieldInputHandler = .init(
            decisionHandler: { textFieldInputHandler, textInputInfo throws(MaskedTextFieldError) in
                let currentText = textInputInfo.currentText
                
                switch textInputInfo.textInputAction {
                case .insert(let maskedTextFieldInsert):
                    let replacementString = maskedTextFieldInsert.replacementString
                    let position = maskedTextFieldInsert.position
                    
                    do {
                        let maskerStringWithPosition = try masker.tryInsert(
                            into: currentText,
                            replacementString: replacementString,
                            at: position)
                        let newMaskedString = maskerStringWithPosition.string
                        let shouldApprove = maskerStringWithPosition.shouldApprove
                        
                        if shouldApprove {
                            return .approve(nil)
                        } else {
                            return .customText(.init(text: newMaskedString,
                                                     cursorPosition: maskerStringWithPosition.cursorPosition,
                                                     warning: .init(warning: "Поправка.")))
                        }
                    } catch let maskerError as MaskerError {
                        throw MaskedTextFieldError(reason: maskerError.reason)
                        
                    } catch {
                        fatalError()
                        #warning("Тупорылый компилятор.")
                    }
                    
                case .delete(let deleteRange):
                    do {
                        let maskerStringWithPosition = try masker.tryDelete(maskedString: currentText, in: deleteRange)
                        let newMaskedString = maskerStringWithPosition.string
                        let shouldApprove = maskerStringWithPosition.shouldApprove
                        
                        if shouldApprove {
                            return .approve(nil)
                        } else {
                            return .customText(.init(text: newMaskedString,
                                                     cursorPosition: maskerStringWithPosition.cursorPosition,
                                                     warning: .init(warning: "Поправка.")))
                        }
                    } catch let maskerError as MaskerError {
                        throw MaskedTextFieldError(reason: maskerError.reason)
                        
                    } catch {
                        fatalError()
                        #warning("Тупорылый компилятор.")
                    }
                }
            },
            resultHandler: { textFieldInputHandler, textInputCustomText in
                guard let self = textFieldInputHandler.parentHandler as? Self else { return }
                
                switch textInputCustomText {
                case .success(let textInputWarning):
                    if let warning = textInputWarning.warning {
                        self.suggestion = .init(suggestion: warning.warning, color: .yellow)
                    } else {
                        self.suggestion = nil
                    }
                    
                case .failure(let maskedTextFieldError):
                    self.suggestion = .init(suggestion: maskedTextFieldError.reason, color: .red)
                }
            })
        
        self.textFieldInputHandler.parentHandler = self
    }
    
    func configure(textField: UITextField) {
        self.textFieldInputHandler.configure(textField: textField)
    }
}

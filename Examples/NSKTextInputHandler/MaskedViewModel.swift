//
//  MaskedViewModel.swift
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
final class MaskedViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var suggestion: MaskedTextFieldSuggestion?
    
    #warning("Тупорылый компилятор.")
    private let textInputHandler: NSKTextInputHandler<MaskedTextFieldWarning, Error>
    
    init(text: String, masker: MaskerProtocol) {
        self.text = masker.mask(string: text)
        self.textInputHandler = .init(
            decisionHandler: { textInputHandler, textInputInfo in
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
            resultHandler: { textFieldDecisionHandler, textInputCustomText in
                guard let self = textFieldDecisionHandler.parentHandler as? Self else { return }
                
                switch textInputCustomText {
                case .success(let textInputWarning):
                    if let warning = textInputWarning.warning {
                        self.suggestion = .init(suggestion: warning.warning, color: .yellow)
                    } else {
                        self.suggestion = nil
                    }
                    
                case .failure(let maskedTextFieldError as MaskedTextFieldError):
                    self.suggestion = .init(suggestion: maskedTextFieldError.reason, color: .red)
                    
                default:
                    #warning("Тупорылый компилятор.")
                    break
                }
            })
        self.textInputHandler.parentHandler = self
    }
    
    func configure(textField: UITextField) {
        self.textInputHandler.configure(textField: textField)
    }
}

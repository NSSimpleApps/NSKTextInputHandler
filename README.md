NSKTextInputHandler
=================


```swift
import SwiftUI
import SwiftUIIntrospect

        let textInputHandler = .init(
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
                    break
                }
            })
        self.textInputHandler.parentHandler = self

struct MaskedTextField: View {
    @ObservedObject var maskedViewModel: MaskedViewModel
    
    var body: some View {
        TextField(
            "Placeholder",
            text: self.$maskedViewModel.text
        )
        .textFieldStyle(.roundedBorder)
        .introspect(
            .textField,
            on: .iOS(.v15, .v16, .v17, .v18),
            customize: { textField in
                self.maskedViewModel.configure(textField: textField)
            }
        )
    }
}
```

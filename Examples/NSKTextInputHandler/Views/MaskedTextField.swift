//
//  MaskedTextField.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import SwiftUI
import SwiftUIIntrospect

struct MaskedTextField: View {
    @ObservedObject var textFieldViewModel: TextFieldViewModel
    
    var body: some View {
        TextField(
            "Placeholder",
            text: self.$textFieldViewModel.text
        )
        .textFieldStyle(.roundedBorder)
        .introspect(
            .textField,
            on: .iOS(.v15, .v16, .v17, .v18, .v26),
            customize: { textField in
                self.textFieldViewModel.configure(textField: textField)
            }
        )
    }
}



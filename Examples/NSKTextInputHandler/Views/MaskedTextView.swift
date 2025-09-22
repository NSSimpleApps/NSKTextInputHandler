//
//  MaskedTextView.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import SwiftUI
import SwiftUIIntrospect

struct MaskedTextView: View {
    @ObservedObject var textViewViewModel: TextViewViewModel
    
    var body: some View {
        TextEditor(
            text: self.$textViewViewModel.text
        )
        .autocorrectionDisabled(true)
        .introspect(
            .textEditor,
            on: .iOS(.v15, .v16, .v17, .v18, .v26),
            customize: { textView in
                self.textViewViewModel.configure(textView: textView)
            }
        )
    }
}

//
//  TextFieldListView.swift
//  NSKTextInputHandler
//
//  Created by user on 29.08.2025.
//

import SwiftUI

struct TextFieldListView: View {
    
    @ObservedObject var phoneNumberViewModel: TextFieldViewModel
    
    var body: some View {
        List {
            Section {
                MaskedTextField(
                    textFieldViewModel: self.phoneNumberViewModel
                )
                .frame(maxWidth: .infinity)
            } header: {
                let suggestion = self.phoneNumberViewModel.suggestion
                let text = suggestion?.suggestion ?? " "
                let color = suggestion?.color ?? Color.clear
                
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(color)
                    .font(.caption2)
            } footer: {
                Text(self.phoneNumberViewModel.text)
            }
        }
    }
}

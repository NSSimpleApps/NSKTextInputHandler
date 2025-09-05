//
//  ContentView.swift
//  NSKTextInputHandler
//
//  Created by user on 29.08.2025.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var phoneNumberViewModel = MaskedViewModel(text: "", masker: PhoneNumberMasker())
    
    var body: some View {
        List {
            Section {
                MaskedTextField(maskedViewModel: self.phoneNumberViewModel)
                    .frame(maxWidth: .greatestFiniteMagnitude)
            } header: {
                if let suggestion = self.phoneNumberViewModel.suggestion {
                    Text(suggestion.suggestion)
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                        .foregroundStyle(suggestion.color)
                        .font(.caption2)
                }
            } footer: {
                Button("PRINT") {
                    print(self.phoneNumberViewModel.text)
                }
            }
        }
    }
}

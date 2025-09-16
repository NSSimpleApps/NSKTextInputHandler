//
//  TextViewListView.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import SwiftUI

struct TextViewListView: View {
    @ObservedObject var phoneNumberViewModel: TextViewViewModel
    
    var body: some View {
        List {
            Section {
                MaskedTextView(
                    textViewViewModel: self.phoneNumberViewModel
                )
                .frame(maxWidth: .infinity)
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

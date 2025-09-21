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
                let suggestion = self.phoneNumberViewModel.suggestion
                let text = suggestion?.suggestion ?? " "
                let color = suggestion?.color ?? Color.clear
                
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(color)
                    .font(.caption2)
            } footer: {
                VStack {
                    Text(self.phoneNumberViewModel.text)
                }
            }
        }
    }
}

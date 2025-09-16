//
//  ParentView.swift
//  NSKTextInputHandler
//
//  Created by user on 11.09.2025.
//

import SwiftUI

struct ParentView: View {
    @State private var selectedTab = 0
    
    @ObservedObject var phoneNumberSingleLineViewModel: TextFieldViewModel
    @ObservedObject var phoneNumberMultiLineViewModel: TextViewViewModel
    
    var body: some View {
        TabView(selection: self.$selectedTab) {
            TextFieldListView(
                phoneNumberViewModel: self.phoneNumberSingleLineViewModel
            )
            .tabItem {
                Label("TextField", systemImage: "list.dash")
            }
            .tag(0)
            
            TextViewListView(
                phoneNumberViewModel: self.phoneNumberMultiLineViewModel
            )
            .tabItem {
                Label("TextView", systemImage: "square.and.pencil")
            }
            .tag(1)
        }
    }
}

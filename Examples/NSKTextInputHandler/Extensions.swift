//
//  Extensions.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import Foundation

extension Character {
    var isNumber: Bool {
        let lowercased = self.lowercased()
        
        return "0" <= lowercased && lowercased <= "9"
    }
    
    var isCyrillic: Bool {
        let lowercased = self.lowercased()
        
        return ("а" <= lowercased && lowercased <= "я") || lowercased == "ё"
    }
    
    var isLatin: Bool {
        let lowercased = self.lowercased()
        
        return "a" <= lowercased && lowercased <= "z"
    }
}

extension String {
    func trimWS() -> Self {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Collection {
    var isNotEmpty: Bool {
        return self.isEmpty == false
    }
}

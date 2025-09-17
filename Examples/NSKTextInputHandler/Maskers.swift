//
//  Maskers.swift
//  NSKTextInputHandler
//
//  Created by user on 30.08.2025.
//

import Foundation

struct MaskerError: Error {
    let reason: String
}
struct MaskerString {
    let string: String
    let cursorPosition: String.Index
    let shouldApprove: Bool
}

protocol MaskerProtocol: Sendable {
    func mask(string: String) -> String
    
    func tryInsert(into maskedString: String, replacementString: String, at: String.Index) throws(MaskerError) -> MaskerString
    func tryDelete(maskedString: String, in range: Range<String.Index>) throws(MaskerError) -> MaskerString
}

final class PhoneNumberMasker: MaskerProtocol {
    func mask(string: String) -> String {
        let trimmedString = string.trimWS()
        let hasPlus = trimmedString.hasPrefix("+")
        var numberString = Substring(trimmedString.filter({ $0.isNumber }).prefix(11))
        var result = "+7-"
        
        if (hasPlus && numberString.first == "7") || numberString.first == "8" {
            numberString = numberString.dropFirst()
        }
        
        if case let firstGroup = numberString.prefix(3), firstGroup.isNotEmpty {
            result.append(String(firstGroup))
            numberString = numberString.dropFirst(firstGroup.count)
        } else {
            return result
        }
        
        if case let secondGroup = numberString.prefix(3), secondGroup.isNotEmpty {
            result.append("-" + secondGroup)
            numberString = numberString.dropFirst(secondGroup.count)
        } else {
            return result
        }
        
        if case let thirdGroup = numberString.prefix(2), thirdGroup.isNotEmpty {
            result.append("-" + thirdGroup)
            numberString = numberString.dropFirst(thirdGroup.count)
        } else {
            return result
        }
        
        if case let fouthGroup = numberString.prefix(2), fouthGroup.isNotEmpty {
            result.append("-" + fouthGroup)
        }
        
        return result
    }
    
    func tryInsert(
        into maskedString: String,
        replacementString: String,
        at position: String.Index
    ) throws(MaskerError) -> MaskerString {
            let startIndex = maskedString.startIndex
            
            if position == startIndex || position == maskedString.index(after: startIndex) {
                throw MaskerError(reason: "Код менять нельзя.")
            }
            
            if maskedString.count == 16, position == maskedString.endIndex {
                throw MaskerError(reason: "Больше цифр нельзя.")
            }
            
            if case let numberString = replacementString.filter({ $0.isNumber }), numberString.isNotEmpty {
                let initialStringCount = maskedString.count
                let numberCount = numberString.count
                
                var maskedString = maskedString
                maskedString.insert(contentsOf: numberString, at: position)
                
                let newMaskedString = self.mask(string: maskedString)
                
                if newMaskedString == maskedString {
                    return .init(
                        string: maskedString,
                        cursorPosition: maskedString.index(position, offsetBy: numberCount),
                        shouldApprove: true)
                } else {
                    var offset = newMaskedString.count - initialStringCount
                    if offset == 0 {
                        offset += numberCount
                    }
                    
                    return .init(
                        string: newMaskedString,
                        cursorPosition: newMaskedString.index(position, offsetBy: offset),
                        shouldApprove: false)
                }
            } else {
                throw MaskerError(reason: "Только цифры.")
            }
        }
    
    func tryDelete(
        maskedString: String,
        in range: Range<String.Index>
    ) throws(MaskerError) -> MaskerString {
        let startIndex = maskedString.startIndex
        let prefixRange = Range(uncheckedBounds: (startIndex, maskedString.index(startIndex, offsetBy: 2)))
        
        if prefixRange.overlaps(range) {
            throw MaskerError(reason: "Код удалять нельзя.")
        }
        var maskedString = maskedString
        maskedString.removeSubrange(range)
        let newMaskedString = self.mask(string: maskedString)
        
        if newMaskedString == maskedString {
            return .init(
                string: maskedString,
                cursorPosition: range.lowerBound,
                shouldApprove: true)
        } else {
            return .init(
                string: newMaskedString,
                cursorPosition: min(range.lowerBound, newMaskedString.endIndex),
                shouldApprove: false)
        }
    }
}

//
//  NSKDeinitHandler.swift
//  NSKTextInputHandler
//
//  Created by user on 17.09.2025.
//

final class NSKDeinitHandler {
    let deinitBlock: () -> Void
    
    init(deinitBlock: @escaping () -> Void) {
        self.deinitBlock = deinitBlock
    }
    
    deinit {
        self.deinitBlock()
    }
}

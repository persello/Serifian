//
//  AutocompleteCoordinator.swift
//  Serifian
//
//  Created by Riccardo Persello on 17/09/23.
//

import Foundation
import SwiftyTypst
import os

/// A class for interacting with `AutocompletePopup`.
class AutocompleteCoordinator {
    
    /// The actions that can be performed with keyboard presses.
    enum KeyboardAction {
        case previous
        case next
        case enter
    }
    
    static private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AutocompleteCoordinator")
    
    private var keyboardHandler: ((KeyboardAction) -> ())? = nil
    private var completionUpdateHandler: (([AutocompleteResult], String) -> ())? = nil
    private var selectionCallback: ((String) -> ())? = nil
    
    var latestCompletions: [AutocompleteResult] = []
    var latestSearchText: String = ""
    
    
    /// Perform the action bound to the "previous" key.
    func previous() {
        Self.logger.trace("Received previous command.")
        keyboardHandler?(.previous)
    }
    
    /// Perform the action bound to the "next" key.
    func next() {
        Self.logger.trace("Received next command.")
        keyboardHandler?(.next)
    }
    
    /// Perform the action bound to the "enter" key.
    func enter() {
        Self.logger.trace("Received enter command.")
        keyboardHandler?(.enter)
    }
    
    /// Update the completions and the search text.
    /// - Parameters:
    ///   - completions: completions to display.
    ///   - text: The text that was searched.
    func updateCompletions(_ completions: [AutocompleteResult], searching text: String) {
        Self.logger.trace(#"Updating \(completions.count) completions, searching "\#(text)"."#)
        self.latestCompletions = completions
        self.latestSearchText = text
        self.completionUpdateHandler?(completions, text)
    }
    
    
    /// Select a completion.
    /// - Parameter completion: The current completion.
    func select(_ completion: AutocompleteResult) {
        Self.logger.info(#"Selecting completion "\#(completion.label)"."#)
        self.selectionCallback?(completion.completion)
    }
    
    /// Attach a keyboard handler.
    ///
    /// This handler is called when an action key is pressed.
    /// - Parameter handler: The handler to attach.
    func attachKeyboardHandler(_ handler: @escaping (KeyboardAction) -> ()) {
        Self.logger.info("Keyboard handler attached.")
        self.keyboardHandler = handler
    }
    
    /// Attach a completion update handler.
    ///
    /// This handler is called when the completions are updated.
    /// - Parameter handler: The handler to attach.
    func attachCompletionUpdateHandler(_ handler: @escaping ([AutocompleteResult], String) -> ()) {
        Self.logger.info("Completion update handler attached.")
        self.completionUpdateHandler = handler
    }
    
    
    /// Attach a selection callback.
    ///
    /// The callback is called when the user selects a completion.
    /// - Parameter callback: The callback to attach.
    func onSelection(_ callback: @escaping (String) -> ()) {
        Self.logger.info("Selection callback attached.")
        self.selectionCallback = callback
    }
}

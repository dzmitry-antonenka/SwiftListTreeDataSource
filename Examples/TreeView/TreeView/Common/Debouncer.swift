//
//  Debouncer.swift
//  test
//
//  Created by Dzmitry Antonenka on 24/04/21.
//

import Foundation

class Debouncer {

    let delay: Double
    private var timer: Timer?

    /// Initalize the Debouncer
    /// - Parameter delay: the delay in seconds
    init(delay: Double = 0.5) {
        self.delay = delay
    }

    /// Calls a function after a certain period of time
    /// if the function is called again within the period of time
    /// then the call of the function is again delayed and called after the period of time
    ///
    /// This is used to delay a function call, e.g. when the user is still in the middle of typing.
    /// After he has finished typing (a certain amount of time has passed) then the function
    /// (e.g. a search query to the backend) is executed (but not while he is still typing).
    ///
    /// - Parameter completion: the closure to be called after the delay
    func debounce(completion: @escaping (() -> Void)) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in completion() }
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An extension that provides observable objects for the user's defaults database.
*/

public extension UserDefaults {
    /// An `ObservableObject` for a `UserDefaults` property that is KVO observable.
    /// For a `UserDefaults` property to be KVO observable, the following must be true:
    /// 1) The property name must match the `UserDefaults` key
    /// 2) The property must be marked `@objc dynamic`
    class ObservableProperty<Value: Equatable>: ObservableObject {
        private var observedDefaults: UserDefaults
        private let keyPath: WritableKeyPath<UserDefaults, Value>
        private var observation: NSKeyValueObservation?

        @Published public var value: Value {
            didSet {
                if value != oldValue {
                    observedDefaults[keyPath: keyPath] = value
                }
            }
        }

        /// Constructs a `UserDefaults.ObservableProperty`
        /// - Parameters:
        ///   - observedDefaults: instance of `UserDefaults` to observe
        ///   - keyPath: keyPath to the KVO observable property on `UserDefaults` to observe
        ///   - defaultValue: a default value to use if the new observed value is nil
        public init(_ observedDefaults: UserDefaults, keyPath: WritableKeyPath<UserDefaults, Value>, defaultValue: Value) {
            self.observedDefaults = observedDefaults
            self.keyPath = keyPath
            value = observedDefaults[keyPath: keyPath]
            observation = observedDefaults.observe(keyPath, options: [.new]) { [weak self] _, change in
                self?.value = change.newValue ?? defaultValue
            }
        }
    }
}

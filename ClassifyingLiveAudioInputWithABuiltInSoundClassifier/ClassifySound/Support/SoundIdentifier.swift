/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A structure that describes a sound suitable for displaying to a user.
*/

import Foundation

/// A sound that the app monitors.
struct SoundIdentifier: Hashable {
    /// An internal name that identifies a sound classification.
    var labelName: String

    /// A name suitable for displaying to a user.
    var displayName: String

    /// Creates a sound identifier using an internal sound classification name. This method generates a
    /// name suitable for displaying.
    ///
    /// - Parameter labelName: The name of a label the built-in sound classifier emits.
    init(labelName: String) {
        self.labelName = labelName
        self.displayName = SoundIdentifier.displayNameForLabel(labelName)
    }

    /// Converts a sound classification label to a name suitable for displaying.
    ///
    /// - Parameter label: A sound classification name that the sound classifier provides.
    ///
    /// - Returns: A name suitable for displaying to a user.
    static func displayNameForLabel(_ label: String) -> String {
        let localizationTable = "SoundNames"
        let unlocalized = label.replacingOccurrences(of: "_", with: " ").capitalized
        return Bundle.main.localizedString(forKey: unlocalized,
                                        value: unlocalized,
                                        table: localizationTable)
    }
}

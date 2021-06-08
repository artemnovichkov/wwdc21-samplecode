/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Text-related accessibility examples.
*/

import SwiftUI

/// Examples of making Text accessible using SwiftUI.
struct TextExample: View {
    var body: some View {
        LabeledExample("Text Accessibility") {
            Text("This text will have a different label for Accessibility")
                .accessibilityLabel("Accessibility Label")

            VStack(alignment: .leading) {
                Text("Stacked Multiple Line Text Line 1")
                Text("This is on another line")
                Text("This will be a single Accessibility element.")
                Text("Because of the `.combine` modifier.")
            }
            .accessibilityElement(children: .combine)

            Text("This Text will have both an Label and Value for Accessibility")
                // Prefer `accessibilityLabel` for aspects of accessibility
                // elements that identify the element to the user,
                // such as the name of the setting being changed by a switch control.
                .accessibilityLabel("Text Label")
                // Prefer `accessibilityValue` for aspects of accessibility
                // elements that can change, such as the current state of
                // controls, like whether a switch is currently on or off.
                .accessibilityValue("Text Value")
        }

        LabeledExample("Text with VoiceOver Customization") {
            Text("This text will spell out characters")
                .speechSpellsOutCharacters()

            Text("The text will be spoken at a high pitch")
                .speechAdjustedPitch(2)

            Text("This text will, always, completely spell out punctuation!")
                .speechAlwaysIncludesPunctuation()

            Text("This text will be spoken behind existing speech in VoiceOver")
                .speechAnnouncementsQueued(true)
        }

        LabeledExample("Customizing Pronunciation") {
            // Use speechPhoneticRepresentation` to specify pronunciation
            // of the text by VoiceOver in IPA notation.
            Text("Record").speechPhoneticRepresentation("ɹɪˈkɔɹd")
            Text("Record").speechPhoneticRepresentation("ˈɹɛkɚd")
        }

        // Use accessibilityTextContentType to specify what kind of content your
        // text includes, to allow VoiceOver to better interact with it.
        LabeledExample("Text Content Types") {
            Text("this_text_will_be_treated_as_source_code")
                .accessibilityTextContentType(.sourceCode)

            Text("This text will be treated as if it was in a Word Processing document.")
                .accessibilityTextContentType(.wordProcessing)
        }

        // Use the accessibilityHeading modifier or the isHeader trait to mark
        // headings in your text. You can use up to six levels of headings
        // which can be navigated separately.
        LabeledExample("Headings") {
            Text("This will be a standard heading")
                .bold()
                .accessibilityHeading(.unspecified)
            Text("This will be a level-one heading")
                .italic()
                .accessibilityHeading(.h1)
            Text("This will be a level-two heading")
                .underline()
                .accessibilityHeading(.h2)
            Text("This will be another a standard heading")
                .bold()
                .accessibilityHeading(.unspecified)
            Text("This will be a third standard heading")
                .bold()
                .accessibilityAddTraits(.isHeader)
        }
    }
}

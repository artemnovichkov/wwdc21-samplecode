/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that allows a user to select which sounds the system monitors when
performing sound classification.
*/

import SwiftUI

/// A view for selecting sounds to monitor.
struct SetupMonitoredSoundsView: View {
    /// A closure that queries the list of recognized sounds.
    ///
    /// The app uses the results of this closure to populate the `soundOptions` state variable. This
    /// closure may throw an error so the user can select an option to run it again.
    let querySoundOptions: () throws -> Set<SoundIdentifier>

    /// A message to display when `querySoundOptions` throws an error.
    @State var querySoundsErrorMessage: String?

    /// A list of possible sounds that a user selects in the app.
    @State var soundOptions: Set<SoundIdentifier>

    /// A search string the app uses to filter the available sound options. The app displays all the sound
    /// options when empty.
    @State var soundSearchString = ""

    /// A binding to the set of sounds the app monitors when starting sound classification.
    @Binding var selectedSounds: Set<SoundIdentifier>

    /// An action the app executes upon completing the setup.
    ///
    /// The app hides this view upon completion, so this action needs to perform any changes necessary to
    /// operate the app.
    var doneAction: () -> Void

    init(querySoundOptions: @escaping () throws -> Set<SoundIdentifier>,
         selectedSounds: Binding<Set<SoundIdentifier>>,
         doneAction: @escaping () -> Void) {
        self.querySoundOptions = querySoundOptions
        self._selectedSounds = selectedSounds
        self.doneAction = doneAction

        let soundOptions: Set<SoundIdentifier>
        let querySoundsErrorMessage: String?
        do {
            soundOptions = try querySoundOptions()
            querySoundsErrorMessage = nil
        } catch {
            soundOptions = Set<SoundIdentifier>()
            querySoundsErrorMessage = "\(error)"
        }

        _soundOptions = State(initialValue: soundOptions)
        _querySoundsErrorMessage = State(initialValue: querySoundsErrorMessage)
    }

    /// Searches the provided sounds for those that satisfy the search string.
    ///
    /// - Parameters:
    ///   - sounds: The set of sounds to search through.
    ///   - string: The string to search for within the display names of the provided sounds. The
    ///   method returns the sounds that contain this string, ignoring case. If the string is empty, the method
    ///   returns all the available sounds.
    ///
    /// - Returns: The set of sounds that satisfy the provided search string.
    func search(sounds: Set<SoundIdentifier>,
                for string: String) -> Set<SoundIdentifier> {
        let result: Set<SoundIdentifier>
        if string == "" {
            result = sounds
        } else {
            result = sounds.filter {
                $0.displayName.lowercased().contains(string.lowercased())
            }
        }
        return result
    }

    /// A list of all sounds the app displays for user selection.
    ///
    /// The first item in the option pair identifies the sound to display. The second item indicates whether the
    /// user enables it. The app lists options in the order in which they appear in the selection UI.
    var displayedSoundOptions: [(SoundIdentifier, Bool)] {
        let optionsAfterSearch = search(sounds: soundOptions,
                                        for: soundSearchString)
        let optionsSorted = [SoundIdentifier](optionsAfterSearch).sorted(by: { $0.displayName < $1.displayName })
        return optionsSorted.map {
            ($0, selectedSounds.contains($0))
        }
    }

    /// Toggles whether an object is a member of a set.
    ///
    /// - Parameters:
    ///   - member: The item to add or remove from the target set.
    ///   - targetSet: The set to update.
    static func toggleMembership<T>(member: T, set targetSet: inout Set<T>) {
        if targetSet.contains(member) {
            targetSet.remove(member)
        } else {
            targetSet.insert(member)
        }
    }

    /// A view that displays the content above the list of sound options.
    ///
    /// - Returns: This view contains instructions for the setup page, and buttons for selecting sounds
    ///   and dismissing the view.
    var headerContent: some View {
        VStack {
            HStack {
                Spacer()
                Button("Done", action: doneAction).padding()
            }
            Text("Select Labels to Detect").font(.title).frame(alignment: .leading)
            HStack {
                Button("Select All", action: { selectedSounds.formUnion(soundOptions) }).padding()
                Button("Clear All", action: { selectedSounds.removeAll() }).padding()
            }.padding()
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search", text: $soundSearchString)
                Button(action: { soundSearchString = "" }) {
                    Image(systemName: "x.circle.fill")
                      .foregroundColor(Color.gray)
                      .opacity(soundSearchString == "" ? 0.0 : 1.0)
                }
            }.padding()
        }
    }

    /// A view that displays a list of sounds the system detects.
    ///
    /// - Returns: A view that contains the available sounds with their selection status.
    var soundOptionsList: some View {
        List {
            ForEach(displayedSoundOptions, id: \.0) { classAndSelectionStatus in
                Button(action: { SetupMonitoredSoundsView.toggleMembership(member: classAndSelectionStatus.0, set: &selectedSounds) }) {
                    HStack {
                        Image(systemName: selectedSounds.contains(classAndSelectionStatus.0) ? "checkmark.circle.fill" : "circle")
                          .foregroundColor(Color.blue)
                        Text(classAndSelectionStatus.0.displayName).frame(alignment: .leading)
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            VStack {
                headerContent
                soundOptionsList
            }.blur(radius: querySoundsErrorMessage == nil ? 0.0 : 10.0)
             .disabled(querySoundsErrorMessage != nil)

            VStack {
                Text("Error: failed to query recognized sounds").multilineTextAlignment(.center).padding()
                Text(querySoundsErrorMessage ?? "").multilineTextAlignment(.center).padding()
                Button("Retry",
                       action: {
                           do {
                               soundOptions = try querySoundOptions()
                               querySoundsErrorMessage = nil
                           } catch {
                               querySoundsErrorMessage = "\(error)"
                           }
                       })
            }.opacity(querySoundsErrorMessage == nil ? 0.0 : 1.0)
             .disabled(querySoundsErrorMessage == nil)
        }
    }
}

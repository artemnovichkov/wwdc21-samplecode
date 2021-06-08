/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Accessibility Focus examples.
*/

import SwiftUI

/// A model that stores a list of notifications for use in the focus example code.
private struct Model {
    var notifications: [Notification]

    init() {
        // Fill the model with fake test data.
        notifications = [
            Notification(title: "First Notification", subtitle: "First Subtitle", id: UUID()),
            Notification(title: "Second Notification", subtitle: "Second Subtitle", id: UUID()),
            Notification(title: "Third Notification", subtitle: "Third Subtitle", id: UUID())
        ]
    }
}

/// A model describing a notification to show to the user.
private struct Notification: Identifiable {
    var title: String
    var subtitle: String
    var id: UUID
}

/// Examples of getting and setting assistive technology focus in SwiftUI
/// Track Accessibility focus state in several different ways.
struct FocusExample: View {
    // Track whether the top-level title is focused. This enables
    // reading this state, and programmatically focusing the top-level title
    // specifically.
    // This tracks focus of any assistive technology.
    @AccessibilityFocusState var isTopLevelTitleFocused: Bool

    // Track which notification's title element, if any, is focused.
    // This enables detection of whether VoiceOver is focused on a particular
    // notification's title element, as well as moving focus to that element
    // programmatically.
    // This tracks focus of any assistive technology.
    @AccessibilityFocusState var focusedNotificationTitle: UUID?

    // Track which notification's overall container element is focused.
    // On macOS, this is non-nil only when a container element is focused,
    // becase macOS focuses on containers generally. On iOS, this turns
    // non-nil if any of the container's children are focused.
    // This tracks focus of any assistive technology.
    @AccessibilityFocusState var focusedNotification: UUID?

    // Track the focus in the same way as above, but specifically for Switch Control.
    @AccessibilityFocusState(for: .switchControl) var switchControlFocusedNotification: UUID?

    private var model = Model()

    var body: some View {
        VStack {
            Text("Notifications").font(.title)
                // Associate the `isTopLevelTitleFocused` binding with this
                // particular accessibility element.
                .accessibilityFocused($isTopLevelTitleFocused)
                // Read accessibility focus, turning the color of this text
                // red when an assistive technology is focused on the title of this notification.
                .foregroundColor(isTopLevelTitleFocused ? Color.red : Color.black)

            ForEach(model.notifications) { notification in
                HStack {
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .font(.title3)
                            // Associate this `focusedNotificationTitle` binding
                            // with this particular element, and this specific value
                            // of the bound property.
                            .accessibilityFocused($focusedNotificationTitle, equals: notification.id)

                            // Read accessibility focus, turning the color of this text
                            // red when an assistive technology is focused specifically
                            // on the title of this notification.
                            .foregroundColor(focusedNotificationTitle == notification.id ? Color.red : Color.black)
                        Text(notification.subtitle)
                            .font(.caption)
                    }

                    Spacer()
                }
                // Make a new accessibility element (container) to separately
                // track focus for. Give it a label so macOS can land on it.
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Notification \(notification.title) \(notification.subtitle)")

                // Associate the `focusedNotification` binding
                // with this particular element, and this specific value
                // of the bound property. On iOS, because this is a container,
                // the binding triggers for all the element's children.
                .accessibilityFocused($focusedNotification, equals: notification.id)

                // Do the same, but for `switchControlFocusedNotification`, which tracks
                // focus of Switch Control specifically.
                .accessibilityFocused($switchControlFocusedNotification, equals: notification.id)
                .padding()

                // Change color when the notification container is focused
                // (on macOS) or any children of the notification container are
                // focused (on iOS).
                // Change thickness when Switch Control specifically is focused on this container
                // or a child of the container (on iOS).
                .border(
                    focusedNotification == notification.id ? Color.red : Color.gray,
                    width: switchControlFocusedNotification == notification.id ? 3 : 1
                )
            }
        }
        .padding()
        .border(Color.black, width: 2)

        Button("Focus Top Level Title") {
            // Set the value for this binding, which causes assistive technology
            // focus to move if a technology like VoiceOver is running and
            // focused on the app.
            isTopLevelTitleFocused = true
        }

        Button("Focus Second Notification Title") {
            guard model.notifications.count > 1 else {
                return
            }
            
            let secondNotification = model.notifications[1]

            // Set the binding, causing assistive technology to focus
            // specifically on the title of the second notification.
            focusedNotificationTitle = secondNotification.id
        }

        Button("Focus Third Notification") {
            guard model.notifications.count > 2 else {
                return
            }
            let thirdNotification = model.notifications[2]

            // Set the binding, causing assistive technologies to focus the
            // third notification's container.
            // On iOS, this focuses the first child
            // of the container, which is the title.
            focusedNotification = thirdNotification.id
        }
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ForEach accessibility examples.
*/

import SwiftUI

/// Examples of using dynamically-generated stacks and lists
/// in an accessible way.
struct ForEachExample: View {
    @State private var activities: [Activity] = [
        Activity(
            id: 0,
            username: "@annejohnson1",
            caption: "Anne Johnson",
            content: "Status Update"
        ),
        Activity(
            id: 1,
            username: "@meichen3",
            caption: "Mei Chen",
            content: "Status Update"
        )
    ]

    var body: some View {
        VStack {
            ForEach(activities) { activity in
                ActivityCell(activity: activity)
            }
        }
        .padding()
    }

    private struct Activity: Identifiable {
        var id: Int
        var username: String
        var caption: String
        var content: String
    }

    private struct ActivityCell: View {
        var activity: Activity
        
        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "person")
                    VStack(alignment: .leading) {
                        Text(activity.username)
                            .font(.subheadline)
                        Text(activity.caption)
                            .font(.caption)
                    }
                }

                Divider()

                Text(activity.content)

                HStack {
                    let buttonBackground = Circle().foregroundColor(Color.blue)
                    let padding: CGFloat = 4

                    Button {} label: {
                        Image(systemName: "hand.thumbsup")
                    }
                    .buttonStyle(.plain)
                    .padding(padding)
                    .background { buttonBackground }

                    Button {} label: {
                        Image(systemName: "bubble.left")
                    }
                    .buttonStyle(.plain)
                    .padding(padding)
                    .background { buttonBackground }
                }
                .symbolVariant(.fill)
            }
            .foregroundColor(Color.white)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(Color(white: 0.2))
            }
            // The combine value merges accessibility properties, turning
            // Buttons into custom actions. Note that some labels
            // and traits are ignored. For example, the label
            // from the `Image` and its traits are ignored since
            // other elements provide a label.
            .accessibilityElement(children: .combine)
        }
    }
}

struct ForEachExample_Previews: PreviewProvider {
    static var previews: some View {
        ForEachExample()
    }
}

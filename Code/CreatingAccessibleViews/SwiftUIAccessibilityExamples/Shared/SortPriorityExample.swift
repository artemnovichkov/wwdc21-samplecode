/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sort priority accessibility examples.
*/

import SwiftUI

/// Examples of using `sortPriority` to improve navigation order.
struct SortPriorityExample: View {
    var body: some View {
        VStack {
            // Default sort order is from top left to bottom right.
            // Elements with a higher sort priority are ordered first,
            // whereas a lower sort priority is ordered last.

            Text("Default sort order")

            Text("Sort priority 1 (Ordered First)")
                // Set the priority to 1 to order first.
                .accessibilitySortPriority(1)

            Text("Sort priority -1 (Ordered Last)")
                // Set the priority to -1 to order last.
                .accessibilitySortPriority(-1)

            Spacer().frame(height: 20)

            // Content aligned in horizontally in a row is
            // navigated sequentially before moving to
            // the next row.
            Row()
            Row()
            Row()

            Spacer().frame(height: 20)

            // Content aligned vertically in a column requires
            // an accessibility container for each column. This way
            // all elements in the column are navigated to before
            // moving to the next column.
            HStack(spacing: 10) {
                Column()
                    .accessibilityElement(children: .contain)
                Column()
                    .accessibilityElement(children: .contain)
                Column()
                    .accessibilityElement(children: .contain)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private struct Row: View {
        var body: some View {
            HStack {
                Text("Row Label")
                Spacer()
                Text("Row Value")
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: defaultCornerRadius)
                    .stroke(Color.gray)
            }
        }
    }

    private struct Column: View {
        var body: some View {
            VStack {
                Text("Column")
                Spacer().frame(height: 15)
                Text("Label")
                Text("Value")
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 5)
            .background {
                RoundedRectangle(cornerRadius: defaultCornerRadius)
                    .stroke(Color.gray)
            }
        }
    }
}

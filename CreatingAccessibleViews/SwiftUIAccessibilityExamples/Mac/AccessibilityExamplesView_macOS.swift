/*
See LICENSE folder for this sample’s licensing information.

Abstract:
macOS accessibility examples view.
*/

import SwiftUI

/// The contents view for a specific example.
private struct ExampleView: View {
    private var example: Example

    init(_ example: Example) {
        self.example = example
    }

    @ViewBuilder
    var innerExampleView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                example.view
                    .padding(.all, example.wantsPadding ? 8 : 0)
            }
            Spacer()
        }
    }

    var body: some View {
        if example.wantsScrollView {
            ScrollView {
                innerExampleView
            }
        } else {
            VStack {
                innerExampleView
                Spacer()
            }
        }
    }
}

/// The top-level view for all examples.
struct ExamplesView: View {
    var body: some View {
        NavigationView {
            List(examples, id: \.name) { example in
                NavigationLink(example.name) {
                    ExampleView(example)
                }
            }
            Text("No Content")
        }
    }
}

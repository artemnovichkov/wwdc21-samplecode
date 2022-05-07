/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Constructs the view that introduces the app.
*/

import SwiftUI

/// Presents the introduction screen for the app.
struct IntroViewPage: View {
    /// Optional binding to dismiss this view, if needed.
    private var isPresented: Binding<Bool>?
    /// Determines if the last page is being presented to show a button to dismiss the view.
    private var isFinalPage: Bool
    /// An array of strings to create Text Views from.
    private var textStrings: [String]

    init(isPresented: Binding<Bool>? = nil,
         isFinalPage: Bool = false,
         textStrings: String ...) {
        self.isPresented = isPresented
        self.isFinalPage = isFinalPage
        self.textStrings = textStrings
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            // Go through each string in the array and build a separate Text
            // View for each.
            ForEach(textStrings, id: \.self) { text in
                Text(text)
                    .font(.body)
                    .padding(.vertical, 8)
            }

            Spacer()

            // Only present the dismiss button if this is the final page.
            if isFinalPage {
                Button("Finish", action: {
                    self.isPresented?.wrappedValue.toggle()
                })
                    .buttonStyle(CustomButtonStyle())
                    .frame(width: 300)
                    .padding()
            }

            Spacer()
        }
    }
}

/// Constructs the Intro View that presents when the app launches.
struct IntroView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 32) {
                        Text("Welcome to the Large Text Challenge")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                            .frame(alignment: .center)

                        Spacer()

                        HStack(spacing: 0) {
                            Image(systemName: "hand.tap.fill")
                                .renderingMode(.original)
                                .foregroundColor(Color.blue)
                                .font(.title)
                                .frame(width: geometry.size.width * 0.20)
                            VStack {
                                Text("Tap Your Way to Victory!")
                                    .fontWeight(.bold)
                                Text("""
        Tap the view that needs to be changed. The view will present properties that can be changed.
        Modify any properties of that view to help give an accessible UI at larger text sizes!
        """)
                            }
                            .frame(width: geometry.size.width * 0.80)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "textformat.size")
                                .renderingMode(.original)
                                .foregroundColor(Color.blue)
                                .font(.title)
                                .frame(width: geometry.size.width * 0.20)
                            VStack {
                                Text("Change Text Size on the Fly!")
                                    .fontWeight(.bold)
                                Text("""
        To dynamically change the text size, it may be useful to add the Text Size Control Center Module. To add it:
        • Navigate to Settings
        • Open Control Center
        • Add the Text Size module
        """)
                            }
                            .frame(width: geometry.size.width * 0.80)
                        }
                    }
                }
            }

            Spacer()

            Button("Continue", action: {
                self.isPresented.toggle()
            })
            .buttonStyle(CustomButtonStyle())
        }
        .padding()
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView(isPresented: .constant(true))
    }
}

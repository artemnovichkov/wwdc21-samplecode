/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view model representing the numbers pad when answering a question.
*/

import SwiftUI

struct NumberPadView: View {
    let range: ClosedRange<Int>
    fileprivate var onSelect: ((Int) -> Void)?
    
    init(range: ClosedRange<Int>) {
        self.range = range
    }
    
    var body: some View {
        ZStack {
            HStack(alignment: .center, spacing: 15) {
                ForEach(range, id: \.self) { index in
                    Button(action: {
                        self.onSelect?(index)
                    }, label: {
                        Image.questionButtonImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120, alignment: .center)
                            .overlay(
                                Text("\(index)")
                                    .foregroundColor(Color.white)
                                    .font(.system(size: 50, weight: .black, design: .rounded))
                            )
                    })
                }
            }
            .padding(.all, 20)
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight)).cornerRadius(25)
            )
        }
    }
}

extension NumberPadView {
    
    func onSelect(_ handler: @escaping (Int) -> Void) -> NumberPadView {
        var view = self
        view.onSelect = handler
        return view
    }
}

struct NumberPadView_Previews: PreviewProvider {
    static var previews: some View {
        NumberPadView(range: 1...5)
            .previewInterfaceOrientation(.landscapeRight)
    }
}

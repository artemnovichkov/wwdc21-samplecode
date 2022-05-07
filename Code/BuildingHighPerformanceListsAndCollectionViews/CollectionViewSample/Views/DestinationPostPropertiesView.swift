/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The destination post properties view.
*/
import UIKit

class DestinationPostPropertiesView: UIView {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let likeCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .secondarySystemBackground
        
        titleLabel.font = Appearance.titleFont
        titleLabel.textColor = UIColor.label
        titleLabel.adjustsFontForContentSizeCategory = true
        
        subtitleLabel.font = Appearance.subtitleFont
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.adjustsFontForContentSizeCategory = true
                                       
        likeCountLabel.font = Appearance.likeCountFont
        likeCountLabel.textColor = .secondaryLabel
        likeCountLabel.adjustsFontForContentSizeCategory = true
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(likeCountLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var needsRelayout: Bool = true
    var post: DestinationPost? {
        didSet {
            let header = self.headerValues(for: post)
            if header != self.headerValues(for: oldValue) {
                titleLabel.text = header.title
                subtitleLabel.text = header.subtitle
                // Only invalidate our current size
                // when the post changes.
                needsRelayout = true
            }
            
            let numberOfLikes = post?.numberOfLikes ?? 0
            likeCountLabel.text = "\(numberOfLikes) likes"
        }
    }
    
    private var previousBounds: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        
        needsRelayout = false
        var layoutBounds = bounds.inset(by: layoutMargins)
        
        // Fills the remaining height with the `sizeThatFits`
        // the `view`
        func layout(view: UIView) {
            let fittingSize = CGSize(width: layoutBounds.width, height: UILabel.noIntrinsicMetric)
            let size = view.sizeThatFits(fittingSize)
            (view.frame, layoutBounds) = layoutBounds.divided(atDistance: size.height, from: .minYEdge)
        }
        
        layout(view: titleLabel)
        
        if subtitleLabel.text != nil {
            layout(view: subtitleLabel)
        }
        
        if likeCountLabel.text != nil {
            layout(view: likeCountLabel)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let layoutMargin = self.layoutMargins
        let fittingSize = CGSize(width: size.width - layoutMargins.left - layoutMargins.right, height: UILabel.noIntrinsicMetric)

        var height = layoutMargin.top + layoutMargin.bottom
        height += titleLabel.sizeThatFits(fittingSize).height
        if subtitleLabel.text != nil {
            height += subtitleLabel.sizeThatFits(fittingSize).height
        }
        if likeCountLabel.text != nil {
            height += likeCountLabel.sizeThatFits(fittingSize).height
        }
        
        return CGSize(width: size.width, height: height)
    }
    
    private func headerValues(for post: DestinationPost?) -> (title: String?, subtitle: String?) {
        guard let post = post else { return (nil, nil) }
        if let subregion = post.subregion {
            return (subregion, post.region)
        } else {
            return (post.region, nil)
        }
    }
}


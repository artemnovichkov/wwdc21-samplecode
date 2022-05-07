/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This MKAnnotationView subclass displays points of interest within a venue using a point and a label.
*/

import MapKit

class LabelAnnotationView: MKAnnotationView {
    
    var label: UILabel
    var point: UIView
    
    override var annotation: MKAnnotation? {
        didSet {
            // Always update the label title to ensure it represents the current annotation since annotation views are reused by the map view.
            if let title = annotation?.title {
                label.text = title
            } else {
                label.text = nil
            }
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        label = UILabel(frame: .zero)
        point = UIView(frame: .zero)
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        addSubview(label)
        
        // Set the label constriants.
        label.translatesAutoresizingMaskIntoConstraints = false
        label.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        let radius: CGFloat = 5.0
        point.layer.cornerRadius = radius
        point.layer.borderWidth = 1.0
        point.layer.borderColor = UIColor(named: "AnnotationBorder")?.cgColor
        self.addSubview(point)
        
        // Set the point constraints so that it is centered and above label.
        point.translatesAutoresizingMaskIntoConstraints = false
        point.widthAnchor.constraint(equalToConstant: radius * 2).isActive = true
        point.heightAnchor.constraint(equalToConstant: radius * 2).isActive = true
        point.topAnchor.constraint(equalTo: topAnchor).isActive = true
        point.centerXAnchor.constraint(equalTo: label.centerXAnchor).isActive = true
        point.bottomAnchor.constraint(equalTo: label.topAnchor).isActive = true
        
        // Adjust the view's center offset so that it is anchored on the point. Shift the callout view to appear right above the point.
        centerOffset = CGPoint(x: 0, y: label.font.lineHeight / 2 )
        calloutOffset = CGPoint(x: 0, y: -radius)
        canShowCallout = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var backgroundColor: UIColor? {
        get {
            return point.backgroundColor
        }
        set {
            point.backgroundColor = newValue
        }
    }
}

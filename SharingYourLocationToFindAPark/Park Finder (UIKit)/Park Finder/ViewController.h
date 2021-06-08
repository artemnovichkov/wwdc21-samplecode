/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view controller that illustrates a use case of the CLLocationButton.
*/

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocationUI/CoreLocationUI.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

extern const float BUTTON_SHADOW_OPACITY;
extern const float BUTTON_HEIGHT;
extern const float BUTTON_WIDTH;
extern const float BUTTON_ALPHA;
extern const float BUTTON_BOTTOM_MARGIN;

@interface ViewController : UIViewController<CLLocationManagerDelegate, MKMapViewDelegate> {
    CLLocationManager *locationManager;
}
@property (nonatomic, retain) CLLocationButton *locationButton;
@property (nonatomic, retain) MKMapView *mapview;
@end

NS_ASSUME_NONNULL_END

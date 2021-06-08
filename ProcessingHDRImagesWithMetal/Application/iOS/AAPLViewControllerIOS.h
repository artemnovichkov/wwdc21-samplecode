/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for the iOS view controller.
*/

@import UIKit;

@interface AAPLViewControllerIOS : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>
// For menu bar interaction
@property (nonatomic) BOOL isUIDisplayed;
@end


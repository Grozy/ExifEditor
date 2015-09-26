//
//  ViewController.h
//  Exif Editor
//
//  Created by S Park on 9/11/15.
//  Copyright (c) 2015 S Park. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreLocation/CoreLocation.h>
#import "XLMediaZoom.h"
#import "KLCPopup.h"
@import GoogleMaps;
@import MapKit;

@interface ViewController : UIViewController <UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate>

@property CGFloat screenW;
@property CGFloat screenH;

@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) UIImagePickerController *takeNewPhotoPicker;
@property (strong) NSMutableDictionary *exifData;
@property (assign, nonatomic) NSInteger index;
@property (strong, nonatomic) IBOutlet UILabel *screenNumber;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet XLMediaZoom *imageZoom;
@property (strong, nonatomic) IBOutlet UITextField *width;
@property (strong, nonatomic) IBOutlet UITextField *height;
@property (strong, nonatomic) IBOutlet UITextField *fileSize;
@property (strong, nonatomic) IBOutlet UITextField *dateTimeOriginal;
@property (strong, nonatomic) IBOutlet UITextField *dateTimeOriginalTime;
@property (strong, nonatomic) IBOutlet UITextField *dateTimeDigitized;
@property (strong, nonatomic) IBOutlet UITextField *fileName;
@property (strong, nonatomic) IBOutlet UITextField *fileExtension;
@property (strong, nonatomic) IBOutlet UITextField *widthAndHeight;

// Restoring the original values (The 'Reset' button)
@property (strong, nonatomic) IBOutlet UITextField *currentlyBeingEdited;
@property (strong, nonatomic) IBOutlet NSString *currentItem;

// Description pop-up (The 'What is this?' button)
@property (strong, nonatomic) IBOutlet UIView *descriptionView;
@property (strong, nonatomic) IBOutlet UIScrollView *descriptionScrollView;
@property (strong, nonatomic) IBOutlet UILabel *item;
@property (strong, nonatomic) IBOutlet UITextView *itemInfo;
@property (strong, nonatomic) IBOutlet KLCPopup *popup;

// Dictionary of original values (required by both 'Reset' and 'What is this?')
@property (strong, nonatomic) IBOutlet NSMutableDictionary *originalValues;
@property (strong, nonatomic) IBOutlet NSString *exifExposureTimeO;

@property (strong, nonatomic) IBOutlet NSMutableDictionary *tags;
@property long currentTag;

// Date selection
@property (strong, nonatomic) IBOutlet UILabel *selectedDate;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;

// Save menu
@property (strong, nonatomic) IBOutlet UIView *saveView;
@property (strong, nonatomic) IBOutlet UIButton *jpgSaveButton;
@property (strong, nonatomic) IBOutlet UIButton *pngSaveButton;
@property (strong, nonatomic) IBOutlet KLCPopup *savePopup;

// Not-a-number popup
@property (strong, nonatomic) IBOutlet UIView *numberView;
@property (strong, nonatomic) IBOutlet KLCPopup *numberPopup;
@property (strong, nonatomic) IBOutlet UITextView *numberWarning;

// EXIF Dictionary Keys
@property (strong, nonatomic) IBOutlet UITextField *exifExposureTime;
@property (strong, nonatomic) IBOutlet UITextField *exifFNumber;
@property (strong, nonatomic) IBOutlet UITextField *exifExposureProgram;
@property (strong, nonatomic) IBOutlet UITextField *exifSpectralSensitivity;
@property (strong, nonatomic) IBOutlet UITextField *exifISOSpeedRatings;
@property (strong, nonatomic) IBOutlet UITextField *exifOECF;
@property (strong, nonatomic) IBOutlet UITextField *exifVersion;
@property (strong, nonatomic) IBOutlet UITextField *exifComponentsConfiguration;
@property (strong, nonatomic) IBOutlet UITextField *exifCompressedBitsPerPixel;
@property (strong, nonatomic) IBOutlet UITextField *exifShutterSpeedValue;
@property (strong, nonatomic) IBOutlet UITextField *exifApertureValue;
@property (strong, nonatomic) IBOutlet UITextField *exifBrightnessValue;
@property (strong, nonatomic) IBOutlet UITextField *exifExposureBiasValue;
@property (strong, nonatomic) IBOutlet UITextField *exifMaxApertureValue;
@property (strong, nonatomic) IBOutlet UITextField *exifSubjectDistance;
@property (strong, nonatomic) IBOutlet UITextField *exifMeteringMode;
@property (strong, nonatomic) IBOutlet UITextField *exifLightSource;
@property (strong, nonatomic) IBOutlet UITextField *exifFlash;
@property (strong, nonatomic) IBOutlet UITextField *exifFocalLength;
@property (strong, nonatomic) IBOutlet UITextField *exifSubjectArea;
@property (strong, nonatomic) IBOutlet UITextField *exifMakerNote;
@property (strong, nonatomic) IBOutlet UITextField *exifUserComment;
@property (strong, nonatomic) IBOutlet UITextField *exifSubsecTime;
@property (strong, nonatomic) IBOutlet UITextField *exifSubsecTimeOrginal;
@property (strong, nonatomic) IBOutlet UITextField *exifSubsecTimeDigitized;
@property (strong, nonatomic) IBOutlet UITextField *exifFlashPixVersion;
@property (strong, nonatomic) IBOutlet UITextField *exifColorSpace;
@property (strong, nonatomic) IBOutlet UITextField *exifPixelXDimension;
@property (strong, nonatomic) IBOutlet UITextField *exifPixelYDimension;
@property (strong, nonatomic) IBOutlet UITextField *exifRelatedSoundFile;
@property (strong, nonatomic) IBOutlet UITextField *exifFlashEnergy;
@property (strong, nonatomic) IBOutlet UITextField *exifSpatialFrequencyResponse;
@property (strong, nonatomic) IBOutlet UITextField *exifFocalPlaneXResolution;
@property (strong, nonatomic) IBOutlet UITextField *exifFocalPlaneYResolution;
@property (strong, nonatomic) IBOutlet UITextField *exifFocalPlaneResolutionUnit;
@property (strong, nonatomic) IBOutlet UITextField *exifSubjectLocation;
@property (strong, nonatomic) IBOutlet UITextField *exifExposureIndex;
@property (strong, nonatomic) IBOutlet UITextField *exifSensingMethod;
@property (strong, nonatomic) IBOutlet UITextField *exifFileSource;
@property (strong, nonatomic) IBOutlet UITextField *exifSceneType;
@property (strong, nonatomic) IBOutlet UITextField *exifCFAPattern;
@property (strong, nonatomic) IBOutlet UITextField *exifCustomRendered;
@property (strong, nonatomic) IBOutlet UITextField *exifExposureMode;
@property (strong, nonatomic) IBOutlet UITextField *exifWhiteBalance;
@property (strong, nonatomic) IBOutlet UITextField *exifDigitalZoomRatio;
@property (strong, nonatomic) IBOutlet UITextField *exifFocalLenIn35mmFilm;
@property (strong, nonatomic) IBOutlet UITextField *exifSceneCaptureType;
@property (strong, nonatomic) IBOutlet UITextField *exifGainControl;
@property (strong, nonatomic) IBOutlet UITextField *exifContrast;
@property (strong, nonatomic) IBOutlet UITextField *exifSaturation;
@property (strong, nonatomic) IBOutlet UITextField *exifSharpness;
@property (strong, nonatomic) IBOutlet UITextField *exifDeviceSettingDescription;
@property (strong, nonatomic) IBOutlet UITextField *exifSubjectDistRange;
@property (strong, nonatomic) IBOutlet UITextField *exifImageUniqueID;
@property (strong, nonatomic) IBOutlet UITextField *exifGamma;
@property (strong, nonatomic) IBOutlet UITextField *exifCameraOwnerName;
@property (strong, nonatomic) IBOutlet UITextField *exifBodySerialNumber;
@property (strong, nonatomic) IBOutlet UITextField *exifLensSpecification;
@property (strong, nonatomic) IBOutlet UITextField *exifLensMake;
@property (strong, nonatomic) IBOutlet UITextField *exifLensModel;
@property (strong, nonatomic) IBOutlet UITextField *exifLensSerialNumber;

// Google maps
@property (strong, nonatomic) IBOutlet GMSMapView *mapView;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) GMSCameraPosition *camera;
@property (nonatomic) BOOL firstLocationUpdate;

// Apple maps
@property (strong, nonatomic) IBOutlet MKMapView *gpsMapView;
//@property (nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) IBOutlet UIButton *userHeadingBtn;
@property (strong, nonatomic) IBOutlet UIButton *resetLocationBtn;
@property double latval;
@property double longval;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

// GPS Dictionary Keys
@property (strong, nonatomic) IBOutlet UITextField *gpsVersion;
@property (strong, nonatomic) IBOutlet UITextField *gpsLatitudeRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsLatitude;
@property (strong, nonatomic) IBOutlet UITextField *gpsLongitudeRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsLongitude;
@property (strong, nonatomic) IBOutlet UITextField *gpsAltitudeRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsAltitude;
@property (strong, nonatomic) IBOutlet UITextField *gpsTimeStamp;
@property (strong, nonatomic) IBOutlet UITextField *gpsSatellites;
@property (strong, nonatomic) IBOutlet UITextField *gpsStatus;
@property (strong, nonatomic) IBOutlet UITextField *gpsMeasureMode;
@property (strong, nonatomic) IBOutlet UITextField *gpsDegreeOfPrecision;
@property (strong, nonatomic) IBOutlet UITextField *gpsSpeedRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsSpeed;
@property (strong, nonatomic) IBOutlet UITextField *gpsTrackRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsTrack;
@property (strong, nonatomic) IBOutlet UITextField *gpsImgDirectionRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsImgDirection;
@property (strong, nonatomic) IBOutlet UITextField *gpsMapDatum;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestLatRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestLat;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestLongRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestLong;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestBearingRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestBearing;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestDistanceRef;
@property (strong, nonatomic) IBOutlet UITextField *gpsDestDistance;
@property (strong, nonatomic) IBOutlet UITextField *gpsProcessingMethod;
@property (strong, nonatomic) IBOutlet UITextField *gpsAreaInformation;
@property (strong, nonatomic) IBOutlet UITextField *gpsDateStamp;
@property (strong, nonatomic) IBOutlet UITextField *gpsDifferental;
// etc.


// ALAsset keys
@property (strong, nonatomic) IBOutlet UITextField *duration;
@property (strong, nonatomic) IBOutlet UITextField *latitude;
@property (strong, nonatomic) IBOutlet UITextField *longitude;
//@property (strong, nonatomic) IBOutlet NSNumber *duration;
//@property (strong, nonatomic) IBOutlet CLLocation *location;


//@property (strong, nonatomic) IBOutlet UITextView *textView;

// Look into expanding menus

@property (strong, nonatomic) IBOutlet UITableView *exifTableView;
@property (strong, nonatomic) IBOutlet UITableView *gpsTableView;

@property (strong) UIImagePickerController *pic;
@property (strong) NSDictionary *inf;
@property (strong) NSData *currentImageData;

- (IBAction)loadPicture;
- (IBAction)takePicture;
- (IBAction)newImageButtonPressed:(id)sender;
- (IBAction)saveButtonPressed:(id)sender;
- (IBAction)resetExif:(id)sender;
//- (IBAction)eraseExif:(id)sender;
- (IBAction)clearExif;

- (NSString *)md5:(NSString *)input;

@end


//
//  ChildViewController.m
//  Exif Editor
//
//  Created by S Park on 9/11/15.
//  Copyright (c) 2015 S Park. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChildViewController.h"
#import <ImageIO/CGImageDestination.h>
#import <QuartzCore/QuartzCore.h>

@interface ChildViewController ()

@end

@implementation ChildViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
//    
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    
//    if (self) {
//        // Custom initialization
//    }
//    
//    return self;
//    
//}


- (IBAction)loadPicture {
    if (self.picker == nil) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.picker.allowsEditing = NO;
    }
    [self presentViewController:_picker animated:YES completion:nil];
}

- (IBAction)takePicture:(id)sender {
    NSLog(@"Now taking pic");
}
- (IBAction)newImageButtonPressed:(id)sender {
    [self loadPicture];
}

- (IBAction)saveButtonPressed:(id)sender {
    NSLog(@"Now saving");
}

- (IBAction)resetExif:(id)sender {
    NSLog(@"Now resetting");
    [self imagePickerController:self.pic didFinishPickingMediaWithInfo:self.inf];
}

- (IBAction)eraseExif:(id)sender {
    NSLog(@"Now erasing");
    self.width.text = @"";
    self.height.text = @"";
    self.dateTimeDigitized.text = @"";
    self.duration.text = @"";
    self.latitude.text = @"";
    self.longitude.text = @"";
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.pic = picker;
    self.inf = info;
//    NSLog(@"%@", info);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    UIImage *fullImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    NSValue *cropRect = info[UIImagePickerControllerCropRect];
    NSURL *mediaUrl = info[UIImagePickerControllerMediaURL];
    NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
    NSMutableDictionary *mediaMetadata = (NSMutableDictionary *) [info objectForKey:UIImagePickerControllerMediaMetadata];
    self.exifData = mediaMetadata;
    
    self.imageView.image = fullImage;
//    [self.imageView sizeToFit];
//    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    CGRect frame = self.imageView.frame;
//    float imgFactor = frame.size.height / frame.size.width;
//    frame.size.width = [[UIScreen mainScreen] bounds].size.width;
//    frame.size.height = frame.size.width * imgFactor;
    
    // full exif (but with didFinishPikingMediaWithInfo)
    
    
    
    // image width and height (but with CGImageSourceRef)
    // below is from http://stackoverflow.com/questions/9766394/get-exif-data-from-uiimage-uiimagepickercontroller
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
             resultBlock:^(ALAsset *asset) {
                 
                 ALAssetRepresentation *image_representation = [asset defaultRepresentation];
                 
                 // create a buffer to hold image data
                 uint8_t *buffer = (Byte*)malloc(image_representation.size);
                 NSUInteger length = [image_representation getBytes:buffer fromOffset: 0.0  length:image_representation.size error:nil];
                 
                 if (length != 0)  {
                     
                     // buffer -> NSData object; free buffer afterwards
                     NSData *adata = [[NSData alloc] initWithBytesNoCopy:buffer length:image_representation.size freeWhenDone:YES];
                     
                     // identify image type (jpeg, png, RAW file, ...) using UTI hint
                     NSDictionary* sourceOptionsDict = [NSDictionary dictionaryWithObjectsAndKeys:(id)[image_representation UTI] ,kCGImageSourceTypeIdentifierHint,nil];
                     
                     // create CGImageSource with NSData
                     CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef) adata,  (__bridge CFDictionaryRef) sourceOptionsDict);
                     
                     // get imagePropertiesDictionary for use in Exif
                     CFDictionaryRef imagePropertiesDictionary;
                     imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
                     
                     // get metadata for use in GPS
                     NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(sourceRef,0,NULL));
                     NSMutableDictionary *metadataAsMutable = [metadata mutableCopy];
                     
                     NSMutableDictionary *EXIFDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyExifDictionary]mutableCopy];
                     NSMutableDictionary *GPSDictionary = [[metadataAsMutable objectForKey:(NSString *)kCGImagePropertyGPSDictionary]mutableCopy];
                     
                     if(!EXIFDictionary) {
                         //if the image does not have an EXIF dictionary (not all images do), then create one for us to use
                         EXIFDictionary = [NSMutableDictionary dictionary];
                     }
                     if(!GPSDictionary) {
                         GPSDictionary = [NSMutableDictionary dictionary];
                     }
                     
                     // Get width and height
                     CFNumberRef imageWidth = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelWidth);
                     CFNumberRef imageHeight = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyPixelHeight);
                     
                     int w = 0;
                     int h = 0;
                     
                     CFNumberGetValue(imageWidth, kCFNumberIntType, &w);
                     CFNumberGetValue(imageHeight, kCFNumberIntType, &h);
                     
                     self.width.text = [NSString stringWithFormat:@"%d",w];
                     self.height.text = [NSString stringWithFormat:@"%d",h];
                     
                     // get exif data
                     CFDictionaryRef exif = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifDictionary);
                     NSDictionary *exif_dict = (__bridge NSDictionary*)exif;
                     NSLog(@"exif_dict: %@",exif_dict);
                     
                     NSString *exifExposureTime = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureTime);
                     self.exifExposureTime.text = exifExposureTime;
                     NSString *exifFNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifFNumber);
                     self.exifFNumber.text = exifFNumber;
                     NSString *exifExposureProgram = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureProgram);
                     self.exifExposureProgram.text = exifExposureProgram;
                     NSString *exifSpectralSensitivity = CFDictionaryGetValue(exif, kCGImagePropertyExifSpectralSensitivity);
                     self.exifSpectralSensitivity.text = exifSpectralSensitivity;
                     NSString *exifISOSpeedRatings = CFDictionaryGetValue(exif, kCGImagePropertyExifISOSpeedRatings);
                     self.exifISOSpeedRatings.text = exifISOSpeedRatings;
                     NSString *exifOECF = CFDictionaryGetValue(exif, kCGImagePropertyExifOECF);
                     self.exifOECF.text = exifOECF;
                     NSString *exifVersion = CFDictionaryGetValue(exif, kCGImagePropertyExifVersion);
                     self.exifVersion.text = exifVersion;
                     NSString *exifDateTimeOriginal = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal);
                     self.dateTimeOriginal.text = exifDateTimeOriginal;
                     NSString *exifDateTimeDigitized = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeDigitized);
                     self.dateTimeDigitized.text = exifDateTimeDigitized;
                     NSString *exifComponentsConfiguration = CFDictionaryGetValue(exif, kCGImagePropertyExifComponentsConfiguration);
                     self.exifComponentsConfiguration.text = exifComponentsConfiguration;
                     NSString *exifCompressedBitsPerPixel = CFDictionaryGetValue(exif, kCGImagePropertyExifCompressedBitsPerPixel);
                     self.exifCompressedBitsPerPixel.text = exifCompressedBitsPerPixel;
                     NSString *exifShutterSpeedValue = CFDictionaryGetValue(exif, kCGImagePropertyExifShutterSpeedValue);
                     self.exifShutterSpeedValue.text = exifShutterSpeedValue;
                     NSString *exifApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifApertureValue);
                     self.exifApertureValue.text = exifApertureValue;
                     NSString *exifBrightnessValue = CFDictionaryGetValue(exif, kCGImagePropertyExifBrightnessValue);
                     self.exifBrightnessValue.text = exifBrightnessValue;
                     NSString *exifExposureBiasValue = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureBiasValue);
                     self.exifExposureBiasValue.text = exifExposureBiasValue;
                     NSString *exifMaxApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifMaxApertureValue);
                     self.exifMaxApertureValue.text = exifMaxApertureValue;
                     NSString *exifSubjectDistance = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectDistance);
                     self.exifSubjectDistance.text = exifSubjectDistance;
                     NSString *exifMeteringMode = CFDictionaryGetValue(exif, kCGImagePropertyExifMeteringMode);
                     self.exifMeteringMode.text = exifMeteringMode;
                     NSString *exifLightSource = CFDictionaryGetValue(exif, kCGImagePropertyExifLightSource);
                     self.exifLightSource.text = exifLightSource;
                     NSString *exifFlash = CFDictionaryGetValue(exif, kCGImagePropertyExifFlash);
                     self.exifFlash.text = exifFlash;
                     NSString *exifFocalLength = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalLength);
                     self.exifFocalLength.text = exifFocalLength;
                     NSString *exifSubjectArea = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectArea);
                     self.exifSubjectArea.text = exifSubjectArea;
                     NSString *exifMakerNote = CFDictionaryGetValue(exif, kCGImagePropertyExifMakerNote);
                     self.exifMakerNote.text = exifMakerNote;
                     NSString *exifUserComment = CFDictionaryGetValue(exif, kCGImagePropertyExifUserComment);
                     self.exifUserComment.text = exifUserComment;
                     NSString *exifSubsecTime = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTime);
                     self.exifSubsecTime.text = exifSubsecTime;
                     
                     // Get digitized time stamp
//                     if (exif){
//                         NSString *timestamp = (NSString *)CFBridgingRelease(CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal));
//                         if (timestamp){
//                             NSLog(@"timestamp: %@", timestamp);
//                             self.dateTimeDigitized.text = timestamp;
//                         } else {
//                             self.dateTimeDigitized.text = @"N/A";
//                             NSLog(@"timestamp not found in the exif dic %@", exif);
//                         }
//                     } else {
//                     }
                     
                     // Get file size
                     
                     // Get video duration
                     NSString *duration = [asset valueForProperty:ALAssetPropertyDuration];
                     if([duration isEqualToString: @"ALErrorInvalidProperty"]) {
                         self.duration.text = @"N/A";
                     }
                     else {
                         self.duration.text = duration;
                     }
                     
                     
                     // get gps data
                     CFDictionaryRef gps = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSDictionary);
                     NSDictionary *gps_dict = (__bridge NSDictionary*)gps;
                     NSLog(@"gps_dict: %@",gps_dict);
                     
                     NSString *version = CFDictionaryGetValue(gps, kCGImagePropertyGPSVersion);
                     self.gpsVersion.text = version;
                     NSString *latitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
                     self.gpsLatitudeRef.text = latitudeRef;
                     NSString *latitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
                     self.gpsLatitude.text = latitude;
                     NSString *longitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
                     self.gpsLongitudeRef.text = longitudeRef;
                     NSString *longitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
                     self.gpsLongitude.text = longitude;
                     NSString *altitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitudeRef);
                     self.gpsAltitudeRef.text = altitudeRef;
                     NSString *altitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitude);
                     self.gpsAltitude.text = altitude;
                     NSString *timeStamp = CFDictionaryGetValue(gps, kCGImagePropertyGPSTimeStamp);
                     self.gpsTimeStamp.text = timeStamp;
                     NSString *satellites = CFDictionaryGetValue(gps, kCGImagePropertyGPSSatellites);
                     self.gpsSatellites.text = satellites;
                     NSString *status = CFDictionaryGetValue(gps, kCGImagePropertyGPSStatus);
                     self.gpsStatus.text = status;
                     NSString *measureMode = CFDictionaryGetValue(gps, kCGImagePropertyGPSMeasureMode);
                     self.gpsMeasureMode.text = measureMode;
                     NSString *degreeOfPrecision = CFDictionaryGetValue(gps, kCGImagePropertyGPSDOP);
                     self.gpsDegreeOfPrecision.text = degreeOfPrecision;
                     NSString *speedRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSSpeedRef);
                     self.gpsSpeedRef.text = speedRef;
                     NSString *speed = CFDictionaryGetValue(gps, kCGImagePropertyGPSSpeed);
                     self.gpsSpeed.text = speed;
                     NSString *trackRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSTrackRef);
                     self.gpsTrackRef.text = trackRef;
                     NSString *track = CFDictionaryGetValue(gps, kCGImagePropertyGPSTrack);
                     self.gpsTrack.text = track;
                     NSString *imgDirectionRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSImgDirectionRef);
                     self.gpsImgDirectionRef.text = imgDirectionRef;
                     NSString *imgDirection = CFDictionaryGetValue(gps, kCGImagePropertyGPSImgDirection);
                     self.gpsImgDirection.text = imgDirection;
                     NSString *mapDatum = CFDictionaryGetValue(gps, kCGImagePropertyGPSMapDatum);
                     self.gpsMapDatum.text = mapDatum;
                     NSString *destLatRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLatitudeRef);
                     self.gpsDestLatRef.text = destLatRef;
                     NSString *destLat = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLatitude);
                     self.gpsDestLat.text = destLat;
                     NSString *destLongRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLongitudeRef);
                     self.gpsDestLongRef.text = destLongRef;
                     NSString *destLong = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLongitude);
                     self.gpsDestLong.text = destLong;
                     NSString *destBearingRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestBearingRef);
                     self.gpsDestBearingRef.text = destBearingRef;
                     NSString *destBearing = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestBearing);
                     self.gpsDestBearing.text = destBearing;
                     NSString *destDistanceRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestDistanceRef);
                     self.gpsDestDistanceRef.text = destDistanceRef;
                     NSString *destDistance = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestDistance);
                     self.gpsDestDistance.text = destDistance;
                     NSString *processingMethod = CFDictionaryGetValue(gps, kCGImagePropertyGPSProcessingMethod);
                     self.gpsProcessingMethod.text = processingMethod;
                     NSString *areaInformation = CFDictionaryGetValue(gps, kCGImagePropertyGPSAreaInformation);
                     self.gpsAreaInformation.text = areaInformation;
                     NSString *dateStamp = CFDictionaryGetValue(gps, kCGImagePropertyGPSDateStamp);
                     self.gpsDateStamp.text = dateStamp;
                     NSString *differental = CFDictionaryGetValue(gps, kCGImagePropertyGPSDifferental);
                     self.gpsDifferental.text = differental;
                     
//                     NSLog(@"%@", version);
//                     NSLog(@"%@", latitudeRef);
//                     NSLog(@"%@", latitude);
//                     NSLog(@"%@", longitudeRef);
//                     NSLog(@"%@", longitude);
//                     NSLog(@"%@", altitudeRef);
//                     NSLog(@"%@", altitude);
//                     NSLog(@"%@", timeStamp);
//                     NSLog(@"%@", satellites);
                     
                     // save image WITH meta data
                     //                     NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                     //                     NSURL *fileURL = nil;
                     //                     CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, imagePropertiesDictionary);
                     //
                     //                     if (![[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"] isEqualToString:@"public.tiff"])
                     //                     {
                     //                         fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@.%@",
                     //                                                           documentsDirectory,
                     //                                                           @"myimage",
                     //                                                           [[[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"] componentsSeparatedByString:@"."] objectAtIndex:1]
                     //                                                           ]];
                     //
                     //                         CGImageDestinationRef dr = CGImageDestinationCreateWithURL ((__bridge CFURLRef)fileURL,
                     //                                                                                     (__bridge CFStringRef)[sourceOptionsDict objectForKey:@"kCGImageSourceTypeIdentifierHint"],
                     //                                                                                     1,
                     //                                                                                     NULL
                     //                                                                                     );
                     //                         CGImageDestinationAddImage(dr, imageRef, imagePropertiesDictionary);
                     //                         CGImageDestinationFinalize(dr);
                     //                         CFRelease(dr);
                     //                     }
                     //                     else
                     //                     {
                     //                         NSLog(@"no valid kCGImageSourceTypeIdentifierHint found …");
                     //                     }
                     
                     // clean up
                     //                     CFRelease(imageRef);
                     //                     CFRelease(imagePropertiesDictionary);
                     CFRelease(sourceRef);
                 }
                 else {
                     NSLog(@"image_representation buffer length == 0");
                 }
             }
            failureBlock:^(NSError *error) {
                NSLog(@"couldn't get asset: %@", error);
            }
     ];
    [picker dismissViewControllerAnimated:YES
                               completion:nil];
    
    //    UITextField *fileType = (UITextField *) [info objectForKey: UIImagePickerControllerMediaType];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
//    [self.width resignFirstResponder];
//    [self.height resignFirstResponder];
}


// Get current location
- (NSDictionary *)getGPSDictionaryForLocation:(CLLocation *)location {
    NSMutableDictionary *gps = [NSMutableDictionary dictionary];
    
    // GPS tag version
    [gps setObject:@"2.2.0.0" forKey:(NSString *)kCGImagePropertyGPSVersion];
    
    // Time and date must be provided as strings, not as an NSDate object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSSSSS"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    [formatter setDateFormat:@"yyyy:MM:dd"];
    [gps setObject:[formatter stringFromDate:location.timestamp] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    
    // Latitude
    CGFloat latitude = location.coordinate.latitude;
    if (latitude < 0) {
        latitude = -latitude;
        [gps setObject:@"S" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    } else {
        [gps setObject:@"N" forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:latitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
    
    // Longitude
    CGFloat longitude = location.coordinate.longitude;
    if (longitude < 0) {
        longitude = -longitude;
        [gps setObject:@"W" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    } else {
        [gps setObject:@"E" forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    [gps setObject:[NSNumber numberWithFloat:longitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
    
    // Altitude
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        if (altitude < 0) {
            altitude = -altitude;
            [gps setObject:@"1" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        } else {
            [gps setObject:@"0" forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
        }
        [gps setObject:[NSNumber numberWithFloat:altitude] forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    
    // Speed, must be converted from m/s to km/h
    if (location.speed >= 0){
        [gps setObject:@"K" forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
        [gps setObject:[NSNumber numberWithFloat:location.speed*3.6] forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    
    // Heading
    if (location.course >= 0){
        [gps setObject:@"T" forKey:(NSString *)kCGImagePropertyGPSTrackRef];
        [gps setObject:[NSNumber numberWithFloat:location.course] forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    
    return gps;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
//    self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    self.width.delegate = self;
    
//    
//    self.myTable.delegate = [[CollapsableTableView alloc] init];
//    [self.myTable setDelegate:CollapsableTableViewDelegate ];
//    [self.myTable setDataSource:CollapsableTableView];
//    
    
    
    // Exif
//    if(self.index == 0) {
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*3)];
    [self.view addSubview:self.scrollView];
    
    // Width of scroll view
    CGFloat w = self.scrollView.bounds.size.width;
    NSLog(@"%f", w);
    
    // Take picture button
    UIButton *takePicture = [UIButton buttonWithType:UIButtonTypeCustom];
    takePicture.frame = CGRectMake(0, 10.0, w/5, w/5);
    UIImage *takePictureImage = [UIImage imageNamed:@"CameraIconC.png"];
    [takePicture setImage:takePictureImage forState:UIControlStateNormal];
    [takePicture addTarget:self
                    action:@selector(takePicture:)
          forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:takePicture];
    
    // New image button
    UIButton *chooseNewImage = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseNewImage.frame = CGRectMake(w/5, 10.0, w/5, w/5);
    UIImage *chooseNewImageImage = [UIImage imageNamed:@"PhotoIconC.png"];
    [chooseNewImage setImage:chooseNewImageImage forState:UIControlStateNormal];
    [chooseNewImage addTarget:self
                       action:@selector(newImageButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:chooseNewImage];
    
    // Reset to actual
    UIButton *resetExif = [UIButton buttonWithType:UIButtonTypeCustom];
    resetExif.frame = CGRectMake(2*w/5, 10.0, w/5, w/5);
    UIImage *resetExifImage = [UIImage imageNamed:@"ResetIconC.png"];
    [resetExif setImage:resetExifImage forState:UIControlStateNormal];
    [resetExif addTarget:self
                  action:@selector(resetExif:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:resetExif];
    
    // Delete all
    UIButton *eraseExif = [UIButton buttonWithType:UIButtonTypeCustom];
    eraseExif.frame = CGRectMake(3*w/5, 10.0, w/5, w/5);
    UIImage *eraseExifImage = [UIImage imageNamed:@"EraseIconC.png"];
    [eraseExif setImage:eraseExifImage forState:UIControlStateNormal];
    [eraseExif addTarget:self
                  action:@selector(eraseExif:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:eraseExif];
    
    // Button for saving the modified image
    UIButton *saveExif = [UIButton buttonWithType:UIButtonTypeCustom];
    saveExif.frame = CGRectMake(4*w/5, 10.0, w/5, w/5);
    UIImage *saveExifImage = [UIImage imageNamed:@"SaveIconC.png"];
    [saveExif setImage:saveExifImage forState:UIControlStateNormal];
    [saveExif addTarget:self
                 action:@selector(saveButtonPressed:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:saveExif];
    
    // Image view
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = CGRectMake(20, 100, self.scrollView.bounds.size.width-40, 300);
    // Aspect fit from http://stackoverflow.com/questions/15499376/uiimageview-aspect-fit-and-center
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.scrollView addSubview:self.imageView];
    
    // Width label
    UILabel *widthLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 420, 400, 20)];
    widthLabel.text = @"Width";
    widthLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:widthLabel];
    
    // Width
    self.width = [[UITextField alloc] init];
    self.width.frame = CGRectMake(130, 420, self.scrollView.bounds.size.width-260, 20);
    self.width.textColor = [UIColor blackColor];
    self.width.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.width];
    
//    // Round style text field from http://stackoverflow.com/questions/1824463/how-to-style-uitextview-to-like-rounded-rect-text-field
//    [self.width.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
//    [self.width.layer setBorderWidth:2.0];
//    self.width.layer.cornerRadius = 5;
//    self.width.clipsToBounds = YES;
    
    // Height label
    UILabel *heightLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 460, 400, 20)];
    heightLabel.text = @"Height";
    heightLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:heightLabel];
    
    // Height
    self.height = [[UITextField alloc] init];
    self.height.frame = CGRectMake(130, 460, 400, 20);
    self.height.textColor = [UIColor blackColor];
    self.height.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.height];
    
    // File size label
    UILabel *fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 500, 400, 20)];
    fileSizeLabel.text = @"File size";
    fileSizeLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:fileSizeLabel];
    
    // File size
    self.fileSize = [[UITextField alloc] init];
    self.fileSize.frame = CGRectMake(130, 500, 400, 20);
    self.fileSize.textColor = [UIColor blackColor];
    self.fileSize.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.fileSize];
    
    // Date label. created or modified?
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 540, 400, 20)];
    dateLabel.text = @"Date created";
    dateLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:dateLabel];
    
    // Date
    self.dateTimeDigitized = [[UITextField alloc] init];
    self.dateTimeDigitized.frame = CGRectMake(130, 540, 400, 20);
    self.dateTimeDigitized.textColor = [UIColor blackColor];
    self.dateTimeDigitized.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.dateTimeDigitized];
    
    // GPS latitude ref label
    UILabel *latitudeRefLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 580, 400, 20)];
    latitudeRefLabel.text = @"Latitude Ref";
    latitudeRefLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:latitudeRefLabel];
    
    // GPS latitude Ref
    self.gpsLatitudeRef = [[UITextField alloc] init];
    self.gpsLatitudeRef.frame = CGRectMake(130, 580, 400, 20);
    self.gpsLatitudeRef.textColor = [UIColor blackColor];
    self.gpsLatitudeRef.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.gpsLatitudeRef];
    
    // ALAsset duration label
    UILabel *durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 620, 400, 20)];
    durationLabel.text = @"Duration";
    durationLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:durationLabel];
    
    // ALAsset duration
    self.duration = [[UITextField alloc] init];
    self.duration.frame = CGRectMake(130, 620, 400, 20);
    self.duration.textColor = [UIColor blackColor];
    self.duration.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.duration];
    
    // ALAsset latitude label
    UILabel *latitudeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 660, 400, 20)];
    latitudeLabel.text = @"Latitude";
    latitudeLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:latitudeLabel];
    
    // ALAsset location
    self.latitude = [[UITextField alloc] init];
    self.latitude.frame = CGRectMake(130, 660, 400, 20);
    self.latitude.textColor = [UIColor blackColor];
    self.latitude.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.latitude];
    
    // ALAsset longitude label
    UILabel *longitudeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 700, 400, 20)];
    longitudeLabel.text = @"Longitude";
    longitudeLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:longitudeLabel];
    
    // ALAsset location
    self.longitude = [[UITextField alloc] init];
    self.longitude.frame = CGRectMake(130, 700, 400, 20);
    self.longitude.textColor = [UIColor blackColor];
    self.longitude.allowsEditingTextAttributes = NO;
    [self.scrollView addSubview:self.longitude];
    
    [self loadPicture];

//    }
    // Converter
//    else if(self.index == 1) {
//        self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
//        [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*3)];
//        [self.view addSubview:self.scrollView];
//
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(200, 200, 380, 20)];
//        label.text = @"Second Page";
//        label.textColor = [UIColor whiteColor];
//        [self.scrollView addSubview:label];
//    }
    
    
//    self.screenNumber.text = [NSString stringWithFormat:@"Screen #%ld", self.index];
    
}



- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end

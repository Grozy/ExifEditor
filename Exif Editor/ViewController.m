//
//  ViewController.m
//  Exif Editor
//
//  Created by S Park on 9/11/15.
//  Copyright (c) 2015 S Park. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import <ImageIO/CGImageDestination.h>
#import <QuartzCore/QuartzCore.h>
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface ViewController ()

@end

@implementation ViewController

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

- (NSString *)stringOutputForDictionary:(NSDictionary *)inputDict {
    NSMutableString * outputString = [NSMutableString stringWithCapacity:256];
    
    NSArray * allKeys = [inputDict allKeys];
    
    for (NSString * key in allKeys) {
        if ([[inputDict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
            [outputString appendString: [self stringOutputForDictionary: (NSDictionary *)inputDict]];
        }
        else {
            [outputString appendString: key];
            [outputString appendString: @": "];
            [outputString appendString: [[inputDict objectForKey: key] description]];
        }
        [outputString appendString: @"\n"];
    }
    
    return [NSString stringWithString: outputString];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.pic = picker;
    self.inf = info;
    //    NSLog(@"%@", info);
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    NSString *mediaType = info[UIImagePickerControllerMediaType];
    UIImage *fullImage = info[UIImagePickerControllerOriginalImage];
//    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
//    NSValue *cropRect = info[UIImagePickerControllerCropRect];
//    NSURL *mediaUrl = info[UIImagePickerControllerMediaURL];
//    NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
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
                 
                 self.fileName.text = [[asset defaultRepresentation] filename];
                 
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
                     
                     // get file size
                     ALAssetRepresentation *representation=[asset defaultRepresentation];
                     double fileSize = [representation size]/1024.0;
                     
                     NSLog(@"File size is: %f kilobytes", fileSize);
                     self.fileSize.text = [NSString stringWithFormat:@"%f KB", fileSize];
                     
                     //                     self.tableData = [exif_dict allValues];
                     //                     self.myTableView.dataSource = self;
                     //                     self.myTableView.delegate = self;
                     //                     [self setUpTableView];
                     
                     NSMutableString * outputString = [NSMutableString stringWithCapacity:4096];
                     NSArray * allKeys = [exif_dict allKeys];
                     
                     for (NSString * key in allKeys) {
                         if ([[exif_dict objectForKey:key] isKindOfClass:[NSDictionary class]]) {
                             [outputString appendString: [self stringOutputForDictionary: (NSDictionary *)exif_dict]];
                         }
                         else {
                             [outputString appendString: key];
                             [outputString appendString: @": "];
                             [outputString appendString: [[exif_dict objectForKey: key] description]];
                         }
                         [outputString appendString: @"\n"];
                     }
                     
                     //                     self.textView.text = outputString;
                     
                     if(exif_dict) {
                         NSDecimalNumber *exifExposureTime = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureTime);
                         //                         NSLog(@"%@", exifExposureTime);
                         self.exifExposureTime.text = [NSString stringWithFormat:@"%@", exifExposureTime];
                         
                         NSDecimalNumber *exifFNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifFNumber);
                         self.exifFNumber.text = [NSString stringWithFormat:@"%@", exifFNumber];
                         
                         NSDecimalNumber *exifExposureProgram = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureProgram);
                         self.exifExposureProgram.text = [NSString stringWithFormat:@"%@", exifExposureProgram];
                         
                         NSDecimalNumber *exifSpectralSensitivity = CFDictionaryGetValue(exif, kCGImagePropertyExifSpectralSensitivity);
                         self.exifSpectralSensitivity.text = [NSString stringWithFormat:@"%@", exifSpectralSensitivity];
                         
                         NSDecimalNumber *exifISOSpeedRatings = CFDictionaryGetValue(exif, kCGImagePropertyExifISOSpeedRatings);
                         self.exifISOSpeedRatings.text = [NSString stringWithFormat:@"%@", exifISOSpeedRatings];
                         
                         NSDecimalNumber *exifOECF = CFDictionaryGetValue(exif, kCGImagePropertyExifOECF);
                         self.exifOECF.text = [NSString stringWithFormat:@"%@", exifOECF];
                         
                         NSDecimalNumber *exifVersion = CFDictionaryGetValue(exif, kCGImagePropertyExifVersion);
                         self.exifVersion.text = [NSString stringWithFormat:@"%@", exifVersion];
                         
                         NSDecimalNumber *exifDateTimeOriginal = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal);
                         self.dateTimeOriginal.text = [NSString stringWithFormat:@"%@", exifDateTimeOriginal];
                         
                         NSDecimalNumber *exifDateTimeDigitized = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeDigitized);
                         self.dateTimeDigitized.text = [NSString stringWithFormat:@"%@", exifDateTimeDigitized];
                         
                         NSDecimalNumber *exifComponentsConfiguration = CFDictionaryGetValue(exif, kCGImagePropertyExifComponentsConfiguration);
                         self.exifComponentsConfiguration.text = [NSString stringWithFormat:@"%@", exifComponentsConfiguration];
                         
                         NSDecimalNumber *exifCompressedBitsPerPixel = CFDictionaryGetValue(exif, kCGImagePropertyExifCompressedBitsPerPixel);
                         self.exifCompressedBitsPerPixel.text = [NSString stringWithFormat:@"%@", exifCompressedBitsPerPixel];
                         
                         NSDecimalNumber *exifShutterSpeedValue = CFDictionaryGetValue(exif, kCGImagePropertyExifShutterSpeedValue);
                         self.exifShutterSpeedValue.text = [NSString stringWithFormat:@"%@", exifShutterSpeedValue];
                         
                         NSDecimalNumber *exifApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifApertureValue);
                         self.exifApertureValue.text = [NSString stringWithFormat:@"%@", exifApertureValue];
                         
                         NSDecimalNumber *exifBrightnessValue = CFDictionaryGetValue(exif, kCGImagePropertyExifBrightnessValue);
                         self.exifBrightnessValue.text = [NSString stringWithFormat:@"%@", exifBrightnessValue];
                         
                         NSDecimalNumber *exifExposureBiasValue = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureBiasValue);
                         self.exifExposureBiasValue.text = [NSString stringWithFormat:@"%@", exifExposureBiasValue];
                         
                         NSDecimalNumber *exifMaxApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifMaxApertureValue);
                         self.exifMaxApertureValue.text = [NSString stringWithFormat:@"%@", exifMaxApertureValue];
                         
                         NSDecimalNumber *exifSubjectDistance = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectDistance);
                         self.exifSubjectDistance.text = [NSString stringWithFormat:@"%@", exifSubjectDistance];
                         
                         NSDecimalNumber *exifMeteringMode = CFDictionaryGetValue(exif, kCGImagePropertyExifMeteringMode);
                         self.exifMeteringMode.text = [NSString stringWithFormat:@"%@", exifMeteringMode];
                         
                         NSDecimalNumber *exifLightSource = CFDictionaryGetValue(exif, kCGImagePropertyExifLightSource);
                         self.exifLightSource.text = [NSString stringWithFormat:@"%@", exifLightSource];
                         
                         NSDecimalNumber *exifFlash = CFDictionaryGetValue(exif, kCGImagePropertyExifFlash);
                         self.exifFlash.text = [NSString stringWithFormat:@"%@", exifFlash];
                         
                         NSDecimalNumber *exifFocalLength = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalLength);
                         self.exifFocalLength.text = [NSString stringWithFormat:@"%@", exifFocalLength];
                         
                         NSDecimalNumber *exifSubjectArea = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectArea);
                         self.exifSubjectArea.text = [NSString stringWithFormat:@"%@", exifSubjectDistance];
                         
                         NSDecimalNumber *exifMakerNote = CFDictionaryGetValue(exif, kCGImagePropertyExifMakerNote);
                         self.exifMakerNote.text = [NSString stringWithFormat:@"%@", exifMakerNote];
                         
                         NSDecimalNumber *exifUserComment = CFDictionaryGetValue(exif, kCGImagePropertyExifUserComment);
                         self.exifUserComment.text = [NSString stringWithFormat:@"%@", exifUserComment];
                         
                         NSDecimalNumber *exifSubsecTime = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTime);
                         self.exifSubsecTime.text = [NSString stringWithFormat:@"%@", exifSubsecTime];
                         
                         NSDecimalNumber *exifSubsecTimeOrginal = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTimeOrginal);
                         self.exifSubsecTimeOrginal.text = [NSString stringWithFormat:@"%@", exifSubsecTimeOrginal];
                         
                         NSDecimalNumber *exifSubsecTimeDigitized = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTimeDigitized);
                         self.exifSubsecTimeDigitized.text = [NSString stringWithFormat:@"%@", exifSubsecTimeDigitized];
                         
                         NSDecimalNumber *exifFlashPixVersion = CFDictionaryGetValue(exif, kCGImagePropertyExifFlashPixVersion);
                         self.exifFlashPixVersion.text = [NSString stringWithFormat:@"%@", exifFlashPixVersion];
                         
                         NSDecimalNumber *exifColorSpace = CFDictionaryGetValue(exif, kCGImagePropertyExifColorSpace);
                         self.exifColorSpace.text = [NSString stringWithFormat:@"%@", exifColorSpace];
                         
                         NSDecimalNumber *exifPixelXDimension = CFDictionaryGetValue(exif, kCGImagePropertyExifPixelXDimension);
                         self.exifPixelXDimension.text = [NSString stringWithFormat:@"%@", exifPixelXDimension];
                         
                         NSDecimalNumber *exifPixelYDimension = CFDictionaryGetValue(exif, kCGImagePropertyExifPixelYDimension);
                         self.exifPixelYDimension.text = [NSString stringWithFormat:@"%@", exifPixelYDimension];
                         
                         NSDecimalNumber *exifRelatedSoundFile = CFDictionaryGetValue(exif, kCGImagePropertyExifRelatedSoundFile);
                         self.exifRelatedSoundFile.text = [NSString stringWithFormat:@"%@", exifRelatedSoundFile];
                         
                         NSDecimalNumber *exifFlashEnergy = CFDictionaryGetValue(exif, kCGImagePropertyExifFlashEnergy);
                         self.exifFlashEnergy.text = [NSString stringWithFormat:@"%@", exifFlashEnergy];
                         
                         NSDecimalNumber *exifSpatialFrequencyResponse = CFDictionaryGetValue(exif, kCGImagePropertyExifSpatialFrequencyResponse);
                         self.exifSpatialFrequencyResponse.text = [NSString stringWithFormat:@"%@", exifSpatialFrequencyResponse];
                         
                         NSDecimalNumber *exifFocalPlaneXResolution = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneXResolution);
                         self.exifFocalPlaneXResolution.text = [NSString stringWithFormat:@"%@", exifFocalPlaneXResolution];
                         
                         NSDecimalNumber *exifFocalPlaneYResolution = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneYResolution);
                         self.exifFocalPlaneYResolution.text = [NSString stringWithFormat:@"%@", exifFocalPlaneYResolution];
                         
                         NSDecimalNumber *exifFocalPlaneResolutionUnit = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneResolutionUnit);
                         self.exifFocalPlaneResolutionUnit.text = [NSString stringWithFormat:@"%@", exifFocalPlaneResolutionUnit];
                         
                         NSDecimalNumber *exifSubjectLocation = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectLocation);
                         self.exifSubjectLocation.text = [NSString stringWithFormat:@"%@", exifSubjectLocation];
                         
                         NSDecimalNumber *exifExposureIndex = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureIndex);
                         self.exifExposureIndex.text = [NSString stringWithFormat:@"%@", exifExposureIndex];
                         
                         NSDecimalNumber *exifSensingMethod = CFDictionaryGetValue(exif, kCGImagePropertyExifSensingMethod);
                         self.exifSensingMethod.text = [NSString stringWithFormat:@"%@", exifSensingMethod];
                         
                         NSDecimalNumber *exifFileSource = CFDictionaryGetValue(exif, kCGImagePropertyExifFileSource);
                         self.exifFileSource.text = [NSString stringWithFormat:@"%@", exifFileSource];
                         
                         NSDecimalNumber *exifSceneType = CFDictionaryGetValue(exif, kCGImagePropertyExifSceneType);
                         self.exifSceneType.text = [NSString stringWithFormat:@"%@", exifSceneType];
                         
                         NSDecimalNumber *exifCFAPattern = CFDictionaryGetValue(exif, kCGImagePropertyExifCFAPattern);
                         self.exifCFAPattern.text = [NSString stringWithFormat:@"%@", exifCFAPattern];
                         
                         NSDecimalNumber *exifCustomRendered = CFDictionaryGetValue(exif, kCGImagePropertyExifCustomRendered);
                         self.exifCustomRendered.text = [NSString stringWithFormat:@"%@", exifCustomRendered];
                         
                         NSDecimalNumber *exifExposureMode = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureMode);
                         self.exifExposureMode.text = [NSString stringWithFormat:@"%@", exifExposureMode];
                         
                         NSDecimalNumber *exifWhiteBalance = CFDictionaryGetValue(exif, kCGImagePropertyExifWhiteBalance);
                         self.exifWhiteBalance.text = [NSString stringWithFormat:@"%@", exifWhiteBalance];
                         
                         NSDecimalNumber *exifDigitalZoomRatio = CFDictionaryGetValue(exif, kCGImagePropertyExifDigitalZoomRatio);
                         self.exifDigitalZoomRatio.text = [NSString stringWithFormat:@"%@", exifDigitalZoomRatio];
                         
                         NSDecimalNumber *exifFocalLenIn35mmFilm = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalLenIn35mmFilm);
                         self.exifFocalLenIn35mmFilm.text = [NSString stringWithFormat:@"%@", exifFocalLenIn35mmFilm];
                         
                         NSDecimalNumber *exifSceneCaptureType = CFDictionaryGetValue(exif, kCGImagePropertyExifSceneCaptureType);
                         self.exifSceneCaptureType.text = [NSString stringWithFormat:@"%@", exifSceneCaptureType];
                         
                         NSDecimalNumber *exifGainControl = CFDictionaryGetValue(exif, kCGImagePropertyExifGainControl);
                         self.exifGainControl.text = [NSString stringWithFormat:@"%@", exifGainControl];
                         
                         NSDecimalNumber *exifContrast = CFDictionaryGetValue(exif, kCGImagePropertyExifContrast);
                         self.exifContrast.text = [NSString stringWithFormat:@"%@", exifContrast];
                         
                         NSDecimalNumber *exifSaturation = CFDictionaryGetValue(exif, kCGImagePropertyExifSaturation);
                         self.exifSaturation.text = [NSString stringWithFormat:@"%@", exifSaturation];
                         
                         NSDecimalNumber *exifSharpness = CFDictionaryGetValue(exif, kCGImagePropertyExifSharpness);
                         self.exifSharpness.text = [NSString stringWithFormat:@"%@", exifSharpness];
                         
                         NSDecimalNumber *exifDeviceSettingDescription = CFDictionaryGetValue(exif, kCGImagePropertyExifDeviceSettingDescription);
                         self.exifDeviceSettingDescription.text = [NSString stringWithFormat:@"%@", exifDeviceSettingDescription];
                         
                         NSDecimalNumber *exifSubjectDistRange = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectDistRange);
                         self.exifSubjectDistRange.text = [NSString stringWithFormat:@"%@", exifSubjectDistRange];
                         
                         NSDecimalNumber *exifImageUniqueID = CFDictionaryGetValue(exif, kCGImagePropertyExifImageUniqueID);
                         self.exifImageUniqueID.text = [NSString stringWithFormat:@"%@", exifImageUniqueID];
                         
                         NSDecimalNumber *exifGamma = CFDictionaryGetValue(exif, kCGImagePropertyExifGamma);
                         self.exifGamma.text = [NSString stringWithFormat:@"%@", exifGamma];
                         
                         NSDecimalNumber *exifCameraOwnerName = CFDictionaryGetValue(exif, kCGImagePropertyExifCameraOwnerName);
                         self.exifCameraOwnerName.text = [NSString stringWithFormat:@"%@", exifCameraOwnerName];
                         
                         NSDecimalNumber *exifBodySerialNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifBodySerialNumber);
                         self.exifBodySerialNumber.text = [NSString stringWithFormat:@"%@", exifBodySerialNumber];
                         
                         NSDecimalNumber *exifLensSpecification = CFDictionaryGetValue(exif, kCGImagePropertyExifLensSpecification);
                         self.exifLensSpecification.text = [NSString stringWithFormat:@"%@", exifLensSpecification];
                         
                         NSDecimalNumber *exifLensMake = CFDictionaryGetValue(exif, kCGImagePropertyExifLensMake);
                         self.exifLensMake.text = [NSString stringWithFormat:@"%@", exifLensMake];
                         
                         NSDecimalNumber *exifLensModel = CFDictionaryGetValue(exif, kCGImagePropertyExifLensModel);
                         self.exifLensModel.text = [NSString stringWithFormat:@"%@", exifLensModel];
                         
                         NSDecimalNumber *exifLensSerialNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifLensSerialNumber);
                         self.exifLensSerialNumber.text = [NSString stringWithFormat:@"%@", exifLensSerialNumber];
                     }
                     
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
                     
                     if(gps_dict) {
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
                     }
                     
                     
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

- (void)imageZoomPressed {
    self.imageZoom = [[XLMediaZoom alloc] initWithAnimationTime:@(0.5) image:self.imageView blurEffect:YES];
    [self.view addSubview:self.imageZoom];
    [self.imageZoom show];
}

CGPoint pointFromRectangle(CGRect rect) {
    
    return CGPointMake(0, rect.origin.y-200);
}

// Focuses to the text field being edited
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"did begin editing");
    
//    [self.width becomeFirstResponder];
    [self.scrollView setContentOffset:(pointFromRectangle(textField.frame)) animated:YES];
    }

//- (void)textFieldDidEndEditing:(UITextField *)textField {
//    NSLog(@"just finished editing");
//}

// Goes to the next text field when Next is pressed
-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if(textField == self.fileName) {
        [self.width becomeFirstResponder];
    }
    if(textField == self.width) {
        [self.height becomeFirstResponder];
    }
    else if(textField == self.height) {
        [self.fileSize becomeFirstResponder];
    }
    else if(textField == self.fileSize) {
        [self.dateTimeDigitized becomeFirstResponder];
    }
    else if(textField == self.dateTimeDigitized) {
        [self.exifExposureTime becomeFirstResponder];
    }
    else if(textField == self.exifExposureTime) {
        [self.exifFNumber becomeFirstResponder];
    }
    else if(textField == self.exifFNumber) {
        [self.exifExposureProgram becomeFirstResponder];
    }
    else if(textField == self.exifExposureProgram) {
        [self.exifSpectralSensitivity becomeFirstResponder];
    }
    else if(textField == self.exifSpectralSensitivity) {
        [self.exifISOSpeedRatings becomeFirstResponder];
    }
    else if(textField == self.exifISOSpeedRatings) {
        [self.exifOECF becomeFirstResponder];
    }
    else if(textField == self.exifOECF) {
        [self.exifVersion becomeFirstResponder];
    }
    else if(textField == self.exifVersion) {
        [self.exifComponentsConfiguration becomeFirstResponder];
    }
    else if(textField == self.exifComponentsConfiguration) {
        [self.exifShutterSpeedValue becomeFirstResponder];
    }
    else if(textField == self.exifShutterSpeedValue) {
        [self.exifApertureValue becomeFirstResponder];
    }
    else if(textField == self.exifApertureValue) {
        [self.exifBrightnessValue becomeFirstResponder];
    }
    else if(textField == self.exifBrightnessValue) {
        [self.exifExposureBiasValue becomeFirstResponder];
    }
    else if(textField == self.exifExposureBiasValue) {
        [self.exifMaxApertureValue becomeFirstResponder];
    }
    else if(textField == self.exifMaxApertureValue) {
        [self.exifSubjectDistance becomeFirstResponder];
    }
    else if(textField == self.exifSubjectDistance) {
        [self.exifMeteringMode becomeFirstResponder];
    }
    else if(textField == self.exifMeteringMode) {
        [self.exifLightSource becomeFirstResponder];
    }
    else if(textField == self.exifLightSource) {
        [self.exifFlash becomeFirstResponder];
    }
    else if(textField == self.exifFlash) {
        [self.exifFocalLength becomeFirstResponder];
    }
    else if(textField == self.exifFocalLength) {
        [self.exifSubjectArea becomeFirstResponder];
    }
    else if(textField == self.exifSubjectArea) {
        [self.exifMakerNote becomeFirstResponder];
    }
    else if(textField == self.exifMakerNote) {
        [self.exifUserComment becomeFirstResponder];
    }
    else if(textField == self.exifUserComment) {
        [self.exifSubsecTime becomeFirstResponder];
    }
    else if(textField == self.exifSubsecTime) {
        [self.exifSubsecTimeOrginal becomeFirstResponder];
    }
    else if(textField == self.exifSubsecTimeOrginal) {
        [self.exifSubsecTimeDigitized becomeFirstResponder];
    }
    else if(textField == self.exifSubsecTimeDigitized) {
        [self.exifFlashPixVersion becomeFirstResponder];
    }
    else if(textField == self.exifFlashPixVersion) {
        [self.exifColorSpace becomeFirstResponder];
    }
    else if(textField == self.exifColorSpace) {
        [self.exifPixelXDimension becomeFirstResponder];
    }
    else if(textField == self.exifPixelXDimension) {
        [self.exifPixelYDimension becomeFirstResponder];
    }
    else if(textField == self.exifPixelYDimension) {
        [self.exifRelatedSoundFile becomeFirstResponder];
    }
    else if(textField == self.exifRelatedSoundFile) {
        [self.exifFlashEnergy becomeFirstResponder];
    }
    else if(textField == self.exifFlashEnergy) {
        [self.exifSpatialFrequencyResponse becomeFirstResponder];
    }
    else if(textField == self.exifSpatialFrequencyResponse) {
        [self.exifFocalPlaneXResolution becomeFirstResponder];
    }
    else if(textField == self.exifFocalPlaneXResolution) {
        [self.exifFocalPlaneYResolution becomeFirstResponder];
    }
    else if(textField == self.exifFocalPlaneYResolution) {
        [self.exifFocalPlaneResolutionUnit becomeFirstResponder];
    }
    else if(textField == self.exifFocalPlaneResolutionUnit) {
        [self.exifSubjectLocation becomeFirstResponder];
    }
    else if(textField == self.exifSubjectLocation) {
        [self.exifExposureIndex becomeFirstResponder];
    }
    else if(textField == self.exifExposureIndex) {
        [self.exifSensingMethod becomeFirstResponder];
    }
    else if(textField == self.exifSensingMethod) {
        [self.exifFileSource becomeFirstResponder];
    }
    else if(textField == self.exifFileSource) {
        [self.exifSceneType becomeFirstResponder];
    }
    else if(textField == self.exifSceneType) {
        [self.exifCFAPattern becomeFirstResponder];
    }
    else if(textField == self.exifCFAPattern) {
        [self.exifCustomRendered becomeFirstResponder];
    }
    else if(textField == self.exifCustomRendered) {
        [self.exifExposureMode becomeFirstResponder];
    }
    else if(textField == self.exifExposureMode) {
        [self.exifWhiteBalance becomeFirstResponder];
    }
    else if(textField == self.exifWhiteBalance) {
        [self.exifDigitalZoomRatio becomeFirstResponder];
    }
    else if(textField == self.exifDigitalZoomRatio) {
        [self.exifFocalLenIn35mmFilm becomeFirstResponder];
    }
    else if(textField == self.exifFocalLenIn35mmFilm) {
        [self.exifSceneCaptureType becomeFirstResponder];
    }
    else if(textField == self.exifSceneCaptureType) {
        [self.exifGainControl becomeFirstResponder];
    }
    else if(textField == self.exifGainControl) {
        [self.exifContrast becomeFirstResponder];
    }
    else if(textField == self.exifContrast) {
        [self.exifSaturation becomeFirstResponder];
    }
    else if(textField == self.exifSaturation) {
        [self.exifSharpness becomeFirstResponder];
    }
    else if(textField == self.exifSharpness) {
        [self.exifDeviceSettingDescription becomeFirstResponder];
    }
    else if(textField == self.exifDeviceSettingDescription) {
        [self.exifSubjectDistRange becomeFirstResponder];
    }
    else if(textField == self.exifSubjectDistRange) {
        [self.exifImageUniqueID becomeFirstResponder];
    }
    else if(textField == self.exifImageUniqueID) {
        [self.exifGamma becomeFirstResponder];
    }
    else if(textField == self.exifGamma) {
        [self.exifCameraOwnerName becomeFirstResponder];
    }
    else if(textField == self.exifCameraOwnerName) {
        [self.exifBodySerialNumber becomeFirstResponder];
    }
    else if(textField == self.exifBodySerialNumber) {
        [self.exifLensSpecification becomeFirstResponder];
    }
    else if(textField == self.exifLensSpecification) {
        [self.exifLensMake becomeFirstResponder];
    }
    else if(textField == self.exifLensMake) {
        [self.exifLensModel becomeFirstResponder];
    }
    else if(textField == self.exifLensModel) {
        [self.exifLensSerialNumber becomeFirstResponder];
    }
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //    self.view.backgroundColor = [UIColor whiteColor];
    //    self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    self.view.backgroundColor = UIColorFromRGB(0x99d0f6);
    
    
    UITapGestureRecognizer *tapOnView = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapOnView];
    
    //    UITapGestureRecognizer *focus = [[UITapGestureRecognizer alloc]
    //                                         initWithTarget:self
    //                                         action:@selector(focusOnTextField)];
    //    [self.view addGestureRecognizer:focus];
    
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height*6)];
    [self.view addSubview:self.scrollView];
    
    // Width of scroll view
    CGFloat w = self.scrollView.bounds.size.width;
    CGFloat h = self.scrollView.bounds.size.height;
    NSLog(@"%f", w);
    
    // Take picture button
    UIButton *takePicture = [UIButton buttonWithType:UIButtonTypeCustom];
    takePicture.frame = CGRectMake(0, 10.0, w/5, w/5);
    UIImage *takePictureImage = [UIImage imageNamed:@"CameraIconC.png"];
    [takePicture setImage:takePictureImage forState:UIControlStateNormal];
    [takePicture addTarget:self
                    action:@selector(takePicture:)
          forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:takePicture];
    
    // New image button
    UIButton *chooseNewImage = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseNewImage.frame = CGRectMake(w/5, 10.0, w/5, w/5);
    UIImage *chooseNewImageImage = [UIImage imageNamed:@"PhotoIconC.png"];
    [chooseNewImage setImage:chooseNewImageImage forState:UIControlStateNormal];
    [chooseNewImage addTarget:self
                       action:@selector(newImageButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:chooseNewImage];
    
    // Reset to actual
    UIButton *resetExif = [UIButton buttonWithType:UIButtonTypeCustom];
    resetExif.frame = CGRectMake(2*w/5, 10.0, w/5, w/5);
    UIImage *resetExifImage = [UIImage imageNamed:@"ResetIconC.png"];
    [resetExif setImage:resetExifImage forState:UIControlStateNormal];
    [resetExif addTarget:self
                  action:@selector(resetExif:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetExif];
    
    // Delete all
    UIButton *eraseExif = [UIButton buttonWithType:UIButtonTypeCustom];
    eraseExif.frame = CGRectMake(3*w/5, 10.0, w/5, w/5);
    UIImage *eraseExifImage = [UIImage imageNamed:@"EraseIconC.png"];
    [eraseExif setImage:eraseExifImage forState:UIControlStateNormal];
    [eraseExif addTarget:self
                  action:@selector(eraseExif:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:eraseExif];
    
    // Button for saving the modified image
    UIButton *saveExif = [UIButton buttonWithType:UIButtonTypeCustom];
    saveExif.frame = CGRectMake(4*w/5, 10.0, w/5, w/5);
    UIImage *saveExifImage = [UIImage imageNamed:@"SaveIconC.png"];
    [saveExif setImage:saveExifImage forState:UIControlStateNormal];
    [saveExif addTarget:self
                 action:@selector(saveButtonPressed:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveExif];
    
    // Image view
    self.imageView = [[UIImageView alloc] init];
    self.imageView.frame = CGRectMake(20, 100, self.scrollView.bounds.size.width-40, 200);
    // Aspect fit from http://stackoverflow.com/questions/15499376/uiimageview-aspect-fit-and-center
    [self.scrollView addSubview:self.imageView];
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    // When the image is selected, zoom in on it full screen
    UITapGestureRecognizer *newTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageZoomPressed)];
    [self.imageView setUserInteractionEnabled:YES];
    [self.imageView addGestureRecognizer:newTap];
    
    // Table view to hold the data
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 376, w, h*6-420)];
    [self.scrollView addSubview:self.tableView];
    
    // Exif title banner
    UIView *exifTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 332, w, 44)];
    exifTitle.backgroundColor = UIColorFromRGB(0x1b81c8);
    [self.scrollView addSubview:exifTitle];
    
    // Exif title banner text
    UILabel *exifTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/2-20, 344, 40, 20)];
    exifTitleLabel.text = @"EXIF";
    exifTitleLabel.textColor = [UIColor whiteColor];
    [self.scrollView addSubview:exifTitleLabel];
    
    // File name label
    UILabel *fileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 388, 400, 20)];
    fileNameLabel.text = @"File name";
    fileNameLabel.textColor = [UIColor grayColor];
    [fileNameLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:fileNameLabel];
    
    // File name
    self.fileName = [[UITextField alloc] init];
    self.fileName.delegate = self;
    self.fileName.frame = CGRectMake(w/2, 388, 400, 20);
    self.fileName.keyboardAppearance = UIKeyboardAppearanceDark;
    self.fileName.textColor = [UIColor blackColor];
    [self.fileName setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.fileName];
    
    // Width label
    UILabel *widthLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 432, 400, 20)];
    widthLabel.text = @"Width";
    widthLabel.textColor = [UIColor grayColor];
    [widthLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:widthLabel];
    
    // Width
    self.width = [[UITextField alloc] init];
    self.width.delegate = self;
    self.width.frame = CGRectMake(w/2, 432, 400, 20);
    self.width.keyboardAppearance = UIKeyboardAppearanceDark;
    self.width.textColor = [UIColor blackColor];
    [self.width setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.width];
    
    // Height label
    UILabel *heightLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 476, 400, 20)];
    heightLabel.text = @"Height";
    heightLabel.textColor = [UIColor grayColor];
    [heightLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:heightLabel];
    
    // Height
    self.height = [[UITextField alloc] init];
    self.height.delegate = self;
    self.height.frame = CGRectMake(w/2, 476, 400, 20);
    self.height.keyboardAppearance = UIKeyboardAppearanceDark;
    self.height.textColor = [UIColor blackColor];
    [self.height setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.height];
    
    // File size label
    UILabel *fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 520, 400, 20)];
    fileSizeLabel.text = @"File size";
    fileSizeLabel.textColor = [UIColor grayColor];
    [fileSizeLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:fileSizeLabel];
    
    // File size
    self.fileSize = [[UITextField alloc] init];
    self.fileSize.delegate = self;
    self.fileSize.frame = CGRectMake(w/2, 520, 400, 20);
    self.fileSize.keyboardAppearance = UIKeyboardAppearanceDark;
    self.fileSize.textColor = [UIColor blackColor];
    [self.height setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.fileSize];
    
    // Date label. created or modified?
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 564, 400, 20)];
    dateLabel.text = @"Date created";
    dateLabel.textColor = [UIColor grayColor];
    [dateLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:dateLabel];
    
    // Date
    self.dateTimeDigitized = [[UITextField alloc] init];
    self.dateTimeDigitized.delegate = self;
    self.dateTimeDigitized.frame = CGRectMake(w/2, 564, 400, 20);
    self.dateTimeDigitized.keyboardAppearance = UIKeyboardAppearanceDark;
    self.dateTimeDigitized.textColor = [UIColor blackColor];
    [self.dateTimeDigitized setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.dateTimeDigitized];
    
    // Exif exposure time label
    UILabel *exifExposureTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 608, 400, 20)];
    exifExposureTimeLabel.text = @"Exposure time";
    exifExposureTimeLabel.textColor = [UIColor grayColor];
    [exifExposureTimeLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureTimeLabel];
    
    // Exif exposure time
    self.exifExposureTime = [[UITextField alloc] init];
    self.exifExposureTime.delegate = self;
    self.exifExposureTime.frame = CGRectMake(w/2, 608, 400, 20);
    self.exifExposureTime.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureTime.textColor = [UIColor blackColor];
    [self.exifExposureTime setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureTime];
    
    // F number label
    UILabel *exifFNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 652, 400, 20)];
    exifFNumberLabel.text = @"F number";
    exifFNumberLabel.textColor = [UIColor grayColor];
    [exifFNumberLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFNumberLabel];
    
    // F number
    self.exifFNumber = [[UITextField alloc] init];
    self.exifFNumber.delegate = self;
    self.exifFNumber.frame = CGRectMake(w/2, 652, 400, 20);
    self.exifFNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFNumber.textColor = [UIColor blackColor];
    [self.exifFNumber setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFNumber];
    
    // Exposure program label
    UILabel *exifExposureProgram = [[UILabel alloc] initWithFrame:CGRectMake(10, 696, 400, 20)];
    exifExposureProgram.text = @"Exposure program";
    exifExposureProgram.textColor = [UIColor grayColor];
    [exifExposureProgram setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureProgram];
    
    // Exposure program
    self.exifExposureProgram = [[UITextField alloc] init];
    self.exifExposureProgram.delegate = self;
    self.exifExposureProgram.frame = CGRectMake(w/2, 696, 400, 20);
    self.exifExposureProgram.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureProgram.textColor = [UIColor blackColor];
    [self.exifExposureProgram setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureProgram];
    
    // Spectral sensitivity label
    UILabel *exifSpectralSensitivity = [[UILabel alloc] initWithFrame:CGRectMake(10, 740, 400, 20)];
    exifSpectralSensitivity.text = @"Spectral sensitivity";
    exifSpectralSensitivity.textColor = [UIColor grayColor];
    [exifSpectralSensitivity setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSpectralSensitivity];
    
    // Spectral sensitivity
    self.exifSpectralSensitivity = [[UITextField alloc] init];
    self.exifSpectralSensitivity.delegate = self;
    self.exifSpectralSensitivity.frame = CGRectMake(w/2, 740, 400, 20);
    self.exifSpectralSensitivity.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSpectralSensitivity.textColor = [UIColor blackColor];
    [self.exifSpectralSensitivity setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSpectralSensitivity];
    
    // ISO speed ratings label
    UILabel *exifISOSpeedRatings = [[UILabel alloc] initWithFrame:CGRectMake(10, 784, 400, 20)];
    exifISOSpeedRatings.text = @"ISO speed rating";
    exifISOSpeedRatings.textColor = [UIColor grayColor];
    [exifISOSpeedRatings setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifISOSpeedRatings];
    
    // ISO speed ratings
    self.exifISOSpeedRatings = [[UITextField alloc] init];
    self.exifISOSpeedRatings.delegate = self;
    self.exifISOSpeedRatings.frame = CGRectMake(w/2, 784, 400, 20);
    self.exifISOSpeedRatings.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifISOSpeedRatings.textColor = [UIColor blackColor];
    [self.exifSpectralSensitivity setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifISOSpeedRatings];
    
    // OECF label
    UILabel *exifOECF = [[UILabel alloc] initWithFrame:CGRectMake(10, 828, 400, 20)];
    exifOECF.text = @"OECF";
    exifOECF.textColor = [UIColor grayColor];
    [exifOECF setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifOECF];
    
    // OECF
    self.exifOECF = [[UITextField alloc] init];
    self.exifOECF.delegate = self;
    self.exifOECF.frame = CGRectMake(w/2, 828, 400, 20);
    self.exifOECF.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifOECF.textColor = [UIColor blackColor];
    [self.exifOECF setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifOECF];
    
    // Version label
    UILabel *exifVersion = [[UILabel alloc] initWithFrame:CGRectMake(10, 872, 400, 20)];
    exifVersion.text = @"Version";
    exifVersion.textColor = [UIColor grayColor];
    [exifVersion setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifVersion];
    
    // Version
    self.exifVersion = [[UITextField alloc] init];
    self.exifVersion.delegate = self;
    self.exifVersion.frame = CGRectMake(w/2, 872, 400, 20);
    self.exifVersion.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifVersion.textColor = [UIColor blackColor];
    [self.exifVersion setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifVersion];
    
    // Components configuration label
    UILabel *exifComponentsConfiguration = [[UILabel alloc] initWithFrame:CGRectMake(10, 916, 400, 20)];
    exifComponentsConfiguration.text = @"Components configuration";
    exifComponentsConfiguration.textColor = [UIColor grayColor];
    [exifComponentsConfiguration setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifComponentsConfiguration];
    
    // Components configuration
    self.exifComponentsConfiguration = [[UITextField alloc] init];
    self.exifComponentsConfiguration.delegate = self;
    self.exifComponentsConfiguration.frame = CGRectMake(w/2, 916, 400, 20);
    self.exifComponentsConfiguration.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifComponentsConfiguration.textColor = [UIColor blackColor];
    [self.exifComponentsConfiguration setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifComponentsConfiguration];
    
    // Shutter speed value label
    UILabel *exifShutterSpeedValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 960, 400, 20)];
    exifShutterSpeedValue.text = @"Shutter speed value";
    exifShutterSpeedValue.textColor = [UIColor grayColor];
    [exifShutterSpeedValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifShutterSpeedValue];
    
    // Shutter speed value
    self.exifShutterSpeedValue = [[UITextField alloc] init];
    self.exifShutterSpeedValue.delegate = self;
    self.exifShutterSpeedValue.frame = CGRectMake(w/2, 960, 400, 20);
    self.exifShutterSpeedValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifShutterSpeedValue.textColor = [UIColor blackColor];
    [self.exifShutterSpeedValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifShutterSpeedValue];
    
    // Aperture value label
    UILabel *exifApertureValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1004, 400, 20)];
    exifApertureValue.text = @"Aperture value";
    exifApertureValue.textColor = [UIColor grayColor];
    [exifApertureValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifApertureValue];
    
    // Aperture value
    self.exifApertureValue = [[UITextField alloc] init];
    self.exifApertureValue.delegate = self;
    self.exifApertureValue.frame = CGRectMake(w/2, 1004, 400, 20);
    self.exifApertureValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifApertureValue.textColor = [UIColor blackColor];
    [self.exifApertureValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifApertureValue];
    
    // Brightness value label
    UILabel *exifBrightnessValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1048, 400, 20)];
    exifBrightnessValue.text = @"Brightness value";
    exifBrightnessValue.textColor = [UIColor grayColor];
    [exifBrightnessValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifBrightnessValue];
    
    // Brightness value
    self.exifBrightnessValue = [[UITextField alloc] init];
    self.exifBrightnessValue.delegate = self;
    self.exifBrightnessValue.frame = CGRectMake(w/2, 1048, 400, 20);
    self.exifBrightnessValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifBrightnessValue.textColor = [UIColor blackColor];
    [self.exifBrightnessValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifBrightnessValue];
    
    // Exposure bias value label
    UILabel *exifExposureBiasValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1092, 400, 20)];
    exifExposureBiasValue.text = @"Exposure bias value";
    exifExposureBiasValue.textColor = [UIColor grayColor];
    [exifExposureBiasValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureBiasValue];
    
    // Exposure bias value
    self.exifExposureBiasValue = [[UITextField alloc] init];
    self.exifExposureBiasValue.delegate = self;
    self.exifExposureBiasValue.frame = CGRectMake(w/2, 1092, 400, 20);
    self.exifExposureBiasValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureBiasValue.textColor = [UIColor blackColor];
    [self.exifExposureBiasValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureBiasValue];
    
    // Max aperture value label
    UILabel *exifMaxApertureValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1136, 400, 20)];
    exifMaxApertureValue.text = @"Max aperture value";
    exifMaxApertureValue.textColor = [UIColor grayColor];
    [exifMaxApertureValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMaxApertureValue];
    
    // Max aperture value
    self.exifMaxApertureValue = [[UITextField alloc] init];
    self.exifMaxApertureValue.delegate = self;
    self.exifMaxApertureValue.frame = CGRectMake(w/2, 1136, 400, 20);
    self.exifMaxApertureValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMaxApertureValue.textColor = [UIColor blackColor];
    [self.exifMaxApertureValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMaxApertureValue];
    
    // Subject distance label
    UILabel *exifSubjectDistance = [[UILabel alloc] initWithFrame:CGRectMake(10, 1180, 400, 20)];
    exifSubjectDistance.text = @"Subject distance";
    exifSubjectDistance.textColor = [UIColor grayColor];
    [exifSubjectDistance setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectDistance];
    
    // Subject distance
    self.exifSubjectDistance = [[UITextField alloc] init];
    self.exifSubjectDistance.delegate = self;
    self.exifSubjectDistance.frame = CGRectMake(w/2, 1180, 400, 20);
    self.exifSubjectDistance.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectDistance.textColor = [UIColor blackColor];
    [self.exifSubjectDistance setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectDistance];
    
    // Metering mode label
    UILabel *exifMeteringMode = [[UILabel alloc] initWithFrame:CGRectMake(10, 1224, 400, 20)];
    exifMeteringMode.text = @"Metering mode";
    exifMeteringMode.textColor = [UIColor grayColor];
    [exifMeteringMode setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMeteringMode];
    
    // Metering mode
    self.exifMeteringMode = [[UITextField alloc] init];
    self.exifMeteringMode.delegate = self;
    self.exifMeteringMode.frame = CGRectMake(w/2, 1224, 400, 20);
    self.exifMeteringMode.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMeteringMode.textColor = [UIColor blackColor];
    [self.exifMeteringMode setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMeteringMode];
    
    // Light source label
    UILabel *exifLightSource = [[UILabel alloc] initWithFrame:CGRectMake(10, 1268, 400, 20)];
    exifLightSource.text = @"Light source";
    exifLightSource.textColor = [UIColor grayColor];
    [exifLightSource setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLightSource];
    
    // Light source
    self.exifLightSource = [[UITextField alloc] init];
    self.exifLightSource.delegate = self;
    self.exifLightSource.frame = CGRectMake(w/2, 1268, 400, 20);
    self.exifLightSource.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLightSource.textColor = [UIColor blackColor];
    [self.exifLightSource setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLightSource];
    
    // Flash label
    UILabel *exifFlash = [[UILabel alloc] initWithFrame:CGRectMake(10, 1312, 400, 20)];
    exifFlash.text = @"Flash";
    exifFlash.textColor = [UIColor grayColor];
    [exifFlash setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFlash];
    
    // Flash
    self.exifFlash = [[UITextField alloc] init];
    self.exifFlash.delegate = self;
    self.exifFlash.frame = CGRectMake(w/2, 1312, 400, 20);
    self.exifFlash.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlash.textColor = [UIColor blackColor];
    [self.exifFlash setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFlash];
    
    // Focal length label
    UILabel *exifFocalLength = [[UILabel alloc] initWithFrame:CGRectMake(10, 1356, 400, 20)];
    exifFocalLength.text = @"Focal length";
    exifFocalLength.textColor = [UIColor grayColor];
    [exifFocalLength setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalLength];
    
    // Focal length
    self.exifFocalLength = [[UITextField alloc] init];
    self.exifFocalLength.delegate = self;
    self.exifFocalLength.frame = CGRectMake(w/2, 1356, 400, 20);
    self.exifFocalLength.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalLength.textColor = [UIColor blackColor];
    [self.exifFocalLength setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalLength];
    
    // Subject area label
    UILabel *exifSubjectArea = [[UILabel alloc] initWithFrame:CGRectMake(10, 1400, 400, 20)];
    exifSubjectArea.text = @"Subject area";
    exifSubjectArea.textColor = [UIColor grayColor];
    [exifSubjectArea setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectArea];
    
    // Subject area
    self.exifSubjectArea = [[UITextField alloc] init];
    self.exifSubjectArea.delegate = self;
    self.exifSubjectArea.frame = CGRectMake(w/2, 1400, 400, 20);
    self.exifSubjectArea.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectArea.textColor = [UIColor blackColor];
    [self.exifSubjectArea setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectArea];
    
    // Maker note label
    UILabel *exifMakerNote = [[UILabel alloc] initWithFrame:CGRectMake(10, 1444, 400, 20)];
    exifMakerNote.text = @"Maker note";
    exifMakerNote.textColor = [UIColor grayColor];
    [exifMakerNote setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMakerNote];
    
    // Maker note
    self.exifMakerNote = [[UITextField alloc] init];
    self.exifMakerNote.delegate = self;
    self.exifMakerNote.frame = CGRectMake(w/2, 1444, 400, 20);
    self.exifMakerNote.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMakerNote.textColor = [UIColor blackColor];
    [self.exifMakerNote setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMakerNote];
    
    // User comment label
    UILabel *exifUserComment = [[UILabel alloc] initWithFrame:CGRectMake(10, 1488, 400, 20)];
    exifUserComment.text = @"User comment";
    exifUserComment.textColor = [UIColor grayColor];
    [exifUserComment setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifUserComment];
    
    // User comment
    self.exifUserComment = [[UITextField alloc] init];
    self.exifUserComment.delegate = self;
    self.exifUserComment.frame = CGRectMake(w/2, 1488, 400, 20);
    self.exifUserComment.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifUserComment.textColor = [UIColor blackColor];
    [self.exifUserComment setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifUserComment];
    
    // Subsec time label
    UILabel *exifSubsecTime = [[UILabel alloc] initWithFrame:CGRectMake(10, 1532, 400, 20)];
    exifSubsecTime.text = @"Subsec Time";
    exifSubsecTime.textColor = [UIColor grayColor];
    [exifSubsecTime setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTime];
    
    // Subsec time
    self.exifSubsecTime = [[UITextField alloc] init];
    self.exifSubsecTime.delegate = self;
    self.exifSubsecTime.frame = CGRectMake(w/2, 1532, 400, 20);
    self.exifSubsecTime.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTime.textColor = [UIColor blackColor];
    [self.exifSubsecTime setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTime];
    
    // Subsec time original label
    UILabel *exifSubsecTimeOrginal = [[UILabel alloc] initWithFrame:CGRectMake(10, 1576, 400, 20)];
    exifSubsecTimeOrginal.text = @"Subsec Time Original";
    exifSubsecTimeOrginal.textColor = [UIColor grayColor];
    [exifSubsecTimeOrginal setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTimeOrginal];
    
    // Subsec time original
    self.exifSubsecTimeOrginal = [[UITextField alloc] init];
    self.exifSubsecTimeOrginal.delegate = self;
    self.exifSubsecTimeOrginal.frame = CGRectMake(w/2, 1576, 400, 20);
    self.exifSubsecTimeOrginal.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTimeOrginal.textColor = [UIColor blackColor];
    [self.exifSubsecTimeOrginal setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTimeOrginal];
    
    // Subsec time digitized label
    UILabel *exifSubsecTimeDigitized = [[UILabel alloc] initWithFrame:CGRectMake(10, 1620, 400, 20)];
    exifSubsecTimeDigitized.text = @"Subsec Time Digitized";
    exifSubsecTimeDigitized.textColor = [UIColor grayColor];
    [exifSubsecTimeDigitized setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTimeDigitized];
    
    // Subsec time digitized
    self.exifSubsecTimeDigitized = [[UITextField alloc] init];
    self.exifSubsecTimeDigitized.delegate = self;
    self.exifSubsecTimeDigitized.frame = CGRectMake(w/2, 1620, 400, 20);
    self.exifSubsecTimeDigitized.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTimeDigitized.textColor = [UIColor blackColor];
    [self.exifSubsecTimeDigitized setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTimeDigitized];
    
    // Flash pix version label
    UILabel *exifFlashPixVersion = [[UILabel alloc] initWithFrame:CGRectMake(10, 1664, 400, 20)];
    exifFlashPixVersion.text = @"FlashPix version";
    exifFlashPixVersion.textColor = [UIColor grayColor];
    [exifFlashPixVersion setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFlashPixVersion];
    
    // Flash pix version
    self.exifFlashPixVersion = [[UITextField alloc] init];
    self.exifFlashPixVersion.delegate = self;
    self.exifFlashPixVersion.frame = CGRectMake(w/2, 1664, 400, 20);
    self.exifFlashPixVersion.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlashPixVersion.textColor = [UIColor blackColor];
    [self.exifFlashPixVersion setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFlashPixVersion];
    
    // Color space label
    UILabel *exifColorSpace = [[UILabel alloc] initWithFrame:CGRectMake(10, 1708, 400, 20)];
    exifColorSpace.text = @"Color space";
    exifColorSpace.textColor = [UIColor grayColor];
    [exifColorSpace setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifColorSpace];
    
    // Color space
    self.exifColorSpace = [[UITextField alloc] init];
    self.exifColorSpace.delegate = self;
    self.exifColorSpace.frame = CGRectMake(w/2, 1708, 400, 20);
    self.exifColorSpace.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifColorSpace.textColor = [UIColor blackColor];
    [self.exifColorSpace setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifColorSpace];
    
    // Pixel X dimension label
    UILabel *exifPixelXDimension = [[UILabel alloc] initWithFrame:CGRectMake(10, 1752, 400, 20)];
    exifPixelXDimension.text = @"Pixel X dimension";
    exifPixelXDimension.textColor = [UIColor grayColor];
    [exifPixelXDimension setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifPixelXDimension];
    
    // Pixel X dimension
    self.exifPixelXDimension = [[UITextField alloc] init];
    self.exifPixelXDimension.delegate = self;
    self.exifPixelXDimension.frame = CGRectMake(w/2, 1752, 400, 20);
    self.exifPixelXDimension.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifPixelXDimension.textColor = [UIColor blackColor];
    [self.exifPixelXDimension setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifPixelXDimension];
    
    // Pixel Y dimension label
    UILabel *exifPixelYDimension = [[UILabel alloc] initWithFrame:CGRectMake(10, 1796, 400, 20)];
    exifPixelYDimension.text = @"Pixel Y dimension";
    exifPixelYDimension.textColor = [UIColor grayColor];
    [exifPixelYDimension setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifPixelYDimension];

    // Pixel Y dimension
    self.exifPixelYDimension = [[UITextField alloc] init];
    self.exifPixelYDimension.delegate = self;
    self.exifPixelYDimension.frame = CGRectMake(w/2, 1796, 400, 20);
    self.exifPixelYDimension.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifPixelYDimension.textColor = [UIColor blackColor];
    [self.exifPixelYDimension setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifPixelYDimension];
    
    // Related sound file label
    UILabel *exifRelatedSoundFile = [[UILabel alloc] initWithFrame:CGRectMake(10, 1840, 400, 20)];
    exifRelatedSoundFile.text = @"Related sound file";
    exifRelatedSoundFile.textColor = [UIColor grayColor];
    [exifRelatedSoundFile setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifRelatedSoundFile];
    
    // Related sound file
    self.exifRelatedSoundFile = [[UITextField alloc] init];
    self.exifRelatedSoundFile.delegate = self;
    self.exifRelatedSoundFile.frame = CGRectMake(w/2, 1840, 400, 20);
    self.exifRelatedSoundFile.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifRelatedSoundFile.textColor = [UIColor blackColor];
    [self.exifRelatedSoundFile setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifRelatedSoundFile];
    
    // Flash energy label
    UILabel *exifFlashEnergy = [[UILabel alloc] initWithFrame:CGRectMake(10, 1884, 400, 20)];
    exifFlashEnergy.text = @"Flash energy";
    exifFlashEnergy.textColor = [UIColor grayColor];
    [exifFlashEnergy setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFlashEnergy];
    
    // Flash energy
    self.exifFlashEnergy = [[UITextField alloc] init];
    self.exifFlashEnergy.delegate = self;
    self.exifFlashEnergy.frame = CGRectMake(w/2, 1884, 400, 20);
    self.exifFlashEnergy.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlashEnergy.textColor = [UIColor blackColor];
    [self.exifFlashEnergy setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFlashEnergy];
    
    // Spatial frequency response label
    UILabel *exifSpatialFrequencyResponse = [[UILabel alloc] initWithFrame:CGRectMake(10, 1928, 400, 20)];
    exifSpatialFrequencyResponse.text = @"Spatial frequency response";
    exifSpatialFrequencyResponse.textColor = [UIColor grayColor];
    [exifSpatialFrequencyResponse setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSpatialFrequencyResponse];
    
    // Spatial frequency response
    self.exifSpatialFrequencyResponse = [[UITextField alloc] init];
    self.exifSpatialFrequencyResponse.delegate = self;
    self.exifSpatialFrequencyResponse.frame = CGRectMake(w/2, 1928, 400, 20);
    self.exifSpatialFrequencyResponse.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSpatialFrequencyResponse.textColor = [UIColor blackColor];
    [self.exifSpatialFrequencyResponse setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSpatialFrequencyResponse];
    
    // Focal plane X resolution label
    UILabel *exifFocalPlaneXResolution = [[UILabel alloc] initWithFrame:CGRectMake(10, 1972, 400, 20)];
    exifFocalPlaneXResolution.text = @"Focal plane X resolution";
    exifFocalPlaneXResolution.textColor = [UIColor grayColor];
    [exifFocalPlaneXResolution setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalPlaneXResolution];
    
    // Focal plane X resolution
    self.exifFocalPlaneXResolution = [[UITextField alloc] init];
    self.exifFocalPlaneXResolution.delegate = self;
    self.exifFocalPlaneXResolution.frame = CGRectMake(w/2, 1972, 400, 20);
    self.exifFocalPlaneXResolution.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneXResolution.textColor = [UIColor blackColor];
    [self.exifFocalPlaneXResolution setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalPlaneXResolution];
    
    // Focal plane Y resolution label
    UILabel *exifFocalPlaneYResolution = [[UILabel alloc] initWithFrame:CGRectMake(10, 2016, 400, 20)];
    exifFocalPlaneYResolution.text = @"Focal plane Y resolution";
    exifFocalPlaneYResolution.textColor = [UIColor grayColor];
    [exifFocalPlaneYResolution setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalPlaneYResolution];
    
    // Focal plane Y resolution
    self.exifFocalPlaneYResolution = [[UITextField alloc] init];
    self.exifFocalPlaneYResolution.delegate = self;
    self.exifFocalPlaneYResolution.frame = CGRectMake(w/2, 2016, 400, 20);
    self.exifFocalPlaneYResolution.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneYResolution.textColor = [UIColor blackColor];
    [self.exifFocalPlaneYResolution setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalPlaneYResolution];
    
    // Focal plane resolution unit label
    UILabel *exifFocalPlaneResolutionUnit = [[UILabel alloc] initWithFrame:CGRectMake(10, 2060, 400, 20)];
    exifFocalPlaneResolutionUnit.text = @"Focal plane resolution unit";
    exifFocalPlaneResolutionUnit.textColor = [UIColor grayColor];
    [exifFocalPlaneResolutionUnit setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalPlaneResolutionUnit];
    
    // Focal plane resolution unit
    self.exifFocalPlaneResolutionUnit = [[UITextField alloc] init];
    self.exifFocalPlaneResolutionUnit.delegate = self;
    self.exifFocalPlaneResolutionUnit.frame = CGRectMake(w/2, 2060, 400, 20);
    self.exifFocalPlaneResolutionUnit.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneResolutionUnit.textColor = [UIColor blackColor];
    [self.exifFocalPlaneResolutionUnit setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalPlaneResolutionUnit];
    
    // Subject location label
    UILabel *exifSubjectLocation = [[UILabel alloc] initWithFrame:CGRectMake(10, 2104, 400, 20)];
    exifSubjectLocation.text = @"Subject location";
    exifSubjectLocation.textColor = [UIColor grayColor];
    [exifSubjectLocation setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectLocation];
    
    // Subject location
    self.exifSubjectLocation = [[UITextField alloc] init];
    self.exifSubjectLocation.delegate = self;
    self.exifSubjectLocation.frame = CGRectMake(w/2, 2104, 400, 20);
    self.exifSubjectLocation.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectLocation.textColor = [UIColor blackColor];
    [self.exifSubjectLocation setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectLocation];
    
    // Exposure index label
    UILabel *exifExposureIndex = [[UILabel alloc] initWithFrame:CGRectMake(10, 2148, 400, 20)];
    exifExposureIndex.text = @"Exposure index";
    exifExposureIndex.textColor = [UIColor grayColor];
    [exifExposureIndex setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureIndex];
    
    // Exposure index
    self.exifExposureIndex = [[UITextField alloc] init];
    self.exifExposureIndex.delegate = self;
    self.exifExposureIndex.frame = CGRectMake(w/2, 2148, 400, 20);
    self.exifExposureIndex.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureIndex.textColor = [UIColor blackColor];
    [self.exifExposureIndex setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureIndex];
    
    // Sensing method label
    UILabel *exifSensingMethod = [[UILabel alloc] initWithFrame:CGRectMake(10, 2192, 400, 20)];
    exifSensingMethod.text = @"Sensing method";
    exifSensingMethod.textColor = [UIColor grayColor];
    [exifSensingMethod setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSensingMethod];
    
    // Sensing method
    self.exifSensingMethod = [[UITextField alloc] init];
    self.exifSensingMethod.delegate = self;
    self.exifSensingMethod.frame = CGRectMake(w/2, 2192, 400, 20);
    self.exifSensingMethod.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSensingMethod.textColor = [UIColor blackColor];
    [self.exifSensingMethod setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSensingMethod];
    
    // File source label
    UILabel *exifFileSource = [[UILabel alloc] initWithFrame:CGRectMake(10, 2236, 400, 20)];
    exifFileSource.text = @"File source";
    exifFileSource.textColor = [UIColor grayColor];
    [exifFileSource setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFileSource];
    
    // File source
    self.exifFileSource = [[UITextField alloc] init];
    self.exifFileSource.delegate = self;
    self.exifFileSource.frame = CGRectMake(w/2, 2236, 400, 20);
    self.exifFileSource.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFileSource.textColor = [UIColor blackColor];
    [self.exifFileSource setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFileSource];
    
    // Scene type label
    UILabel *exifSceneType = [[UILabel alloc] initWithFrame:CGRectMake(10, 2280, 400, 20)];
    exifSceneType.text = @"Scene type";
    exifSceneType.textColor = [UIColor grayColor];
    [exifSceneType setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSceneType];
    
    // Scene type
    self.exifSceneType = [[UITextField alloc] init];
    self.exifSceneType.delegate = self;
    self.exifSceneType.frame = CGRectMake(w/2, 2280, 400, 20);
    self.exifSceneType.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSceneType.textColor = [UIColor blackColor];
    [self.exifSceneType setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSceneType];
    
    // CFA pattern label
    UILabel *exifCFAPattern = [[UILabel alloc] initWithFrame:CGRectMake(10, 2324, 400, 20)];
    exifCFAPattern.text = @"CFA pattern";
    exifCFAPattern.textColor = [UIColor grayColor];
    [exifCFAPattern setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifCFAPattern];
    
    // CFA pattern
    self.exifCFAPattern = [[UITextField alloc] init];
    self.exifCFAPattern.delegate = self;
    self.exifCFAPattern.frame = CGRectMake(w/2, 2324, 400, 20);
    self.exifCFAPattern.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCFAPattern.textColor = [UIColor blackColor];
    [self.exifCFAPattern setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifCFAPattern];
    
    // Custom rendered label
    UILabel *exifCustomRendered = [[UILabel alloc] initWithFrame:CGRectMake(10, 2368, 400, 20)];
    exifCustomRendered.text = @"Custom rendered";
    exifCustomRendered.textColor = [UIColor grayColor];
    [exifCustomRendered setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifCustomRendered];
    
    // Custom rendered
    self.exifCustomRendered = [[UITextField alloc] init];
    self.exifCustomRendered.delegate = self;
    self.exifCustomRendered.frame = CGRectMake(w/2, 2368, 400, 20);
    self.exifCustomRendered.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCustomRendered.textColor = [UIColor blackColor];
    [self.exifCustomRendered setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifCustomRendered];
    
    // Exposure mode label
    UILabel *exifExposureMode = [[UILabel alloc] initWithFrame:CGRectMake(10, 2412, 400, 20)];
    exifExposureMode.text = @"Exposure mode";
    exifExposureMode.textColor = [UIColor grayColor];
    [exifExposureMode setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureMode];
    
    // Exposure mode
    self.exifExposureMode = [[UITextField alloc] init];
    self.exifExposureMode.delegate = self;
    self.exifExposureMode.frame = CGRectMake(w/2, 2412, 400, 20);
    self.exifExposureMode.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureMode.textColor = [UIColor blackColor];
    [self.exifExposureMode setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureMode];
    
    // White balance label
    UILabel *exifWhiteBalance = [[UILabel alloc] initWithFrame:CGRectMake(10, 2456, 400, 20)];
    exifWhiteBalance.text = @"White balance";
    exifWhiteBalance.textColor = [UIColor grayColor];
    [exifWhiteBalance setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifWhiteBalance];
    
    // White balance
    self.exifWhiteBalance = [[UITextField alloc] init];
    self.exifWhiteBalance.delegate = self;
    self.exifWhiteBalance.frame = CGRectMake(w/2, 2456, 400, 20);
    self.exifWhiteBalance.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifWhiteBalance.textColor = [UIColor blackColor];
    [self.exifWhiteBalance setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifWhiteBalance];
    
    // Digital zoom ratio label
    UILabel *exifDigitalZoomRatio = [[UILabel alloc] initWithFrame:CGRectMake(10, 2500, 400, 20)];
    exifDigitalZoomRatio.text = @"Digital zoom ratio";
    exifDigitalZoomRatio.textColor = [UIColor grayColor];
    [exifDigitalZoomRatio setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifDigitalZoomRatio];
    
    // Digital zoom ratio
    self.exifDigitalZoomRatio = [[UITextField alloc] init];
    self.exifDigitalZoomRatio.delegate = self;
    self.exifDigitalZoomRatio.frame = CGRectMake(w/2, 2500, 400, 20);
    self.exifDigitalZoomRatio.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifDigitalZoomRatio.textColor = [UIColor blackColor];
    [self.exifDigitalZoomRatio setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifDigitalZoomRatio];
    
    // Focal length in 35 mm label
    UILabel *exifFocalLenIn35mmFilm = [[UILabel alloc] initWithFrame:CGRectMake(10, 2544, 400, 20)];
    exifFocalLenIn35mmFilm.text = @"Focal length in 35 mm";
    exifFocalLenIn35mmFilm.textColor = [UIColor grayColor];
    [exifFocalLenIn35mmFilm setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalLenIn35mmFilm];
    
    // Focal length in 35 mm
    self.exifFocalLenIn35mmFilm = [[UITextField alloc] init];
    self.exifFocalLenIn35mmFilm.delegate = self;
    self.exifFocalLenIn35mmFilm.frame = CGRectMake(w/2, 2544, 400, 20);
    self.exifFocalLenIn35mmFilm.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalLenIn35mmFilm.textColor = [UIColor blackColor];
    [self.exifFocalLenIn35mmFilm setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalLenIn35mmFilm];
    
    // Scene capture type label
    UILabel *exifSceneCaptureType = [[UILabel alloc] initWithFrame:CGRectMake(10, 2588, 400, 20)];
    exifSceneCaptureType.text = @"Scene capture type";
    exifSceneCaptureType.textColor = [UIColor grayColor];
    [exifSceneCaptureType setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSceneCaptureType];
    
    // Scene capture type
    self.exifSceneCaptureType = [[UITextField alloc] init];
    self.exifSceneCaptureType.delegate = self;
    self.exifSceneCaptureType.frame = CGRectMake(w/2, 2588, 400, 20);
    self.exifSceneCaptureType.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSceneCaptureType.textColor = [UIColor blackColor];
    [self.exifSceneCaptureType setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSceneCaptureType];
    
    // Gain control label
    UILabel *exifGainControl = [[UILabel alloc] initWithFrame:CGRectMake(10, 2632, 400, 20)];
    exifGainControl.text = @"Gain control";
    exifGainControl.textColor = [UIColor grayColor];
    [exifGainControl setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifGainControl];
    
    // Gain control
    self.exifGainControl = [[UITextField alloc] init];
    self.exifGainControl.delegate = self;
    self.exifGainControl.frame = CGRectMake(w/2, 2632, 400, 20);
    self.exifGainControl.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifGainControl.textColor = [UIColor blackColor];
    [self.exifGainControl setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifGainControl];
    
    // Contrast label
    UILabel *exifContrast = [[UILabel alloc] initWithFrame:CGRectMake(10, 2676, 400, 20)];
    exifContrast.text = @"Contrast";
    exifContrast.textColor = [UIColor grayColor];
    [exifContrast setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifContrast];
    
    // Contrast
    self.exifContrast = [[UITextField alloc] init];
    self.exifContrast.delegate = self;
    self.exifContrast.frame = CGRectMake(w/2, 2676, 400, 20);
    self.exifContrast.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifContrast.textColor = [UIColor blackColor];
    [self.exifContrast setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifContrast];
    
    // Saturation label
    UILabel *exifSaturation = [[UILabel alloc] initWithFrame:CGRectMake(10, 2720, 400, 20)];
    exifSaturation.text = @"Saturation";
    exifSaturation.textColor = [UIColor grayColor];
    [exifSaturation setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSaturation];
    
    // Saturation
    self.exifSaturation = [[UITextField alloc] init];
    self.exifSaturation.delegate = self;
    self.exifSaturation.frame = CGRectMake(w/2, 2720, 400, 20);
    self.exifSaturation.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSaturation.textColor = [UIColor blackColor];
    [self.exifSaturation setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSaturation];
    
    // Sharpness label
    UILabel *exifSharpness = [[UILabel alloc] initWithFrame:CGRectMake(10, 2764, 400, 20)];
    exifSharpness.text = @"Sharpness";
    exifSharpness.textColor = [UIColor grayColor];
    [exifSharpness setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSharpness];
    
    // Sharpness
    self.exifSharpness = [[UITextField alloc] init];
    self.exifSharpness.delegate = self;
    self.exifSharpness.frame = CGRectMake(w/2, 2764, 400, 20);
    self.exifSharpness.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSharpness.textColor = [UIColor blackColor];
    [self.exifSharpness setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSharpness];
    
    // Device setting description label
    UILabel *exifDeviceSettingDescription = [[UILabel alloc] initWithFrame:CGRectMake(10, 2808, 400, 20)];
    exifDeviceSettingDescription.text = @"Setting description";
    exifDeviceSettingDescription.textColor = [UIColor grayColor];
    [exifDeviceSettingDescription setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifDeviceSettingDescription];
    
    // Device setting description
    self.exifDeviceSettingDescription = [[UITextField alloc] init];
    self.exifDeviceSettingDescription.delegate = self;
    self.exifDeviceSettingDescription.frame = CGRectMake(w/2, 2808, 400, 20);
    self.exifDeviceSettingDescription.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifDeviceSettingDescription.textColor = [UIColor blackColor];
    [self.exifDeviceSettingDescription setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifDeviceSettingDescription];
    
    // Subject dist range label
    UILabel *exifSubjectDistRange = [[UILabel alloc] initWithFrame:CGRectMake(10, 2852, 400, 20)];
    exifSubjectDistRange.text = @"Distance to subject";
    exifSubjectDistRange.textColor = [UIColor grayColor];
    [exifSubjectDistRange setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectDistRange];
    
    // Subject dist range
    self.exifSubjectDistRange = [[UITextField alloc] init];
    self.exifSubjectDistRange.delegate = self;
    self.exifSubjectDistRange.frame = CGRectMake(w/2, 2852, 400, 20);
    self.exifSubjectDistRange.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectDistRange.textColor = [UIColor blackColor];
    [self.exifSubjectDistRange setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectDistRange];
    
    // Image unique ID label
    UILabel *exifImageUniqueID = [[UILabel alloc] initWithFrame:CGRectMake(10, 2896, 400, 20)];
    exifImageUniqueID.text = @"Unique ID";
    exifImageUniqueID.textColor = [UIColor grayColor];
    [exifImageUniqueID setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifImageUniqueID];
    
    // Image unique ID
    self.exifImageUniqueID = [[UITextField alloc] init];
    self.exifImageUniqueID.delegate = self;
    self.exifImageUniqueID.frame = CGRectMake(w/2, 2896, 400, 20);
    self.exifImageUniqueID.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifImageUniqueID.textColor = [UIColor blackColor];
    [self.exifImageUniqueID setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifImageUniqueID];
    
    // Gamma label
    UILabel *exifGamma = [[UILabel alloc] initWithFrame:CGRectMake(10, 2940, 400, 20)];
    exifGamma.text = @"Gamma";
    exifGamma.textColor = [UIColor grayColor];
    [exifGamma setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifGamma];
    
    // Gamma
    self.exifGamma = [[UITextField alloc] init];
    self.exifGamma.delegate = self;
    self.exifGamma.frame = CGRectMake(w/2, 2940, 400, 20);
    self.exifGamma.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifGamma.textColor = [UIColor blackColor];
    [self.exifGamma setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifGamma];
    
    // Camera owner name label
    UILabel *exifCameraOwnerName = [[UILabel alloc] initWithFrame:CGRectMake(10, 2984, 400, 20)];
    exifCameraOwnerName.text = @"Camera owner name";
    exifCameraOwnerName.textColor = [UIColor grayColor];
    [exifCameraOwnerName setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifCameraOwnerName];
    
    // Camera owner name
    self.exifCameraOwnerName = [[UITextField alloc] init];
    self.exifCameraOwnerName.delegate = self;
    self.exifCameraOwnerName.frame = CGRectMake(w/2, 2984, 400, 20);
    self.exifCameraOwnerName.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCameraOwnerName.textColor = [UIColor blackColor];
    [self.exifCameraOwnerName setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifCameraOwnerName];
    
    // Body serial number label
    UILabel *exifBodySerialNumber = [[UILabel alloc] initWithFrame:CGRectMake(10, 3028, 400, 20)];
    exifBodySerialNumber.text = @"Body serial number";
    exifBodySerialNumber.textColor = [UIColor grayColor];
    [exifBodySerialNumber setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifBodySerialNumber];
    
    // Body serial number
    self.exifBodySerialNumber = [[UITextField alloc] init];
    self.exifBodySerialNumber.delegate = self;
    self.exifBodySerialNumber.frame = CGRectMake(w/2, 3028, 400, 20);
    self.exifBodySerialNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifBodySerialNumber.textColor = [UIColor blackColor];
    [self.exifBodySerialNumber setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifBodySerialNumber];
    
    // Lens specification label
    UILabel *exifLensSpecification = [[UILabel alloc] initWithFrame:CGRectMake(10, 3072, 400, 20)];
    exifLensSpecification.text = @"Lens specification";
    exifLensSpecification.textColor = [UIColor grayColor];
    [exifLensSpecification setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLensSpecification];
    
    // Lens specification
    self.exifLensSpecification = [[UITextField alloc] init];
    self.exifLensSpecification.delegate = self;
    self.exifLensSpecification.frame = CGRectMake(w/2, 3072, 400, 20);
    self.exifLensSpecification.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensSpecification.textColor = [UIColor blackColor];
    [self.exifLensSpecification setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLensSpecification];
    
    // Lens make label
    UILabel *exifLensMake = [[UILabel alloc] initWithFrame:CGRectMake(10, 3116, 400, 20)];
    exifLensMake.text = @"Lens make";
    exifLensMake.textColor = [UIColor grayColor];
    [exifLensMake setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLensMake];
    
    // Lens make
    self.exifLensMake = [[UITextField alloc] init];
    self.exifLensMake.delegate = self;
    self.exifLensMake.frame = CGRectMake(w/2, 3116, 400, 20);
    self.exifLensMake.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensMake.textColor = [UIColor blackColor];
    [self.exifLensMake setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLensMake];
    
    // Lens model label
    UILabel *exifLensModel = [[UILabel alloc] initWithFrame:CGRectMake(10, 3160, 400, 20)];
    exifLensModel.text = @"Lens model";
    exifLensModel.textColor = [UIColor grayColor];
    [exifLensModel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLensModel];
    
    // Lens model
    self.exifLensModel = [[UITextField alloc] init];
    self.exifLensModel.delegate = self;
    self.exifLensModel.frame = CGRectMake(w/2, 3160, 400, 20);
    self.exifLensModel.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensModel.textColor = [UIColor blackColor];
    [self.exifLensModel setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLensModel];
    
    // Lens serial number label
    UILabel *exifLensSerialNumber = [[UILabel alloc] initWithFrame:CGRectMake(10, 3204, 400, 20)];
    exifLensSerialNumber.text = @"Lens serial number";
    exifLensSerialNumber.textColor = [UIColor grayColor];
    [exifLensSerialNumber setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLensSerialNumber];
    
    // Lens serial number
    self.exifLensSerialNumber = [[UITextField alloc] init];
    self.exifLensSerialNumber.delegate = self;
    self.exifLensSerialNumber.frame = CGRectMake(w/2, 3204, 400, 20);
    self.exifLensSerialNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensSerialNumber.textColor = [UIColor blackColor];
    [self.exifLensSerialNumber setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLensSerialNumber];
    
    // GPS title banner
    UIView *gpsTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 3216, w, 44)];
    exifTitle.backgroundColor = UIColorFromRGB(0x1b81c8);
    [self.tableView addSubview:gpsTitle];
    
    // GPS banner text
    UILabel *gpsTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/2-20, 3216, 40, 20)];
    gpsTitleLabel.text = @"EXIF";
    gpsTitleLabel.textColor = [UIColor whiteColor];
    [self.tableView addSubview:gpsTitleLabel];
    
    [self loadPicture];
    
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
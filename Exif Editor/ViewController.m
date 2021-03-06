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
#import <CommonCrypto/CommonDigest.h>
#import <CoreLocation/CoreLocation.h>
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//#define collectionNull (id)kCFNull


@interface ViewController ()

@end

@implementation ViewController

/*
 *  Maybe store the memory addresses of the text fields in a dictionary instead?
 */

/**
 *  Prompts the user to take a picture.
 */
-(IBAction)takePicture {
    if (self.takeNewPhotoPicker == nil) {
        self.takeNewPhotoPicker = [[UIImagePickerController alloc] init];
        self.takeNewPhotoPicker.delegate = self;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [self.takeNewPhotoPicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        }
        else
        {
            [self.takeNewPhotoPicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
        self.takeNewPhotoPicker.allowsEditing = NO;
    }
    [self presentViewController:self.takeNewPhotoPicker animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    if (!error)
    {
        NSLog(@"succesfully picked the image");
    }
    
}

/**
 *  Prompts the user to choose a picture from the photo library.
 */
- (IBAction)loadPicture {
    NSLog(@"now loading a new picture");
    
    if (self.picker == nil) {
        self.picker = [[UIImagePickerController alloc] init];
        self.picker.delegate = self;
        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.picker.allowsEditing = NO;
    }
    [self presentViewController:self.picker animated:YES completion:nil];
}

/**
 *  Selector for the New Image button
 *  Chooses an image from the photo library.
 */
- (IBAction)newImageButtonPressed:(id)sender {
    [self loadPicture];
}

/**
 *  Selector for the Save button
 *
 *  TODO: Saving works, but the image is flipped and MUCH larger.
 */
- (IBAction)saveButtonPressed:(id)sender {
    /*
     *  If all text fields are empty, then save a stripped image.
     *  Else, just save an image with whatever is in the text fields.
     */
    
    NSLog(@"now saving");
//    self.currentImageData = [self getDataFromCurrentTextfields];
    
    self.saveView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 300, 100)];
    self.saveView.backgroundColor = UIColorFromRGB(0x1b81c8);
//    self.saveView.alpha = 1.0;
    
//    self.jpgSaveButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 150, 50)];
//    self.jpgSaveButton.backgroundColor = [UIColor redColor];
//    [self.jpgSaveButton setTitle:@"JPG" forState:UIControlStateNormal];
//    [self.saveView addSubview:self.jpgSaveButton];
//    self.pngSaveButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 90, 150, 50)];
//    self.pngSaveButton.backgroundColor = [UIColor redColor];
//    [self.pngSaveButton setTitle:@"PNG" forState:UIControlStateNormal];
//    [self.saveView addSubview:self.pngSaveButton];

    self.savingLabel = [[UILabel alloc] initWithFrame:CGRectMake(90,0,120,100)];
    self.savingLabel.backgroundColor = UIColorFromRGB(0x1b81c8);
    self.savingLabel.text = @"Saved!";
    [self.savingLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:26]];
    [self.saveView addSubview:self.savingLabel];
    
    self.savePopup = [KLCPopup popupWithContentView:self.saveView
                                       showType:KLCPopupShowTypeGrowIn
                                        dismissType:KLCPopupDismissTypeShrinkOut maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    [self.savePopup showWithDuration: 0.6];
    
    [self saveImage:self.imageView.image withInfo:self.inf];
    
    
}

- (void) saveImage:(UIImage *)imageToSave withInfo:(NSDictionary *)info
{
    // Comment out if kCFNull is to be used instead
    NSNull *collectionNull = [NSNull null];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
//    NSLog(@"info has size: %lu", (unsigned long) [info count]);
    
    // Get the image metadata (EXIF & TIFF)
//    NSMutableDictionary * imageMetadata = [[info objectForKey:UIImagePickerControllerMediaMetadata] mutableCopy];
    
//    NSLog(@"info contains: %@", [self stringOutputForDictionary:info]);
    
//    self.imageMetadata = (NSMutableDictionary *) [info objectForKey:UIImagePickerControllerMediaMetadata];
//    NSLog(@"%@", imageMetadata);
    
    self.imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:[info objectForKey:UIImagePickerControllerMediaMetadata]];
//    self.imageMetadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSMutableDictionary *)(self.originalExif)];
    
    NSMutableDictionary *saveExif = [[NSMutableDictionary alloc] init];
    
    // Date time original - ascii
    NSString *saveDateOriginal = [self.dateTimeOriginal.text stringByAppendingString:[NSString stringWithFormat:@" %@", self.dateTimeOriginalTime.text]];
    if([saveDateOriginal isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
    }
    else {
        [saveExif setObject:saveDateOriginal forKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
        self.allFieldsBlank = NO;
    }
    // Filler for the date time digitized
    /// forKey:(NSString *)kCGImagePropertyExifDateTimeDigitized];
    // Exposure time - rational
    if([self.exifExposureTime.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifExposureTime];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifExposureTime.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifExposureTime];
        self.allFieldsBlank = NO;
    }
    // f-number - rational
    if([self.exifFNumber.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFNumber];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifFNumber.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifFNumber];
        self.allFieldsBlank = NO;
    }
    // Exposure program - short
    if([self.exifExposureProgram.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifExposureProgram];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifExposureProgram.text intValue]] forKey:(NSString *)kCGImagePropertyExifExposureProgram];
        self.allFieldsBlank = NO;
    }
    // Spectral sensitivity - ascii
    if([self.exifSpectralSensitivity.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSpectralSensitivity];
    }
    else {
        [saveExif setObject:self.exifSpectralSensitivity.text forKey:(NSString *)kCGImagePropertyExifSpectralSensitivity];
        self.allFieldsBlank = NO;
    }
    // ISO speed ratings - short according to documentation (but it's actually array)
    if([self.exifISOSpeedRatings.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifISOSpeedRatings];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifISOSpeedRatings.text intValue]] forKey:(NSString *)kCGImagePropertyExifISOSpeedRatings];
        self.allFieldsBlank = NO;
    }
    // OECF - undefined (array)
    if([self.exifOECF.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifOECF];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifOECF.text intValue]] forKey:(NSString *)kCGImagePropertyExifOECF];
        self.allFieldsBlank = NO;
    }
    // Version - undefined (array)
    if([self.exifVersion.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifVersion];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifVersion.text intValue]] forKey:(NSString *)kCGImagePropertyExifVersion];
        self.allFieldsBlank = NO;
    }
    // Components configuration - undefined (array)
    if([self.exifComponentsConfiguration.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifComponentsConfiguration];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifComponentsConfiguration.text intValue]] forKey:(NSString *)kCGImagePropertyExifComponentsConfiguration];
        self.allFieldsBlank = NO;
    }
    // Compressed bits per pixel - rational
    if([self.exifCompressedBitsPerPixel.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifCompressedBitsPerPixel];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifCompressedBitsPerPixel.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifCompressedBitsPerPixel];
        self.allFieldsBlank = NO;
    }
    // Shutter speed value - rational
    if([self.exifShutterSpeedValue.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifShutterSpeedValue];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifShutterSpeedValue.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifShutterSpeedValue];
        self.allFieldsBlank = NO;
    }
    // Aperture value - rational
    if([self.exifApertureValue.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifApertureValue];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifApertureValue.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifApertureValue];
        self.allFieldsBlank = NO;
    }
    // Brightness value - rational
    if([self.exifBrightnessValue.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifBrightnessValue];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifBrightnessValue.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifBrightnessValue];
        self.allFieldsBlank = NO;
    }
    // Exposure bias value - rational
    if([self.exifExposureBiasValue.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifExposureBiasValue];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifExposureBiasValue.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifExposureBiasValue];
        self.allFieldsBlank = NO;
    }
    // Max aperture value - rational
    if([self.exifMaxApertureValue.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifMaxApertureValue];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifMaxApertureValue.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifMaxApertureValue];
        self.allFieldsBlank = NO;
    }
    // Subject distance - rational
    if([self.exifSubjectDistance.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubjectDistance];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifSubjectDistance.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifSubjectDistance];
        self.allFieldsBlank = NO;
    }
    // Metering mode - short
    if([self.exifMeteringMode.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifMeteringMode];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifMeteringMode.text intValue]] forKey:(NSString *)kCGImagePropertyExifMeteringMode];
        self.allFieldsBlank = NO;
    }
    // Light source - short
    if([self.exifLightSource.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifLightSource];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifLightSource.text intValue]] forKey:(NSString *)kCGImagePropertyExifLightSource];
        self.allFieldsBlank = NO;
    }
    // Flash - short
    if([self.exifFlash.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFlash];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifFlash.text intValue]] forKey:(NSString *)kCGImagePropertyExifFlash];
        self.allFieldsBlank = NO;
    }
    // Focal length - rational
    if([self.exifFocalLength.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFocalLength];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifFocalLength.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifFocalLength];
        self.allFieldsBlank = NO;
    }
    // Subject area - short
    if([self.exifSubjectArea.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubjectArea];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSubjectArea.text intValue]] forKey:(NSString *)kCGImagePropertyExifSubjectArea];
        self.allFieldsBlank = NO;
    }
    // Maker note - undefined (string)
    if([self.exifMakerNote.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifMakerNote];
    }
    else {
        [saveExif setObject:self.exifMakerNote.text forKey:(NSString *)kCGImagePropertyExifMakerNote];
        self.allFieldsBlank = NO;
    }
    // User comment - undefined (string)
    if([self.exifUserComment.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifUserComment];
    }
    else {
        [saveExif setObject:self.exifUserComment.text forKey:(NSString *)kCGImagePropertyExifUserComment];
        self.allFieldsBlank = NO;
    }
    // Subsec time - ascii
    if([self.exifSubsecTime.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubsecTime];
    }
    else {
        [saveExif setObject:self.exifSubsecTime.text forKey:(NSString *)kCGImagePropertyExifSubsecTime];
        self.allFieldsBlank = NO;
    }
    // Subsec time original - ascii
    if([self.exifSubsecTimeOrginal.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubsecTimeOrginal];
    }
    else {
        [saveExif setObject:self.exifSubsecTimeOrginal.text forKey:(NSString *)kCGImagePropertyExifSubsecTimeOrginal];
        self.allFieldsBlank = NO;
    }
    // Subsec time digitized - ascii
    if([self.exifSubsecTimeDigitized.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubsecTimeDigitized];
    }
    else {
        [saveExif setObject:self.exifSubsecTimeDigitized.text forKey:(NSString *)kCGImagePropertyExifSubsecTimeDigitized];
        self.allFieldsBlank = NO;
    }
    // Flash pix version - undefined (array)
    if([self.exifFlashPixVersion.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFlashPixVersion];
    }
    else {
        [saveExif setObject:self.exifFlashPixVersion.text forKey:(NSString *)kCGImagePropertyExifFlashPixVersion];
        self.allFieldsBlank = NO;
    }
    // Color space - short
    if([self.exifColorSpace.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifColorSpace];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifColorSpace.text intValue]] forKey:(NSString *)kCGImagePropertyExifColorSpace];
        self.allFieldsBlank = NO;
    }
    // Pixel X dimension - short
    if([self.exifPixelXDimension.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifPixelXDimension];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifPixelXDimension.text intValue]] forKey:(NSString *)kCGImagePropertyExifPixelXDimension];
        self.allFieldsBlank = NO;
    }
    // Pixel Y dimension - short
    if([self.exifPixelYDimension.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifPixelYDimension];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifPixelYDimension.text intValue]] forKey:(NSString *)kCGImagePropertyExifPixelYDimension];
        self.allFieldsBlank = NO;
    }
    // Related sound file - ascii
    if([self.exifRelatedSoundFile.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifRelatedSoundFile];
    }
    else {
        [saveExif setObject:self.exifRelatedSoundFile.text forKey:(NSString *)kCGImagePropertyExifRelatedSoundFile];
        self.allFieldsBlank = NO;
    }
    // Flash energy - rational
    if([self.exifFlashEnergy.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFlashEnergy];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifFlashEnergy.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifFlashEnergy];
        self.allFieldsBlank = NO;
    }
    // Spatial frequency response - undefined (array)
    if([self.exifSpatialFrequencyResponse.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSpatialFrequencyResponse];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifSpatialFrequencyResponse.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifSpatialFrequencyResponse];
        self.allFieldsBlank = NO;
    }
    // Focal plane X resolution - rational
    if([self.exifFocalPlaneXResolution.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFocalPlaneXResolution];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifFocalPlaneXResolution.text intValue]] forKey:(NSString *)kCGImagePropertyExifFocalPlaneXResolution];
        self.allFieldsBlank = NO;
    }
    // Focal plane Y resolution - rational
    if([self.exifFocalPlaneYResolution.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFocalPlaneYResolution];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithInt:[self.exifFocalPlaneYResolution.text intValue]] forKey:(NSString *)kCGImagePropertyExifFocalPlaneYResolution];
        self.allFieldsBlank = NO;
    }
    // Focal plane resolution unit - short
    if([self.exifFocalPlaneResolutionUnit.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFocalPlaneResolutionUnit];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifFocalPlaneResolutionUnit.text intValue]] forKey:(NSString *)kCGImagePropertyExifFocalPlaneResolutionUnit];
        self.allFieldsBlank = NO;
    }
    // Subject location - short
    if([self.exifSubjectLocation.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubjectLocation];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSubjectLocation.text intValue]] forKey:(NSString *)kCGImagePropertyExifSubjectLocation];
        self.allFieldsBlank = NO;
    }
    // Exposure index - rational
    if([self.exifExposureIndex.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifExposureIndex];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifExposureIndex.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifExposureIndex];
        self.allFieldsBlank = NO;
    }
    // Sensing method - short
    if([self.exifSensingMethod.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSensingMethod];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSensingMethod.text intValue]] forKey:(NSString *)kCGImagePropertyExifSensingMethod];
        self.allFieldsBlank = NO;
    }
    // File source - undefined according to documentation, but it's actually a short
    if([self.exifFileSource.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFileSource];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifFileSource.text intValue]] forKey:(NSString *)kCGImagePropertyExifFileSource];
        self.allFieldsBlank = NO;
    }
    // Scene type - undefined. not editable
    if([self.exifSceneType.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSceneType];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifSceneType.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifSceneType];
        self.allFieldsBlank = NO;
    }
    // CFA pattern - undefined. not editable
    if([self.exifCFAPattern.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifCFAPattern];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifCFAPattern.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifCFAPattern];
        self.allFieldsBlank = NO;
    }
    // Custom rendered - short
    if([self.exifCustomRendered.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifCustomRendered];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifCustomRendered.text intValue]] forKey:(NSString *)kCGImagePropertyExifCustomRendered];
        self.allFieldsBlank = NO;
    }
    // Exposure mode - short
    if([self.exifExposureMode.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifExposureMode];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifExposureMode.text intValue]] forKey:(NSString *)kCGImagePropertyExifExposureMode];
        self.allFieldsBlank = NO;
    }
    // White balance - short
    if([self.exifWhiteBalance.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifWhiteBalance];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifWhiteBalance.text intValue]] forKey:(NSString *)kCGImagePropertyExifWhiteBalance];
        self.allFieldsBlank = NO;
    }
    // Digital zoom ratio - rational
    if([self.exifDigitalZoomRatio.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifDigitalZoomRatio];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifDigitalZoomRatio.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifDigitalZoomRatio];
        self.allFieldsBlank = NO;
    }
    // Focal length in 35 mm film - short
    if([self.exifFocalLenIn35mmFilm.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifFocalLenIn35mmFilm];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifFocalLenIn35mmFilm.text intValue]] forKey:(NSString *)kCGImagePropertyExifFocalLenIn35mmFilm];
        self.allFieldsBlank = NO;
    }
    // Scene capture type - short
    if([self.exifSceneCaptureType.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSceneCaptureType];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSceneCaptureType.text intValue]] forKey:(NSString *)kCGImagePropertyExifSceneCaptureType];
        self.allFieldsBlank = NO;
    }
    // Gain control - short
    if([self.exifGainControl.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifGainControl];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifGainControl.text intValue]] forKey:(NSString *)kCGImagePropertyExifGainControl];
        self.allFieldsBlank = NO;
    }
    // Contrast - short
    if([self.exifContrast.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifContrast];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifContrast.text intValue]] forKey:(NSString *)kCGImagePropertyExifContrast];
        self.allFieldsBlank = NO;
    }
    // Saturation - short
    if([self.exifSaturation.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSaturation];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSaturation.text intValue]] forKey:(NSString *)kCGImagePropertyExifSaturation];
        self.allFieldsBlank = NO;
    }
    // Sharpness - short
    if([self.exifSharpness.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSharpness];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSharpness.text intValue]] forKey:(NSString *)kCGImagePropertyExifSharpness];
        self.allFieldsBlank = NO;
    }
    // Device setting description - undefined. not editable
    if([self.exifDeviceSettingDescription.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifDeviceSettingDescription];
    }
    else {
        [saveExif setObject:self.exifDeviceSettingDescription.text forKey:(NSString *)kCGImagePropertyExifDeviceSettingDescription];
        self.allFieldsBlank = NO;
    }
    // Subject distance range - short
    if([self.exifSubjectDistRange.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifSubjectDistRange];
    }
    else {
        [saveExif setObject:[NSNumber numberWithInt:[self.exifSubjectDistRange.text intValue]] forKey:(NSString *)kCGImagePropertyExifSubjectDistRange];
        self.allFieldsBlank = NO;
    }
    // Image unique ID - ascii
    if([self.exifImageUniqueID.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifImageUniqueID];
    }
    else {
        [saveExif setObject:self.exifImageUniqueID.text forKey:(NSString *)kCGImagePropertyExifImageUniqueID];
        self.allFieldsBlank = NO;
    }
    // Gamma - not in documentation, but probably a float
    if([self.exifGamma.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifGamma];
    }
    else {
        [saveExif setObject:[NSDecimalNumber numberWithFloat:[self.exifGamma.text doubleValue]] forKey:(NSString *)kCGImagePropertyExifGamma];
        self.allFieldsBlank = NO;
    }
    // Camera owner name - not in documentation, but probably ascii
    if([self.exifCameraOwnerName.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifCameraOwnerName];
    }
    else {
        [saveExif setObject:self.exifCameraOwnerName.text forKey:(NSString *)kCGImagePropertyExifCameraOwnerName];
        self.allFieldsBlank = NO;
    }
    // Body serial number - not in documentation, but probably ascii
    if([self.exifBodySerialNumber.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifBodySerialNumber];
    }
    else {
        [saveExif setObject:self.exifBodySerialNumber.text forKey:(NSString *)kCGImagePropertyExifBodySerialNumber];
        self.allFieldsBlank = NO;
    }
    // Lens specification - not in documentation, but it is an array
    if([self.exifLensSpecification.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifLensSpecification];
    }
    else {
        [saveExif setObject:self.exifLensSpecification.text forKey:(NSString *)kCGImagePropertyExifLensSpecification];
        self.allFieldsBlank = NO;
    }
    // Lens make - not in documentation, but probably ascii
    if([self.exifLensMake.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifLensMake];
    }
    else {
        [saveExif setObject:self.exifLensMake.text forKey:(NSString *)kCGImagePropertyExifLensMake];
        self.allFieldsBlank = NO;
    }
    // Lens model - not in documentation, but probably ascii
    if([self.exifLensModel.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifLensModel];
    }
    else {
        [saveExif setObject:self.exifLensModel.text forKey:(NSString *)kCGImagePropertyExifLensModel];
        self.allFieldsBlank = NO;
    }
    // Lens serial number - not in documentation, but probably ascii
    if([self.exifLensSerialNumber.text isEqualToString:@""]) {
        /// forKey:(NSString *)kCGImagePropertyExifLensSerialNumber];
    }
    else {
        [saveExif setObject:self.exifLensSerialNumber.text forKey:(NSString *)kCGImagePropertyExifLensSerialNumber];
        self.allFieldsBlank = NO;
    }
    
    // adds exif dictionary to the metadata dictionary
    [self.imageMetadata setObject:saveExif forKey:(NSString *)kCGImagePropertyExifDictionary];
    
    NSLog(@"imageMetadata has size: %lu", (unsigned long)[self.exifData count]);
    
    // add GPS data
    CLLocation * loc = [[CLLocation alloc] initWithLatitude:self.latval longitude:self.longval]; // need a location here
    if ( loc ) {
        NSLog(@"setting object");
        [self.imageMetadata setObject:[self gpsDictionaryForLocation:loc] forKey:(NSString*)kCGImagePropertyGPSDictionary];
    }
    
    ALAssetsLibraryWriteImageCompletionBlock imageWriteCompletionBlock =
    ^(NSURL *newURL, NSError *error) {
        if (error) {
            NSLog( @"Error writing image with metadata to Photo Library: %@", error );
        } else {
            NSLog( @"Wrote image %@ with metadata %@ to Photo Library",newURL,self.imageMetadata);
//            [KLCPopup dismissAllPopups];
        }
    };
    

    if(self.allFieldsBlank) {
        NSLog(@"all fields were blank");
        // Does this ever get called? Need to test more
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
    }
    else {
        NSLog(@"fields were not blank");
        [library writeImageToSavedPhotosAlbum:[imageToSave CGImage]
                                     metadata:self.imageMetadata
                              completionBlock:imageWriteCompletionBlock];
    }
}

/**
 *  Saves the GPS dictionary information
 *  GPS tag info taken from http://www.awaresystems.be/imaging/tiff/tifftags/privateifd/gps.html
 */
- (NSDictionary *) gpsDictionaryForLocation:(CLLocation *)location
{
    // Comment out if kCFNull is to be used instead
    NSNull *collectionNull = [NSNull null];
    
    NSLog(@"now writing gps dictionary location");
    CLLocationDegrees exifLatitude  = location.coordinate.latitude;
    CLLocationDegrees exifLongitude = location.coordinate.longitude;
    
    NSString * latRef;
    NSString * longRef;
    if (exifLatitude < 0.0) {
        exifLatitude = exifLatitude * -1.0f;
        latRef = @"S";
    } else {
        latRef = @"N";
    }
    
    if (exifLongitude < 0.0) {
        exifLongitude = exifLongitude * -1.0f;
        longRef = @"W";
    } else {
        longRef = @"E";
    }
    
    self.locDict = [[NSMutableDictionary alloc] init];
    
    // GPS version - byte. probably works like exif version
    if([self.gpsVersion.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSVersion];
    }
    else {
        [self.locDict setObject:self.gpsVersion.text forKey:(NSString *)kCGImagePropertyGPSVersion];
        self.allFieldsBlank = NO;
    }
    // Latitude ref
    if([self.gpsLatitudeRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
    }
    else {
        [self.locDict setObject:latRef forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
        self.allFieldsBlank = NO;
    }
    // Latitude
    if([self.gpsLatitude.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSLatitude];
    }
    else {
        [self.locDict setObject:[NSNumber numberWithFloat:exifLatitude] forKey:(NSString *)kCGImagePropertyGPSLatitude];
        self.allFieldsBlank = NO;
    }
    // Longitude ref
    if([self.gpsLongitudeRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
    }
    else {
        [self.locDict setObject:longRef forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
        self.allFieldsBlank = NO;
    }
    // Longitude
    if([self.gpsLongitude.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSLongitude];
    }
    else {
        [self.locDict setObject:[NSNumber numberWithFloat:exifLongitude] forKey:(NSString *)kCGImagePropertyGPSLongitude];
        self.allFieldsBlank = NO;
    }
    // GPS DOP - rational
    if([self.gpsDegreeOfPrecision.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDOP];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDegreeOfPrecision.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDOP];
        self.allFieldsBlank = NO;
    }
    // Altitude ref - byte
    if([self.gpsAltitudeRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSAltitudeRef];
    }
    else {
        [self.locDict setObject:[NSNumber numberWithInt:[self.gpsAltitudeRef.text intValue]] forKey:(NSString*)kCGImagePropertyGPSAltitudeRef];
        self.allFieldsBlank = NO;
    }
    // Altitude - rational
    if([self.gpsAltitude.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSAltitude];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsAltitude.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSAltitude];
        self.allFieldsBlank = NO;
    }
    // timestamp - rational
    if([self.gpsTimeStamp.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSTimeStamp];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsTimeStamp.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
        self.allFieldsBlank = NO;
    }
    // Satellites - ascii
    if([self.gpsSatellites.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSSatellites];
    }
    else {
        [self.locDict setObject:self.gpsSatellites.text forKey:(NSString*)kCGImagePropertyGPSSatellites];
        self.allFieldsBlank = NO;
    }
    // GPS status - ascii
    if([self.gpsStatus.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSStatus];
    }
    else {
        [self.locDict setObject:self.gpsStatus.text forKey:(NSString*)kCGImagePropertyGPSStatus];
        self.allFieldsBlank = NO;
    }
    // GPS measure mode - ascii
    if([self.gpsMeasureMode.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSMeasureMode];
    }
    else {
        [self.locDict setObject:self.gpsMeasureMode.text forKey:(NSString*)kCGImagePropertyGPSMeasureMode];
        self.allFieldsBlank = NO;
    }
    // GPS DOP - rational
    if([self.gpsDegreeOfPrecision.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDOP];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDegreeOfPrecision.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDOP];
        self.allFieldsBlank = NO;
    }
    // GPS speed ref - ascii
    if([self.gpsSpeedRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSSpeedRef];
    }
    else {
        [self.locDict setObject:self.gpsSpeedRef.text forKey:(NSString*)kCGImagePropertyGPSSpeedRef];
        self.allFieldsBlank = NO;
    }
    // GPS speed - rational
    if([self.gpsSpeed.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSSpeed];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsSpeed.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSSpeed];
        self.allFieldsBlank = NO;
    }
    // GPS track ref - ascii
    if([self.gpsTrackRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSTrackRef];
    }
    else {
        [self.locDict setObject:self.gpsTrackRef.text forKey:(NSString*)kCGImagePropertyGPSTrackRef];
        self.allFieldsBlank = NO;
    }
    // GPS track - rational
    if([self.gpsTrack.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSTrack];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsTrack.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSTrack];
        self.allFieldsBlank = NO;
    }
    // GPS image direction ref - ascii
    if([self.gpsImgDirectionRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSImgDirectionRef];
    }
    else {
        [self.locDict setObject:self.gpsImgDirectionRef.text forKey:(NSString*)kCGImagePropertyGPSImgDirectionRef];
        self.allFieldsBlank = NO;
    }
    // GPS image direction - rational
    if([self.gpsImgDirection.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSImgDirection];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsImgDirection.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSImgDirection];
        self.allFieldsBlank = NO;
    }
    // GPS map datum - ascii
    if([self.gpsMapDatum.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSMapDatum];
    }
    else {
        [self.locDict setObject:self.gpsMapDatum.text forKey:(NSString*)kCGImagePropertyGPSMapDatum];
        self.allFieldsBlank = NO;
    }
    // GPS destination latitude ref - ascii
    if([self.gpsDestLatRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestLatitudeRef];
    }
    else {
        [self.locDict setObject:self.gpsDestLatRef.text forKey:(NSString*)kCGImagePropertyGPSDestLatitudeRef];
        self.allFieldsBlank = NO;
    }
    // GPS destination latitude - rational
    if([self.gpsDestLat.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestLatitude];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDestLat.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDestLatitude];
        self.allFieldsBlank = NO;
    }
    // GPS destination longitude ref - ascii
    if([self.gpsDestLongRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestLongitudeRef];
    }
    else {
        [self.locDict setObject:self.gpsDestLongRef.text forKey:(NSString*)kCGImagePropertyGPSDestLongitudeRef];
        self.allFieldsBlank = NO;
    }
    // GPS destination longitude - rational
    if([self.gpsDestLong.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestLongitude];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDestLong.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDestLongitude];
        self.allFieldsBlank = NO;
    }
    // GPS destination bearing ref - ascii
    if([self.gpsDestBearingRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestBearingRef];
    }
    else {
        [self.locDict setObject:self.gpsDestBearingRef.text forKey:(NSString*)kCGImagePropertyGPSDestBearingRef];
        self.allFieldsBlank = NO;
    }
    // GPS destination bearing - rational
    if([self.gpsDestBearing.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestBearing];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDestBearing.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDestBearing];
        self.allFieldsBlank = NO;
    }
    // GPS destination distance ref - ascii
    if([self.gpsDestDistanceRef.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestDistanceRef];
    }
    else {
        [self.locDict setObject:self.gpsDestDistanceRef.text forKey:(NSString*)kCGImagePropertyGPSDestDistanceRef];
        self.allFieldsBlank = NO;
    }
    // GPS destination distance - rational
    if([self.gpsDestDistance.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDestDistance];
    }
    else {
        [self.locDict setObject:[NSDecimalNumber numberWithFloat:[self.gpsDestDistance.text doubleValue]] forKey:(NSString*)kCGImagePropertyGPSDestDistance];
        self.allFieldsBlank = NO;
    }
    // GPS processing method - undefined, but according to documentation, it is a string. doesn't update
    if([self.gpsProcessingMethod.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSProcessingMethod];
    }
    else {
        [self.locDict setObject:self.gpsProcessingMethod.text forKey:(NSString*)kCGImagePropertyGPSProcessingMethod];
        self.allFieldsBlank = NO;
    }
    // GPS area information - undefined, but according to documentation, it is a string. doesn't update
    if([self.gpsAreaInformation.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSAreaInformation];
    }
    else {
        [self.locDict setObject:self.gpsAreaInformation.text forKey:(NSString*)kCGImagePropertyGPSAreaInformation];
        self.allFieldsBlank = NO;
    }
    // GPS date stamp - ascii. doesn't update
    if([self.gpsDateStamp.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDateStamp];
    }
    else {
        [self.locDict setObject:self.gpsDateStamp.text forKey:(NSString*)kCGImagePropertyGPSDateStamp];
        self.allFieldsBlank = NO;
    }
    // GPS differential - short
    if([self.gpsDifferental.text isEqualToString:@""]) {
        //// forKey:(NSString *)kCGImagePropertyGPSDifferental];
    }
    else {
        [self.locDict setObject:[NSNumber numberWithInt:[self.gpsDifferental.text intValue]] forKey:(NSString*)kCGImagePropertyGPSDifferental];
        self.allFieldsBlank = NO;
    }
    
    NSLog(@"location dictionary contains: %@", [self stringOutputForDictionary:self.locDict]);
    
    return self.locDict;
}

/**
 *  Reads all current text fields and generates image data from it.
 */
- (NSData *)getDataFromCurrentTextfields {
    return self.currentImageData;
}

/**
 *  Selector for the Reset button
 *  Re-calls the load function with the same photo [self.pic] and information [self.info]
 */
- (IBAction)resetExif:(id)sender {
    NSLog(@"Now resetting");
    [self imagePickerController:self.pic didFinishPickingMediaWithInfo:self.inf];
}

/**
 *  Selector for the Clear button.
 *  Sets all text fields to string of "". This is also called in the load function
 *  to "wash out" the old Exif values when the user pics a new picture.
 */
- (IBAction)clearExif{
    NSLog(@"Now clearing text fields");
    
//    self.fileName.text = @"";
//    self.fileExtension.text = @"";
//    self.widthAndHeight.text = @"";
//    self.fileSize.text = @"";
    self.dateTimeOriginal.text = @"";
    self.dateTimeOriginalTime.text = @"";
    self.dateTimeDigitized.text = @"";
    self.exifExposureTime.text = @"";
    self.exifFNumber.text = @"";
    self.exifExposureProgram.text = @"";
    self.exifSpectralSensitivity.text = @"";
    self.exifISOSpeedRatings.text = @"";
    self.exifOECF.text = @"";
    self.exifVersion.text = @"";
    self.exifComponentsConfiguration.text = @"";
    self.exifCompressedBitsPerPixel.text = @"";
    self.exifShutterSpeedValue.text = @"";
    self.exifApertureValue.text = @"";
    self.exifBrightnessValue.text = @"";
    self.exifExposureBiasValue.text = @"";
    self.exifMaxApertureValue.text = @"";
    self.exifSubjectDistance.text = @"";
    self.exifMeteringMode.text = @"";
    self.exifLightSource.text = @"";
    self.exifFlash.text = @"";
    self.exifFocalLength.text = @"";
    self.exifSubjectArea.text = @"";
    self.exifMakerNote.text = @"";
    self.exifUserComment.text = @"";
    self.exifSubsecTime.text = @"";
    self.exifSubsecTimeOrginal.text = @"";
    self.exifSubsecTimeDigitized.text = @"";
    self.exifFlashPixVersion.text = @"";
    self.exifColorSpace.text = @"";
    self.exifPixelXDimension.text = @"";
    self.exifPixelYDimension.text = @"";
    self.exifRelatedSoundFile.text = @"";
    self.exifFlashEnergy.text = @"";
    self.exifSpatialFrequencyResponse.text = @"";
    self.exifFocalPlaneXResolution.text = @"";
    self.exifFocalPlaneYResolution.text = @"";
    self.exifFocalPlaneResolutionUnit.text = @"";
    self.exifSubjectLocation.text = @"";
    self.exifExposureIndex.text = @"";
    self.exifSensingMethod.text = @"";
    self.exifFileSource.text = @"";
    self.exifSceneType.text = @"";
    self.exifCFAPattern.text = @"";
    self.exifCustomRendered.text = @"";
    self.exifExposureMode.text = @"";
    self.exifWhiteBalance.text = @"";
    self.exifDigitalZoomRatio.text = @"";
    self.exifFocalLenIn35mmFilm.text = @"";
    self.exifSceneCaptureType.text = @"";
    self.exifGainControl.text = @"";
    self.exifContrast.text = @"";
    self.exifSaturation.text = @"";
    self.exifSharpness.text = @"";
    self.exifDeviceSettingDescription.text = @"";
    self.exifSubjectDistRange.text = @"";
    self.exifImageUniqueID.text = @"";
    self.exifGamma.text = @"";
    self.exifCameraOwnerName.text = @"";
    self.exifBodySerialNumber.text = @"";
    self.exifLensSpecification.text = @"";
    self.exifLensMake.text = @"";
    self.exifLensModel.text = @"";
    self.exifLensSerialNumber.text = @"";
    self.gpsVersion.text = @"";
    self.gpsLatitudeRef.text = @"";
    self.gpsLatitude.text = @"";
    self.gpsLongitudeRef.text = @"";
    self.gpsLongitude.text = @"";
    self.gpsAltitudeRef.text = @"";
    self.gpsAltitude.text = @"";
    self.gpsTimeStamp.text = @"";
    self.gpsSatellites.text = @"";
    self.gpsStatus.text = @"";
    self.gpsMeasureMode.text = @"";
    self.gpsDegreeOfPrecision.text = @"";
    self.gpsSpeedRef.text = @"";
    self.gpsSpeed.text = @"";
    self.gpsTrackRef.text = @"";
    self.gpsTrack.text = @"";
    self.gpsImgDirectionRef.text = @"";
    self.gpsImgDirection.text = @"";
    self.gpsMapDatum.text = @"";
    self.gpsDestLatRef.text = @"";
    self.gpsDestLat.text = @"";
    self.gpsDestLongRef.text = @"";
    self.gpsDestLong.text = @"";
    self.gpsDestBearingRef.text = @"";
    self.gpsDestBearing.text = @"";
    self.gpsDestDistanceRef.text = @"";
    self.gpsDestDistance.text = @"";
    self.gpsProcessingMethod.text = @"";
    self.gpsAreaInformation.text = @"";
    self.gpsDateStamp.text = @"";
    self.gpsDifferental.text = @"";
}

/**
 *  Takes an image in NSData format and returns it with the Exif/GPS dictionary
 *  stripped. Not yet used by anything
 *
 *  TODO: Strip the other dictionaries (i.e. the format-specific and manufacturer-
 *  specific ones)
 */
- (NSData *)dataByRemovingExif:(NSData *)data
{
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    NSMutableData *mutableData = nil;
    
    if (source) {
        CFStringRef type = CGImageSourceGetType(source);
        size_t count = CGImageSourceGetCount(source);
        mutableData = [NSMutableData data];
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)mutableData, type, count, NULL);
        
        NSDictionary *removeExifProperties = @{(id)kCGImagePropertyExifDictionary: (id)kCFNull,
                                               (id)kCGImagePropertyGPSDictionary : (id)kCFNull};
        
        if (destination) {
            for (size_t index = 0; index < count; index++) {
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)removeExifProperties);
            }
            
            if (!CGImageDestinationFinalize(destination)) {
                NSLog(@"CGImageDestinationFinalize failed");
            }
            
            CFRelease(destination);
        }
        
        CFRelease(source);
    }
    
    return mutableData;
}

/**
 *  Prints the contents of a dictionary. Only used for debugging.
 */
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

/**
 *  Called when the user canceled the image selection.
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  Gets the date portion of the dateTime field. Don't use with anything but self.dateTimeOriginal.
 */
- (NSString *)firstHalf: (NSString *)str {
    return [str substringToIndex:10];
}

/**
 *  Gets the time portion of the dateTime field. Don't use with anything but self.dateTimeOriginal.
 */
- (NSString *)secondHalf: (NSString *)str {
    return [str substringWithRange:NSMakeRange(11, 8)];
}

/**
 *  Called when the user took a picture or picked a photo from the library. It then reads the Exif/GPS data, then:
 *      1) Fills the image view
 *      2) Fills a dictionary for original values for resetting
 *      3) Populates the text fields
 *
 *  TODO: When the user takes a new picture, it doesn't show up in the image view, and its Exif/GPS data don't appear.
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.pic = [[UIImagePickerController alloc] init];
    self.pic = picker;
    self.inf = [[NSDictionary alloc] init];
    self.inf = info;
    
    if(picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImage *fullImage = info[UIImagePickerControllerOriginalImage];
        NSMutableDictionary *mediaMetadata = (NSMutableDictionary *) [info objectForKey:UIImagePickerControllerMediaMetadata];
        
        NSLog(@"now in the imagePickerController method as SourceTypeCamera");
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        
        ALAssetsLibraryWriteImageCompletionBlock imageWriteCompletionBlock =
        ^(NSURL *newURL, NSError *error) {
            if (error) {
                NSLog( @"Error writing image with metadata to Photo Library: %@", error );
            } else {
                NSLog( @"Wrote image %@ with metadata %@ to Photo Library",newURL,mediaMetadata);
            }
        };
        
        [library writeImageToSavedPhotosAlbum:[fullImage CGImage]
                                     metadata:mediaMetadata
                              completionBlock:imageWriteCompletionBlock];
        
        [picker dismissViewControllerAnimated:YES completion:nil];
        

        self.pic = [[UIImagePickerController alloc] init];
        self.pic.delegate = self;
        self.pic.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.pic.allowsEditing = NO;
        [self presentViewController:self.pic animated:YES completion:nil];
//        [self didSelectPhotoFromLibrary:self.pic didFinishPickingMediaWithInfo:self.inf];

    }
    else if(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        [self didSelectPhotoFromLibrary:picker didFinishPickingMediaWithInfo:info];
    }
}

- (void)didSelectPhotoFromLibrary:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSLog(@"now loading the picture's information");
    
    // Clears the data fields before populating them
    [self clearExif];
    
    self.allFieldsBlank = YES;
    
    self.pic = picker;
    self.inf = info;
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    NSString *mediaType = info[UIImagePickerControllerMediaType];
    UIImage *fullImage = info[UIImagePickerControllerOriginalImage];
//    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
//    NSValue *cropRect = info[UIImagePickerControllerCropRect];
//    NSURL *mediaUrl = info[UIImagePickerControllerMediaURL];
    

    
    NSURL *referenceUrl = info[UIImagePickerControllerReferenceURL];
    
//    self.currentImageData = [[NSData alloc] initWithContentsOfFile:[referenceUrl absoluteString]];
    
    NSString *extension = [[referenceUrl path] pathExtension];
    NSLog(@"The extension is %@", extension);
    self.fileExtension.text = extension;
    self.originalValues = [[NSMutableDictionary alloc] init];
    [self.originalValues setObject:self.fileExtension.text forKey:@"fileExtension"];
    
    NSMutableDictionary *mediaMetadata = (NSMutableDictionary *) [info objectForKey:UIImagePickerControllerMediaMetadata];
    self.exifData = mediaMetadata;
    
    self.imageView.image = fullImage;
    
    // image width and height (but with CGImageSourceRef)
    // below is from http://stackoverflow.com/questions/9766394/get-exif-data-from-uiimage-uiimagepickercontroller
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:[info objectForKey:UIImagePickerControllerReferenceURL]
             resultBlock:^(ALAsset *asset) {
                 
                 ALAssetRepresentation *image_representation = [asset defaultRepresentation];
                 
                 // create a buffer to hold image data
                 uint8_t *buffer = (Byte*)malloc(image_representation.size);
                 NSUInteger length = [image_representation getBytes:buffer fromOffset: 0.0  length:image_representation.size error:nil];
                 
                 NSString *fullFileName = [[asset defaultRepresentation] filename];
                 self.fileName.text = [fullFileName stringByDeletingPathExtension];
                 [self.originalValues setObject:self.fileName.text forKey:@"fileName"];
                 
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
                     
                     NSString *dimensions = [[[NSString stringWithFormat:@"%d",w] stringByAppendingString:@" x "] stringByAppendingString:[NSString stringWithFormat:@"%d",h]];
                     self.widthAndHeight.text = dimensions;
                     [self.originalValues setObject:self.widthAndHeight.text forKey:@"widthAndHeight"];
                     
                     // get exif data
                     CFDictionaryRef exif = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyExifDictionary);
                     self.originalExif = exif;
                     NSDictionary *exif_dict = (__bridge NSDictionary*)exif;
                     NSLog(@"exif_dict: %@",exif_dict);
                     
                     // get file size
                     ALAssetRepresentation *representation=[asset defaultRepresentation];
                     double fileSize = [representation size]/1024.0;
                     
                     NSLog(@"File size is: %f kilobytes", fileSize);
                     self.fileSize.text = [NSString stringWithFormat:@"%f KB", fileSize];
                     [self.originalValues setObject:self.fileSize.text forKey:@"fileSize"];
                     
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
                         if(!exifExposureTime) {
                             self.exifExposureTime.text = @"";
                         }
                         else {
                             self.exifExposureTime.text = [NSString stringWithFormat:@"%@", exifExposureTime];
                         }
                         [self.originalValues setObject:self.exifExposureTime.text forKey:@"exifExposureTime"];
                         
                         NSDecimalNumber *exifFNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifFNumber);
                         if(!exifFNumber) {
                             self.exifFNumber.text = @"";
                         }
                         else {
                             self.exifFNumber.text = [NSString stringWithFormat:@"%@", exifFNumber];
                         }
                         [self.originalValues setObject:self.exifFNumber.text forKey:@"exifFNumber"];
                         
                         NSDecimalNumber *exifExposureProgram = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureProgram);
                         if(!exifExposureProgram) {
                             self.exifExposureProgram.text = @"";
                         }
                         else {
                             self.exifExposureProgram.text = [NSString stringWithFormat:@"%@", exifExposureProgram];
                         }
                         [self.originalValues setObject:self.exifExposureProgram.text forKey:@"exifExposureProgram"];
                         
                         NSString *exifSpectralSensitivity = CFDictionaryGetValue(exif, kCGImagePropertyExifSpectralSensitivity);
                         if(!exifSpectralSensitivity) {
                             self.exifSpectralSensitivity.text = @"";
                         }
                         else {
                             self.exifSpectralSensitivity.text = exifSpectralSensitivity;
                         }
                         [self.originalValues setObject:self.exifSpectralSensitivity.text forKey:@"exifSpectralSensitivity"];
                         
                         NSDecimalNumber *exifISOSpeedRatings = CFDictionaryGetValue(exif, kCGImagePropertyExifISOSpeedRatings);
                         if(!exifISOSpeedRatings) {
                             self.exifISOSpeedRatings.text = @"";
                         }
                         else {
                             self.exifISOSpeedRatings.text = [NSString stringWithFormat:@"%@", exifISOSpeedRatings];
                         }
                         [self.originalValues setObject:self.exifISOSpeedRatings.text forKey:@"exifISOSpeedRatings"];
                         
                         NSString *exifOECF = CFDictionaryGetValue(exif, kCGImagePropertyExifOECF);
                         if(!exifOECF) {
                             self.exifOECF.text = @"";
                         }
                         else {
                             self.exifOECF.text = exifOECF;
                         }
                         [self.originalValues setObject:self.exifOECF.text forKey:@"exifOECF"];
                         
                         NSDecimalNumber *exifVersion = CFDictionaryGetValue(exif, kCGImagePropertyExifVersion);
                         if(!exifVersion) {
                             self.exifVersion.text = @"";
                         }
                         else {
                             self.exifVersion.text = [NSString stringWithFormat:@"%@", exifVersion];
                         }
                         [self.originalValues setObject:self.exifVersion.text forKey:@"exifVersion"];
                         
                         NSDecimalNumber *exifDateTimeOriginal = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeOriginal);
                         if(!exifDateTimeOriginal) {
                             self.dateTimeOriginal.text = @"";
                             self.dateTimeOriginalTime.text = @"";
                         }
                         else {
                             self.dateTimeOriginal.text = [self firstHalf:[NSString stringWithFormat:@"%@", exifDateTimeOriginal]];
                             self.dateTimeOriginalTime.text = [self secondHalf:[NSString stringWithFormat:@"%@", exifDateTimeOriginal]];
                         }
                         [self.originalValues setObject:self.dateTimeOriginal.text forKey:@"dateTimeOriginal"];
                         [self.originalValues setObject:self.dateTimeOriginalTime.text forKey:@"dateTimeOriginalTime"];
                         
                         NSDecimalNumber *exifDateTimeDigitized = CFDictionaryGetValue(exif, kCGImagePropertyExifDateTimeDigitized);
                         if(!exifDateTimeDigitized) {
                             NSLog(@"%d", 1);
                             self.dateTimeDigitized.text = @"";
                         }
                         else {
                             NSLog(@"%d", 2);
                             self.dateTimeDigitized.text = [NSString stringWithFormat:@"%@", exifDateTimeDigitized];
                         }
                         NSLog(@"value is: %@", self.dateTimeDigitized.text);
                         [self.originalValues setObject:self.dateTimeDigitized.text forKey:@"dateTimeDigitized"];
                         
                         NSDecimalNumber *exifComponentsConfiguration = CFDictionaryGetValue(exif, kCGImagePropertyExifComponentsConfiguration);
                         if(!exifComponentsConfiguration) {
                             self.exifComponentsConfiguration.text = @"";
                         }
                         else {
                             self.exifComponentsConfiguration.text = [NSString stringWithFormat:@"%@", exifComponentsConfiguration];
                         }
                         [self.originalValues setObject:self.exifComponentsConfiguration.text forKey:@"exifComponentsConfiguration"];
                         
                         NSDecimalNumber *exifCompressedBitsPerPixel = CFDictionaryGetValue(exif, kCGImagePropertyExifCompressedBitsPerPixel);
                         if(!exifComponentsConfiguration) {
                             self.exifCompressedBitsPerPixel.text = @"";
                         }
                         else {
                             self.exifCompressedBitsPerPixel.text = [NSString stringWithFormat:@"%@", exifCompressedBitsPerPixel];
                         }
                         [self.originalValues setObject:self.exifCompressedBitsPerPixel.text forKey:@"exifCompressedBitsPerPixel"];
                         
                         NSDecimalNumber *exifShutterSpeedValue = CFDictionaryGetValue(exif, kCGImagePropertyExifShutterSpeedValue);
                         if(!exifShutterSpeedValue) {
                             self.exifShutterSpeedValue.text = @"";
                         }
                         else {
                             self.exifShutterSpeedValue.text = [NSString stringWithFormat:@"%@", exifShutterSpeedValue];
                         }
                         [self.originalValues setObject:self.exifShutterSpeedValue.text forKey:@"exifShutterSpeedValue"];
                         
                         NSDecimalNumber *exifApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifApertureValue);
                         if(!exifApertureValue) {
                             self.exifApertureValue.text = @"";
                         }
                         else {
                             self.exifApertureValue.text = [NSString stringWithFormat:@"%@", exifApertureValue];
                         }
                         [self.originalValues setObject:self.exifApertureValue.text forKey:@"exifApertureValue"];
                         
                         NSDecimalNumber *exifBrightnessValue = CFDictionaryGetValue(exif, kCGImagePropertyExifBrightnessValue);
                         if(!exifBrightnessValue) {
                             self.exifBrightnessValue.text = @"";
                         }
                         else {
                             self.exifBrightnessValue.text = [NSString stringWithFormat:@"%@", exifBrightnessValue];
                         }
                         [self.originalValues setObject:self.exifBrightnessValue.text forKey:@"exifBrightnessValue"];
                         
                         NSDecimalNumber *exifExposureBiasValue = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureBiasValue);
                         if(!exifExposureBiasValue) {
                             self.exifExposureBiasValue.text = @"";
                         }
                         else {
                             self.exifExposureBiasValue.text = [NSString stringWithFormat:@"%@", exifExposureBiasValue];
                         }
                         [self.originalValues setObject:self.exifExposureBiasValue.text forKey:@"exifExposureBiasValue"];
                         
                         NSDecimalNumber *exifMaxApertureValue = CFDictionaryGetValue(exif, kCGImagePropertyExifMaxApertureValue);
                         if(!exifMaxApertureValue) {
                             self.exifMaxApertureValue.text = @"";
                         }
                         else {
                             self.exifMaxApertureValue.text = [NSString stringWithFormat:@"%@", exifMaxApertureValue];
                         }
                         [self.originalValues setObject:self.exifMaxApertureValue.text forKey:@"exifMaxApertureValue"];
                         
                         NSDecimalNumber *exifSubjectDistance = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectDistance);
                         if(!exifSubjectDistance) {
                             self.exifSubjectDistance.text = @"";
                         }
                         else {
                             self.exifSubjectDistance.text = [NSString stringWithFormat:@"%@", exifSubjectDistance];
                         }
                         [self.originalValues setObject:self.exifSubjectDistance.text forKey:@"exifSubjectDistance"];
                         
                         NSDecimalNumber *exifMeteringMode = CFDictionaryGetValue(exif, kCGImagePropertyExifMeteringMode);
                         if(!exifMeteringMode) {
                             self.exifMeteringMode.text = @"";
                         }
                         else {
                             self.exifMeteringMode.text = [NSString stringWithFormat:@"%@", exifMeteringMode];
                         }
                         [self.originalValues setObject:self.exifMeteringMode.text forKey:@"exifMeteringMode"];
                         
                         NSDecimalNumber *exifLightSource = CFDictionaryGetValue(exif, kCGImagePropertyExifLightSource);
                         if(!exifLightSource) {
                             self.exifLightSource.text = @"";
                         }
                         else {
                             self.exifLightSource.text = [NSString stringWithFormat:@"%@", exifLightSource];
                         }
                         [self.originalValues setObject:self.exifLightSource.text forKey:@"exifLightSource"];
                         
                         NSDecimalNumber *exifFlash = CFDictionaryGetValue(exif, kCGImagePropertyExifFlash);
                         if(!exifFlash) {
                             self.exifFlash.text = @"";
                         }
                         else {
                             self.exifFlash.text = [NSString stringWithFormat:@"%@", exifFlash];
                         }
                         [self.originalValues setObject:self.exifFlash.text forKey:@"exifFlash"];
                         
                         NSDecimalNumber *exifFocalLength = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalLength);
                         if(!exifFocalLength) {
                             self.exifFocalLength.text = @"";
                         }
                         else {
                             self.exifFocalLength.text = [NSString stringWithFormat:@"%@", exifFocalLength];
                         }
                         [self.originalValues setObject:self.exifFocalLength.text forKey:@"exifFocalLength"];
                         
                         NSDecimalNumber *exifSubjectArea = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectArea);
                         if(!exifSubjectArea) {
                             self.exifSubjectArea.text = @"";
                         }
                         else {
                             self.exifSubjectArea.text = [NSString stringWithFormat:@"%@", exifSubjectArea];
                         }
                         [self.originalValues setObject:self.exifSubjectArea.text forKey:@"exifSubjectArea"];
                         
                         NSString *exifMakerNote = CFDictionaryGetValue(exif, kCGImagePropertyExifMakerNote);
                         if(!exifMakerNote) {
                             self.exifMakerNote.text = @"";
                         }
                         else {
                             self.exifMakerNote.text = exifMakerNote;
                         }
                         [self.originalValues setObject:self.exifMakerNote.text forKey:@"exifMakerNote"];
                         
                         NSString *exifUserComment = CFDictionaryGetValue(exif, kCGImagePropertyExifUserComment);
                         if(!exifUserComment) {
                             self.exifUserComment.text = @"";
                         }
                         else {
                             self.exifUserComment.text = exifUserComment;
                         }
                         [self.originalValues setObject:self.exifUserComment.text forKey:@"exifUserComment"];
                         
                         NSString *exifSubsecTime = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTime);
                         if(!exifSubsecTime) {
                             self.exifSubsecTime.text = @"";
                         }
                         else {
                             self.exifSubsecTime.text = exifSubsecTime;
                         }
                         [self.originalValues setObject:self.exifSubsecTime.text forKey:@"exifSubsecTime"];
                         
                         NSDecimalNumber *exifSubsecTimeOrginal = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTimeOrginal);
                         if(!exifSubsecTimeOrginal) {
                             self.exifSubsecTimeOrginal.text = @"";
                         }
                         else {
                             self.exifSubsecTimeOrginal.text = [NSString stringWithFormat:@"%@", exifSubsecTimeOrginal];
                         }
                         [self.originalValues setObject:self.exifSubsecTimeOrginal.text forKey:@"exifSubsecTimeOrginal"];
                         
                         NSDecimalNumber *exifSubsecTimeDigitized = CFDictionaryGetValue(exif, kCGImagePropertyExifSubsecTimeDigitized);
                         if(!exifSubsecTimeDigitized) {
                             self.exifSubsecTimeDigitized.text = @"";
                         }
                         else {
                             self.exifSubsecTimeDigitized.text = [NSString stringWithFormat:@"%@", exifSubsecTimeDigitized];
                         }
                         [self.originalValues setObject:self.exifSubsecTimeDigitized.text forKey:@"exifSubsecTimeDigitized"];
                         
                         NSDecimalNumber *exifFlashPixVersion = CFDictionaryGetValue(exif, kCGImagePropertyExifFlashPixVersion);
                         if(!exifFlashPixVersion) {
                             self.exifFlashPixVersion.text = @"";
                         }
                         else {
                             self.exifFlashPixVersion.text = [NSString stringWithFormat:@"%@", exifFlashPixVersion];
                         }
                         [self.originalValues setObject:self.exifFlashPixVersion.text forKey:@"exifFlashPixVersion"];
                         
                         NSDecimalNumber *exifColorSpace = CFDictionaryGetValue(exif, kCGImagePropertyExifColorSpace);
                         if(!exifColorSpace) {
                             self.exifColorSpace.text = @"";
                         }
                         else {
                             self.exifColorSpace.text = [NSString stringWithFormat:@"%@", exifColorSpace];
                         }
                         [self.originalValues setObject:self.exifColorSpace.text forKey:@"exifColorSpace"];
                         
                         NSDecimalNumber *exifPixelXDimension = CFDictionaryGetValue(exif, kCGImagePropertyExifPixelXDimension);
                         if(!exifPixelXDimension) {
                             self.exifPixelXDimension.text = @"";
                         }
                         else {
                             self.exifPixelXDimension.text = [NSString stringWithFormat:@"%@", exifPixelXDimension];
                         }
                         [self.originalValues setObject:self.exifPixelXDimension.text forKey:@"exifPixelXDimension"];
                         
                         NSDecimalNumber *exifPixelYDimension = CFDictionaryGetValue(exif, kCGImagePropertyExifPixelYDimension);
                         if(!exifPixelYDimension) {
                             self.exifPixelYDimension.text = @"";
                         }
                         else {
                             self.exifPixelYDimension.text = [NSString stringWithFormat:@"%@", exifPixelYDimension];
                         }
                         [self.originalValues setObject:self.exifPixelYDimension.text forKey:@"exifPixelYDimension"];
                         
                         NSString *exifRelatedSoundFile = CFDictionaryGetValue(exif, kCGImagePropertyExifRelatedSoundFile);
                         if(!exifRelatedSoundFile) {
                             self.exifRelatedSoundFile.text = @"";
                         }
                         else {
                             self.exifRelatedSoundFile.text = exifRelatedSoundFile;
                         }
                         [self.originalValues setObject:self.exifRelatedSoundFile.text forKey:@"exifRelatedSoundFile"];
                         
                         NSDecimalNumber *exifFlashEnergy = CFDictionaryGetValue(exif, kCGImagePropertyExifFlashEnergy);
                         if(!exifFlashEnergy) {
                             self.exifFlashEnergy.text = @"";
                         }
                         else {
                             self.exifFlashEnergy.text = [NSString stringWithFormat:@"%@", exifFlashEnergy];
                         }
                         [self.originalValues setObject:self.exifFlashEnergy.text forKey:@"exifFlashEnergy"];
                         
                         NSDecimalNumber *exifSpatialFrequencyResponse = CFDictionaryGetValue(exif, kCGImagePropertyExifSpatialFrequencyResponse);
                         if(!exifSpatialFrequencyResponse) {
                             self.exifSpatialFrequencyResponse.text = @"";
                         }
                         else {
                             self.exifSpatialFrequencyResponse.text = [NSString stringWithFormat:@"%@", exifSpatialFrequencyResponse];
                         }
                         [self.originalValues setObject:self.exifSpatialFrequencyResponse.text forKey:@"exifSpatialFrequencyResponse"];
                         
                         NSDecimalNumber *exifFocalPlaneXResolution = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneXResolution);
                         if(!exifFocalPlaneXResolution) {
                             self.exifFocalPlaneXResolution.text = @"";
                         }
                         else {
                             self.exifFocalPlaneXResolution.text = [NSString stringWithFormat:@"%@", exifFocalPlaneXResolution];
                         }
                         [self.originalValues setObject:self.exifFocalPlaneXResolution.text forKey:@"exifFocalPlaneXResolution"];
                         
                         NSDecimalNumber *exifFocalPlaneYResolution = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneYResolution);
                         if(!exifFocalPlaneYResolution) {
                             self.exifFocalPlaneYResolution.text = @"";
                         }
                         else {
                             self.exifFocalPlaneYResolution.text = [NSString stringWithFormat:@"%@", exifFocalPlaneYResolution];
                         }
                         [self.originalValues setObject:self.exifFocalPlaneYResolution.text forKey:@"exifFocalPlaneYResolution"];
                         
                         NSDecimalNumber *exifFocalPlaneResolutionUnit = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalPlaneResolutionUnit);
                         if(!exifFocalPlaneResolutionUnit) {
                             self.exifFocalPlaneResolutionUnit.text = @"";
                         }
                         else {
                             self.exifFocalPlaneResolutionUnit.text = [NSString stringWithFormat:@"%@", exifFocalPlaneResolutionUnit];
                         }
                         [self.originalValues setObject:self.exifFocalPlaneResolutionUnit.text forKey:@"exifFocalPlaneResolutionUnit"];
                         
                         NSDecimalNumber *exifSubjectLocation = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectLocation);
                         if(!exifSubjectLocation) {
                             self.exifSubjectLocation.text = @"";
                         }
                         else {
                             self.exifSubjectLocation.text = [NSString stringWithFormat:@"%@", exifSubjectLocation];
                         }
                         [self.originalValues setObject:self.exifSubjectLocation.text forKey:@"exifSubjectLocation"];
                         
                         NSDecimalNumber *exifExposureIndex = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureIndex);
                         if(!exifExposureIndex) {
                             self.exifExposureIndex.text = @"";
                         }
                         else {
                             self.exifExposureIndex.text = [NSString stringWithFormat:@"%@", exifExposureIndex];
                         }
                         [self.originalValues setObject:self.exifExposureIndex.text forKey:@"exifExposureIndex"];
                         
                         NSDecimalNumber *exifSensingMethod = CFDictionaryGetValue(exif, kCGImagePropertyExifSensingMethod);
                         if(!exifSensingMethod) {
                             self.exifSensingMethod.text = @"";
                         }
                         else {
                             self.exifSensingMethod.text = [NSString stringWithFormat:@"%@", exifSensingMethod];
                         }
                         [self.originalValues setObject:self.exifSensingMethod.text forKey:@"exifSensingMethod"];
                         
                         NSDecimalNumber *exifFileSource = CFDictionaryGetValue(exif, kCGImagePropertyExifFileSource);
                         if(!exifFileSource) {
                             self.exifFileSource.text = @"";
                         }
                         else {
                             self.exifFileSource.text = [NSString stringWithFormat:@"%@", exifFileSource];
                         }
                         [self.originalValues setObject:self.exifFileSource.text forKey:@"exifFileSource"];
                         
                         NSDecimalNumber *exifSceneType = CFDictionaryGetValue(exif, kCGImagePropertyExifSceneType);
                         if(!exifSceneType) {
                             self.exifSceneType.text = @"";
                         }
                         else {
                             self.exifSceneType.text = [NSString stringWithFormat:@"%@", exifSceneType];
                         }
                         [self.originalValues setObject:self.exifSceneType.text forKey:@"exifSceneType"];
                         
                         NSDecimalNumber *exifCFAPattern = CFDictionaryGetValue(exif, kCGImagePropertyExifCFAPattern);
                         if(!exifCFAPattern) {
                             self.exifCFAPattern.text = @"";
                         }
                         else {
                             self.exifCFAPattern.text = [NSString stringWithFormat:@"%@", exifCFAPattern];
                         }
                         [self.originalValues setObject:self.exifCFAPattern.text forKey:@"exifCFAPattern"];
                         
                         NSDecimalNumber *exifCustomRendered = CFDictionaryGetValue(exif, kCGImagePropertyExifCustomRendered);
                         if(!exifCustomRendered) {
                             self.exifCustomRendered.text = @"";
                         }
                         else {
                             self.exifCustomRendered.text = [NSString stringWithFormat:@"%@", exifCustomRendered];
                         }
                         [self.originalValues setObject:self.exifCustomRendered.text forKey:@"exifCustomRendered"];
                         
                         NSDecimalNumber *exifExposureMode = CFDictionaryGetValue(exif, kCGImagePropertyExifExposureMode);
                         if(!exifExposureMode) {
                             self.exifExposureMode.text = @"";
                         }
                         else {
                             self.exifExposureMode.text = [NSString stringWithFormat:@"%@", exifExposureMode];
                         }
                         [self.originalValues setObject:self.exifExposureMode.text forKey:@"exifExposureMode"];
                         
                         NSDecimalNumber *exifWhiteBalance = CFDictionaryGetValue(exif, kCGImagePropertyExifWhiteBalance);
                         if(!exifWhiteBalance) {
                             self.exifWhiteBalance.text = @"";
                         }
                         else {
                             self.exifWhiteBalance.text = [NSString stringWithFormat:@"%@", exifWhiteBalance];
                         }
                         [self.originalValues setObject:self.exifWhiteBalance.text forKey:@"exifWhiteBalance"];
                         
                         NSDecimalNumber *exifDigitalZoomRatio = CFDictionaryGetValue(exif, kCGImagePropertyExifDigitalZoomRatio);
                         if(!exifDigitalZoomRatio) {
                             self.exifDigitalZoomRatio.text = @"";
                         }
                         else {
                             self.exifDigitalZoomRatio.text = [NSString stringWithFormat:@"%@", exifDigitalZoomRatio];
                         }
                         [self.originalValues setObject:self.exifDigitalZoomRatio.text forKey:@"exifDigitalZoomRatio"];
                         
                         NSDecimalNumber *exifFocalLenIn35mmFilm = CFDictionaryGetValue(exif, kCGImagePropertyExifFocalLenIn35mmFilm);
                         if(!exifFocalLenIn35mmFilm) {
                             self.exifFocalLenIn35mmFilm.text = @"";
                         }
                         else {
                             self.exifFocalLenIn35mmFilm.text = [NSString stringWithFormat:@"%@", exifFocalLenIn35mmFilm];
                         }
                         [self.originalValues setObject:self.exifFocalLenIn35mmFilm.text forKey:@"exifFocalLenIn35mmFilm"];
                         
                         NSDecimalNumber *exifSceneCaptureType = CFDictionaryGetValue(exif, kCGImagePropertyExifSceneCaptureType);
                         if(!exifSceneCaptureType) {
                             self.exifSceneCaptureType.text = @"";
                         }
                         else {
                             self.exifSceneCaptureType.text = [NSString stringWithFormat:@"%@", exifSceneCaptureType];
                         }
                         [self.originalValues setObject:self.exifSceneCaptureType.text forKey:@"exifSceneCaptureType"];
                         
                         NSDecimalNumber *exifGainControl = CFDictionaryGetValue(exif, kCGImagePropertyExifGainControl);
                         if(!exifGainControl) {
                             self.exifGainControl.text = @"";
                         }
                         else {
                             self.exifGainControl.text = self.exifContrast.text = [NSString stringWithFormat:@"%@", exifGainControl];
                         }
                         [self.originalValues setObject:self.exifGainControl.text forKey:@"exifGainControl"];

                         NSDecimalNumber *exifContrast = CFDictionaryGetValue(exif, kCGImagePropertyExifContrast);
                         if(!exifContrast) {
                             self.exifContrast.text = @"";
                         }
                         else {
                             self.exifContrast.text = [NSString stringWithFormat:@"%@", exifContrast];
                         }
                         [self.originalValues setObject:self.exifContrast.text forKey:@"exifContrast"];
                         
                         NSDecimalNumber *exifSaturation = CFDictionaryGetValue(exif, kCGImagePropertyExifSaturation);
                         if(!exifSaturation) {
                             self.exifSaturation.text = @"";
                         }
                         else {
                             self.exifSaturation.text = [NSString stringWithFormat:@"%@", exifSaturation];
                         }
                         [self.originalValues setObject:self.exifSaturation.text forKey:@"exifSaturation"];
                         
                         NSDecimalNumber *exifSharpness = CFDictionaryGetValue(exif, kCGImagePropertyExifSharpness);
                         if(!exifSharpness) {
                             self.exifSharpness.text = @"";
                         }
                         else {
                             self.exifSharpness.text = [NSString stringWithFormat:@"%@", exifSharpness];
                         }
                         [self.originalValues setObject:self.exifSharpness.text forKey:@"exifSharpness"];
                         
                         NSDecimalNumber *exifDeviceSettingDescription = CFDictionaryGetValue(exif, kCGImagePropertyExifDeviceSettingDescription);
                         if(!exifDeviceSettingDescription) {
                             self.exifDeviceSettingDescription.text = @"";
                         }
                         else {
                             self.exifDeviceSettingDescription.text = [NSString stringWithFormat:@"%@", exifDeviceSettingDescription];
                         }
                         [self.originalValues setObject:self.exifDeviceSettingDescription.text forKey:@"exifDeviceSettingDescription"];
                         
                         NSDecimalNumber *exifSubjectDistRange = CFDictionaryGetValue(exif, kCGImagePropertyExifSubjectDistRange);
                         if(!exifSubjectDistRange) {
                             self.exifSubjectDistRange.text = @"";
                         }
                         else {
                             self.exifSubjectDistRange.text = [NSString stringWithFormat:@"%@", exifSubjectDistRange];
                         }
                         [self.originalValues setObject:self.exifSubjectDistRange.text forKey:@"exifSubjectDistRange"];
                         
                         NSString *exifImageUniqueID = CFDictionaryGetValue(exif, kCGImagePropertyExifImageUniqueID);
                         if(!exifImageUniqueID) {
                             self.exifImageUniqueID.text = @"";
                         }
                         else {
                             self.exifImageUniqueID.text = exifImageUniqueID;
                         }
                         [self.originalValues setObject:self.exifImageUniqueID.text forKey:@"exifImageUniqueID"];
                         
                         NSDecimalNumber *exifGamma = CFDictionaryGetValue(exif, kCGImagePropertyExifGamma);
                         if(!exifGamma) {
                             self.exifGamma.text = @"";
                         }
                         else {
                             self.exifGamma.text = [NSString stringWithFormat:@"%@", exifGamma];
                         }
                         [self.originalValues setObject:self.exifGamma.text forKey:@"exifGamma"];
                         
                         NSDecimalNumber *exifCameraOwnerName = CFDictionaryGetValue(exif, kCGImagePropertyExifCameraOwnerName);
                         if(!exifCameraOwnerName) {
                             self.exifCameraOwnerName.text = @"";
                         }
                         else {
                             self.exifCameraOwnerName.text = [NSString stringWithFormat:@"%@", exifCameraOwnerName];
                         }
                         [self.originalValues setObject:self.exifCameraOwnerName.text forKey:@"exifCameraOwnerName"];
                         
                         NSDecimalNumber *exifBodySerialNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifBodySerialNumber);
                         if(!exifBodySerialNumber) {
                             self.exifBodySerialNumber.text = @"";
                         }
                         else {
                             self.exifBodySerialNumber.text = [NSString stringWithFormat:@"%@", exifBodySerialNumber];
                         }
                         [self.originalValues setObject:self.exifBodySerialNumber.text forKey:@"exifBodySerialNumber"];
                         
                         NSDecimalNumber *exifLensSpecification = CFDictionaryGetValue(exif, kCGImagePropertyExifLensSpecification);
                         if(!exifLensSpecification) {
                             self.exifLensSpecification.text = @"";
                         }
                         else {
                             self.exifLensSpecification.text = [NSString stringWithFormat:@"%@", exifLensSpecification];
                         }
                         [self.originalValues setObject:self.exifLensSpecification.text forKey:@"exifLensSpecification"];
                         
                         NSDecimalNumber *exifLensMake = CFDictionaryGetValue(exif, kCGImagePropertyExifLensMake);
                         if(!exifLensMake) {
                             self.exifLensMake.text = @"";
                         }
                         else {
                             self.exifLensMake.text = [NSString stringWithFormat:@"%@", exifLensMake];
                         }
                         [self.originalValues setObject:self.exifLensMake.text forKey:@"exifLensMake"];
                         
                         NSDecimalNumber *exifLensModel = CFDictionaryGetValue(exif, kCGImagePropertyExifLensModel);
                         if(!exifLensModel) {
                             self.exifLensModel.text = @"";
                         }
                         else {
                             self.exifLensModel.text = [NSString stringWithFormat:@"%@", exifLensModel];
                         }
                         [self.originalValues setObject:self.exifLensModel.text forKey:@"exifLensModel"];
                         
                         NSDecimalNumber *exifLensSerialNumber = CFDictionaryGetValue(exif, kCGImagePropertyExifLensSerialNumber);
                         if(!exifLensSerialNumber) {
                             self.exifLensSerialNumber.text = @"";
                         }
                         else {
                             self.exifLensSerialNumber.text = [NSString stringWithFormat:@"%@", exifLensSerialNumber];
                         }
                         [self.originalValues setObject:self.exifLensSerialNumber.text forKey:@"exifLensSerialNumber"];
                     }
                     
                     // Get video duration
//                     NSString *duration = [asset valueForProperty:ALAssetPropertyDuration];
//                     if([duration isEqualToString: @"ALErrorInvalidProperty"]) {
//                         self.duration.text = @"";
//                     }
//                     else {
//                         self.duration.text = duration;
//                     }
                     
                     // get gps data
                     CFDictionaryRef gps = (CFDictionaryRef)CFDictionaryGetValue(imagePropertiesDictionary, kCGImagePropertyGPSDictionary);
                     self.originalGps = gps;
                     NSDictionary *gps_dict = (__bridge NSDictionary*)gps;
                     NSLog(@"gps_dict: %@",gps_dict);
                     
                     if(gps_dict) {
                         NSDecimalNumber *version = CFDictionaryGetValue(gps, kCGImagePropertyGPSVersion);
                         if(!version) {
                             self.gpsVersion.text = @"";
                         }
                         else {
                             self.gpsVersion.text = [NSString stringWithFormat:@"%@", version];
                         }
                         [self.originalValues setObject:self.gpsVersion.text forKey:@"gpsVersion"];
                         
                         NSDecimalNumber *latitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitudeRef);
                         self.gpsLatitudeRef.text = [NSString stringWithFormat:@"%@", latitudeRef];
                         [self.originalValues setObject:self.gpsLatitudeRef.text forKey:@"gpsLatitudeRef"];
                         
                         NSDecimalNumber *latitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSLatitude);
                         self.gpsLatitude.text = [NSString stringWithFormat:@"%@", latitude];
                         [self.originalValues setObject:self.gpsLatitude.text forKey:@"gpsLatitude"];
                         
                         NSDecimalNumber *longitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitudeRef);
                         self.gpsLongitudeRef.text = [NSString stringWithFormat:@"%@", longitudeRef];
                         [self.originalValues setObject:self.gpsLongitudeRef.text forKey:@"gpsLongitudeRef"];
                         
                         NSDecimalNumber *longitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSLongitude);
                         self.gpsLongitude.text = [NSString stringWithFormat:@"%@", longitude];
                         [self.originalValues setObject:self.gpsLongitude.text forKey:@"gpsLongitude"];
                         
                         // Google maps
                         /*
                          * Might have to check if the user is using iOS 8.
                          * Apparently, the NSLocationWhenInUseUsageDescription and
                          * NSLocationAlwaysUsageDescription keys in the info.plist
                          * file might cause problems in earlier versions.
                          */
                         
                         if([self.gpsLatitudeRef.text isEqualToString:@"N"]) {
                             self.latval = [latitude doubleValue];
                         }
                         else {
                             self.latval = -1*[latitude doubleValue];
                         }
                         if([self.gpsLatitudeRef.text isEqualToString:@"E"]) {
                             self.longval = [longitude doubleValue];
                         }
                         else {
                             self.longval = -1*[longitude doubleValue];
                         }
                         
                         /*
                         // Create a GMSCameraPosition that tells the map to display the
                         // coordinate -33.86,151.20 at zoom level 6.
                         self.camera = [GMSCameraPosition cameraWithLatitude:latval
                                                                   longitude:longval
                                                                        zoom:6];
                         self.mapView = [GMSMapView mapWithFrame:CGRectMake(0, 3280, self.screenW, 220) camera:self.camera];
//                         self.mapView.settings.compassButton = YES;
                         self.mapView.myLocationEnabled = YES;
                         self.mapView.settings.myLocationButton = YES;
                         NSLog(@"User's location: %@", self.mapView.myLocation);
                         [self.scrollView addSubview:self.mapView];
                         
                         [self.mapView addObserver:self
                                    forKeyPath:@"myLocation"
                                       options:NSKeyValueObservingOptionNew
                                       context:NULL];
                         // Ask for My Location data after the map has already been added to the UI.
                         dispatch_async(dispatch_get_main_queue(), ^{
                             self.mapView.myLocationEnabled = YES;
                         });
                         
                         // Creates a marker in the center of the map.
                         GMSMarker *marker = [[GMSMarker alloc] init];
                         marker.position = CLLocationCoordinate2DMake(latval, longval);
                         marker.title = @"Location";
                         marker.snippet = [[NSString stringWithFormat:@"%f", latval] stringByAppendingString:[NSString stringWithFormat:@", %f",longval]];
                         marker.map = self.mapView;
                         */
                         
                         // Apple maps
                         
                         
                         
                         // Test location in Cairo, Egypt
//                         self.latval = 30.05;
//                         self.longval = 31.2333;
                         
                         MKCoordinateRegion region;
                         region.center.latitude = self.latval;
                         region.center.longitude = self.longval;
                         region.span.latitudeDelta = 0.01;
                         region.span.longitudeDelta = 0.01;
                         
                         [self.gpsMapView setRegion:region animated:YES];
                         
                         // Annotation
                         MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
                         point.coordinate = CLLocationCoordinate2DMake(self.latval, self.longval);
                         point.title = @"Image location";
                         point.subtitle = [[NSString stringWithFormat:@"%f", self.latval] stringByAppendingString:[NSString stringWithFormat:@", %f", self.longval]];
                         
                         [self.gpsMapView addAnnotation:point];
                         
//                         MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.gpsMapView];
//                         self.navigationItem.rightBarButtonItem = buttonItem;
//                         
//                         [self.gpsMapView addSubview:self.userHeadingBtn];
                         
                         
                         NSDecimalNumber *altitudeRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitudeRef);
                         if(!altitudeRef) {
                             self.gpsAltitudeRef.text = @"";
                         }
                         else {
                             self.gpsAltitudeRef.text = [NSString stringWithFormat:@"%@", altitudeRef];
                         }
                         [self.originalValues setObject:self.gpsAltitudeRef.text forKey:@"gpsAltitudeRef"];
                         
                         NSDecimalNumber *altitude = CFDictionaryGetValue(gps, kCGImagePropertyGPSAltitude);
                         if(!altitude) {
                             self.gpsAltitude.text = @"";
                         }
                         else {
                             self.gpsAltitude.text = [NSString stringWithFormat:@"%@", altitude];
                         }
                         [self.originalValues setObject:self.gpsAltitude.text forKey:@"gpsAltitude"];
                         
                         NSDecimalNumber *timeStamp = CFDictionaryGetValue(gps, kCGImagePropertyGPSTimeStamp);
                         if(!timeStamp) {
                             self.gpsTimeStamp.text = @"";
                         }
                         else {
                             self.gpsTimeStamp.text = [NSString stringWithFormat:@"%@", timeStamp];
                         }
                         [self.originalValues setObject:self.gpsTimeStamp.text forKey:@"gpsTimeStamp"];
                         
                         NSDecimalNumber *satellites = CFDictionaryGetValue(gps, kCGImagePropertyGPSSatellites);
                         if(!satellites) {
                             self.gpsSatellites.text = @"";
                         }
                         else {
                             self.gpsSatellites.text = [NSString stringWithFormat:@"%@", satellites];
                         }
                         [self.originalValues setObject:self.gpsSatellites.text forKey:@"gpsSatellites"];
                         
                         NSDecimalNumber *status = CFDictionaryGetValue(gps, kCGImagePropertyGPSStatus);
                         if(!status) {
                             self.gpsStatus.text = @"";
                         }
                         else {
                             self.gpsStatus.text = [NSString stringWithFormat:@"%@", status];
                         }
                         [self.originalValues setObject:self.gpsStatus.text forKey:@"gpsStatus"];
                         
                         NSDecimalNumber *measureMode = CFDictionaryGetValue(gps, kCGImagePropertyGPSMeasureMode);
                         if(!measureMode) {
                             self.gpsMeasureMode.text = @"";
                         }
                         else {
                             self.gpsMeasureMode.text = [NSString stringWithFormat:@"%@", measureMode];
                         }
                         [self.originalValues setObject:self.gpsMeasureMode.text forKey:@"gpsMeasureMode"];
                         
                         NSDecimalNumber *degreeOfPrecision = CFDictionaryGetValue(gps, kCGImagePropertyGPSDOP);
                         if(!degreeOfPrecision) {
                             self.gpsDegreeOfPrecision.text = @"";
                         }
                         else {
                             self.gpsDegreeOfPrecision.text = [NSString stringWithFormat:@"%@", degreeOfPrecision];
                         }
                         [self.originalValues setObject:self.gpsDegreeOfPrecision.text forKey:@"gpsDegreeOfPrecision"];
                         
                         NSDecimalNumber *speedRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSSpeedRef);
                         if(!speedRef) {
                             self.gpsSpeedRef.text = @"";
                         }
                         else {
                             self.gpsSpeedRef.text = [NSString stringWithFormat:@"%@", speedRef];
                         }
                         [self.originalValues setObject:self.gpsSpeedRef.text forKey:@"gpsSpeedRef"];
                         
                         NSDecimalNumber *speed = CFDictionaryGetValue(gps, kCGImagePropertyGPSSpeed);
                         if(!speed) {
                             self.gpsSpeed.text = @"";
                         }
                         else {
                             self.gpsSpeed.text = [NSString stringWithFormat:@"%@", speed];
                         }
                         [self.originalValues setObject:self.gpsSpeed.text forKey:@"gpsSpeed"];
                         
                         NSDecimalNumber *trackRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSTrackRef);
                         if(!trackRef) {
                             self.gpsTrackRef.text = @"";
                         }
                         else {
                             self.gpsTrackRef.text = [NSString stringWithFormat:@"%@", trackRef];
                         }
                         [self.originalValues setObject:self.gpsTrackRef.text forKey:@"gpsTrackRef"];
                         
                         NSDecimalNumber *track = CFDictionaryGetValue(gps, kCGImagePropertyGPSTrack);
                         if(!track) {
                             self.gpsTrack.text = @"";
                         }
                         else {
                             self.gpsTrack.text = [NSString stringWithFormat:@"%@", track];
                         }
                         [self.originalValues setObject:self.gpsTrack.text forKey:@"gpsTrack"];
                         
                         NSString *imgDirectionRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSImgDirectionRef);
                         if(!imgDirectionRef) {
                             self.gpsImgDirectionRef.text = @"";
                         }
                         else {
                             self.gpsImgDirectionRef.text = imgDirectionRef;
                         }
                         [self.originalValues setObject:self.gpsImgDirectionRef.text forKey:@"gpsImgDirectionRef"];
                         
                         NSDecimalNumber *imgDirection = CFDictionaryGetValue(gps, kCGImagePropertyGPSImgDirection);
                         if(!imgDirection) {
                             self.gpsImgDirection.text = @"";
                         }
                         else {
                             self.gpsImgDirection.text = [NSString stringWithFormat:@"%@", imgDirection];
                         }
                         [self.originalValues setObject:self.gpsImgDirection.text forKey:@"gpsImgDirection"];
                         
                         NSDecimalNumber *mapDatum = CFDictionaryGetValue(gps, kCGImagePropertyGPSMapDatum);
                         if(!mapDatum) {
                             self.gpsMapDatum.text = @"";
                         }
                         else {
                             self.gpsMapDatum.text = [NSString stringWithFormat:@"%@", mapDatum];
                         }
                         [self.originalValues setObject:self.gpsMapDatum.text forKey:@"gpsMapDatum"];
                         
                         NSDecimalNumber *destLatRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLatitudeRef);
                         if(!destLatRef) {
                             self.gpsDestLatRef.text = @"";
                         }
                         else {
                             self.gpsDestLatRef.text = [NSString stringWithFormat:@"%@", destLatRef];
                         }
                         [self.originalValues setObject:self.gpsDestLatRef.text forKey:@"gpsDestLatRef"];
                         
                         NSDecimalNumber *destLat = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLatitude);
                         if(!destLat) {
                             self.gpsDestLat.text = @"";
                         }
                         else {
                             self.gpsDestLat.text = [NSString stringWithFormat:@"%@", destLat];
                         }
                         [self.originalValues setObject:self.gpsDestLat.text forKey:@"gpsDestLat"];
                         
                         NSDecimalNumber *destLongRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLongitudeRef);
                         if(!destLongRef) {
                             self.gpsDestLongRef.text = @"";
                         }
                         else {
                             self.gpsDestLongRef.text = [NSString stringWithFormat:@"%@", destLongRef];
                         }
                         [self.originalValues setObject:self.gpsDestLongRef.text forKey:@"gpsDestLongRef"];
                         
                         NSDecimalNumber *destLong = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestLongitude);
                         if(!destLong) {
                             self.gpsDestLong.text = @"";
                         }
                         else {
                             self.gpsDestLong.text = [NSString stringWithFormat:@"%@", destLong];
                         }
                         [self.originalValues setObject:self.gpsDestLong.text forKey:@"gpsDestLong"];
                         
                         NSString *destBearingRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestBearingRef);
                         if(!destBearingRef) {
                             self.gpsDestBearingRef.text = @"";
                         }
                         else {
                             self.gpsDestBearingRef.text = destBearingRef;
                         }
                         [self.originalValues setObject:self.gpsDestBearingRef.text forKey:@"gpsDestBearingRef"];
                         
                         NSDecimalNumber *destBearing = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestBearing);
                         if(!destBearing) {
                             self.gpsDestBearing.text = @"";
                         }
                         else {
                             self.gpsDestBearing.text = [NSString stringWithFormat:@"%@", destBearing];
                         }
                         [self.originalValues setObject:self.gpsDestBearing.text forKey:@"gpsDestBearing"];
                         
                         NSString *destDistanceRef = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestDistanceRef);
                         if(!destDistanceRef) {
                             self.gpsDestDistanceRef.text = @"";
                         }
                         else {
                             self.gpsDestDistanceRef.text = destDistanceRef;
                         }
                         [self.originalValues setObject:self.gpsDestDistanceRef.text forKey:@"gpsDestDistanceRef"];
                         
                         NSDecimalNumber *destDistance = CFDictionaryGetValue(gps, kCGImagePropertyGPSDestDistance);
                         if(!destDistance) {
                             self.gpsDestDistance.text = @"";
                         }
                         else {
                             self.gpsDestDistance.text = [NSString stringWithFormat:@"%@", destDistance];
                         }
                         [self.originalValues setObject:self.gpsDestDistance.text forKey:@"gpsDestDistance"];
                         
                         NSDecimalNumber *processingMethod = CFDictionaryGetValue(gps, kCGImagePropertyGPSProcessingMethod);
                         if(!processingMethod) {
                             self.gpsProcessingMethod.text = @"";
                         }
                         else {
                             self.gpsProcessingMethod.text = [NSString stringWithFormat:@"%@", processingMethod];
                         }
                         [self.originalValues setObject:self.gpsProcessingMethod.text forKey:@"gpsProcessingMethod"];
                         
                         NSString *areaInformation = CFDictionaryGetValue(gps, kCGImagePropertyGPSAreaInformation);
                         if(!areaInformation) {
                             self.gpsAreaInformation.text = @"";
                         }
                         else {
                             self.gpsAreaInformation.text = areaInformation;
                         }
                         [self.originalValues setObject:self.gpsAreaInformation.text forKey:@"gpsAreaInformation"];
                         
                         NSString *dateStamp = CFDictionaryGetValue(gps, kCGImagePropertyGPSDateStamp);
                         if(!dateStamp) {
                             self.gpsDateStamp.text = @"";
                         }
                         else {
                             self.gpsDateStamp.text = dateStamp;
                         }
                         [self.originalValues setObject:self.gpsDateStamp.text forKey:@"gpsDateStamp"];
                         
                         NSDecimalNumber *differental = CFDictionaryGetValue(gps, kCGImagePropertyGPSDifferental);
                         if(!differental) {
                             self.gpsDifferental.text = @"";
                         }
                         else {
                             self.gpsDifferental.text = [NSString stringWithFormat:@"%@", differental];
                         }
                         [self.originalValues setObject:self.gpsDifferental.text forKey:@"gpsDifferental"];
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
- (NSString *)deviceLocation
{
    NSString *theLocation = [NSString stringWithFormat:@"latitude: %f longitude: %f", self.locationManager.location.coordinate.latitude, self.locationManager.location.coordinate.longitude];
    return theLocation;
}

/**
 *  Dismisses the keyboard and hides the description view when the user clicks the view.
 */
-(void)dismissKeyboard {
    [self.view endEditing:YES];
    [self.item removeFromSuperview];
    [self.itemInfo removeFromSuperview];
//    [UIView animateWithDuration:0.3 animations:^() {
//        self.descriptionView.alpha = 0.0;
//    }];
}

/**
 *  Gets the current location for when the user writes new GPS data. No function actually calls this yet.
 */
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

/**
 *  Makes the image full screen.
 */
- (void)imageZoomPressed {
    [self dismissKeyboard];
    self.imageZoom = [[XLMediaZoom alloc] initWithAnimationTime:@(0.5) image:self.imageView blurEffect:YES];
    [self.view addSubview:self.imageZoom];
    [self.imageZoom show];
}

/**
 *  Gets a point on the scrollview using the .frame value of the text field.
 *  Used for automatically focusing on the textfield when the user begins editing it.
 */
CGPoint pointFromRectangle(CGRect rect) {
    
    return CGPointMake(0, rect.origin.y-200);
}

/**
 *  When the user begins editing a text field:
 *      1) Any previous description views are dismissed
 *      2) It focuses on the textfield automatically
 *      3) Sets the current tag for use in the Reset and Identify functions.
 *      4) Sets the textfield being edited for use in Reset. I suppose I could just use the current tag for this.
 *      5) Shows the tool bar above the keyboard
 */
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"did begin editing");
    
    [self.item removeFromSuperview];
    [self.itemInfo removeFromSuperview];
    [KLCPopup dismissAllPopups];
    
    [self.scrollView setContentOffset:(pointFromRectangle(textField.frame)) animated:YES];
    
    self.currentTag = textField.tag;
    self.currentlyBeingEdited = textField;
    [textField addTarget:self
                  action:@selector(textFieldDidChange:)
        forControlEvents:UIControlEventEditingChanged];
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    //    numberToolbar.tintColor = [UIColor whiteColor];
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStylePlain target:self action:@selector(resetPressed)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"What is this?" style:UIBarButtonItemStylePlain target:self action:@selector(identifyPressed)],
                           nil];
    [numberToolbar sizeToFit];
    textField.inputAccessoryView = numberToolbar;
    
    // check if the text field should have only numbers in it
//    if(self.currentTag == ) {
        [self checkIfNumber];
//    }
}

/**
 *  Checks if the the string contains something that isn't a number.
 *  Called in textFieldDidBeginEditing and textFieldDidChange.
 */
- (void)checkIfNumber {
    long t = self.currentlyBeingEdited.tag;
    if(t == 2 || t == 3 || t == 4 || t == 10 || t == 11 || t == 12 ||
       t == 13 || t == 14 || t == 15 || t == 16 || t == 17 || t == 18 || t == 19 ||
       t == 20 || t == 24 || t == 25 || t == 26 || t == 28 || t == 29 || t == 30 ||
       t == 32 || t == 34 ||
       t == 35 || t == 36 || t == 37 || t == 38 || t == 39 || t == 43 || t == 44 ||
       t == 45 || t == 46 || t == 47 || t == 48 || t == 49 || t == 50 || t == 51 ||
       t == 52 || t == 54 || t == 73 || t == 75 || t == 77 || t == 78 || t == 82 ||
       t == 84 || t == 86 || t == 88 || t == 91 || t == 93 || t == 95 || t == 97 ||
       t == 101) {
        NSNumberFormatter *s = [[NSNumberFormatter alloc] init];
        
        // If s is null, then the text field contains something that isn't a number
        if(![s numberFromString: self.currentlyBeingEdited.text] &&
           ![self.currentlyBeingEdited.text isEqualToString:@""]) {
            self.numberView = [[UIView alloc] initWithFrame:CGRectMake(10, 0, self.screenW-20, 60)];
            self.numberView.backgroundColor = [UIColor redColor];
            [self.numberView setAlpha:0.9];
            
            self.numberWarning = [[UITextView alloc] initWithFrame:CGRectMake((self.screenW-20)/2-(self.screenW-40)/2, 10, self.screenW-40, 40)];
            self.numberWarning.backgroundColor = [UIColor redColor];
            [self.numberWarning setFont:[UIFont fontWithName:@"Avenir-Heavy" size:26]];
            self.numberWarning.text = @"You must enter a number.";
            [self.numberView addSubview:self.numberWarning];
            
            self.numberPopup = [KLCPopup popupWithContentView:self.numberView
                                                     showType:KLCPopupShowTypeSlideInFromTop dismissType:KLCPopupDismissTypeSlideOutToTop maskType:KLCPopupMaskTypeNone dismissOnBackgroundTouch:YES dismissOnContentTouch:YES];
            if(![self.numberPopup isShowing]) {
                NSLog(@"the number popup is currently showing");
                [self.numberPopup showWithLayout:KLCPopupLayoutMake(KLCPopupHorizontalLayoutCenter, KLCPopupVerticalLayoutTop)];
            }
        }
    }
    else {
        NSLog(@"you are editing a string");
    }
}

/**
 *  Dismisses the description view.
 */
- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"just finished editing");
    [self.item removeFromSuperview];
    [self.itemInfo removeFromSuperview];
}

/**
 *  Automatically focuses on the text field when the user starts editing it.
 */
- (void)textFieldDidChange:(id) sender {
    [self.scrollView setContentOffset:(pointFromRectangle(self.currentlyBeingEdited.frame)) animated:YES];
    
//    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
//    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:self.currentlyBeingEdited.text];
    
//    if(![numericSet isSupersetOfSet: stringSet]) {
    
    [KLCPopup dismissAllPopups];
    
    [self checkIfNumber];
    
    if(self.currentlyBeingEdited == self.gpsLatitude) {
        MKCoordinateRegion region;
        region.center.latitude = [self.gpsLatitude.text doubleValue];
        region.center.longitude = [self.gpsLongitude.text doubleValue];
        region.span.latitudeDelta = 0.01;
        region.span.longitudeDelta = 0.01;
        
        [self.gpsMapView setRegion:region animated:YES];
        
        // Annotation
//        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
//        point.coordinate = CLLocationCoordinate2DMake([self.gpsLatitude.text doubleValue], [self.gpsLongitude.text doubleValue]);
//        point.title = @"Image location";
//        point.subtitle = [[NSString stringWithFormat:@"%f", [self.gpsLatitude.text doubleValue]] stringByAppendingString:[NSString stringWithFormat:@", %f", [self.gpsLongitude.text doubleValue]]];
//        
//        [self.gpsMapView addAnnotation:point];
    }
    else if(self.currentlyBeingEdited == self.gpsLongitude) {
        MKCoordinateRegion region;
        region.center.latitude = [self.gpsLatitude.text doubleValue];
        region.center.longitude = [self.gpsLongitude.text doubleValue];
        region.span.latitudeDelta = 0.01;
        region.span.longitudeDelta = 0.01;
        
        [self.gpsMapView setRegion:region animated:YES];
        
        // Annotation
//        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
//        point.coordinate = CLLocationCoordinate2DMake([self.gpsLatitude.text doubleValue], [self.gpsLongitude.text doubleValue]);
//        point.title = @"Image location";
//        point.subtitle = [[NSString stringWithFormat:@"%f", [self.gpsLatitude.text doubleValue]] stringByAppendingString:[NSString stringWithFormat:@", %f", [self.gpsLongitude.text doubleValue]]];
//        
//        [self.gpsMapView addAnnotation:point];
    }
}

/**
 *  Goes to the next available text field when the user clicks next
 */
-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [self.item removeFromSuperview];
    [self.itemInfo removeFromSuperview];
    
    if(textField == self.fileName) {
        [self.dateTimeOriginal becomeFirstResponder];
    }
    else if(textField == self.dateTimeOriginal) {
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
        [self.exifCompressedBitsPerPixel becomeFirstResponder];
    }
    else if(textField == self.exifCompressedBitsPerPixel) {
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
    else if(textField == self.exifLensSerialNumber) {
        [self.gpsVersion becomeFirstResponder];
    }
    else if(textField == self.gpsVersion) {
        [self.gpsLatitudeRef becomeFirstResponder];
    }
    else if(textField == self.gpsLatitudeRef) {
        [self.gpsLatitude becomeFirstResponder];
    }
    else if(textField == self.gpsLatitude) {
        [self.gpsLongitudeRef becomeFirstResponder];
    }
    else if(textField == self.gpsLongitudeRef) {
        [self.gpsLongitude becomeFirstResponder];
    }
    else if(textField == self.gpsLongitude) {
        [self.gpsAltitudeRef becomeFirstResponder];
    }
    else if(textField == self.gpsAltitudeRef) {
        [self.gpsAltitude becomeFirstResponder];
    }
    else if(textField == self.gpsAltitude) {
        [self.gpsTimeStamp becomeFirstResponder];
    }
    else if(textField == self.gpsTimeStamp) {
        [self.gpsSatellites becomeFirstResponder];
    }
    else if(textField == self.gpsSatellites) {
        [self.gpsStatus becomeFirstResponder];
    }
    else if(textField == self.gpsStatus) {
        [self.gpsMeasureMode becomeFirstResponder];
    }
    else if(textField == self.gpsMeasureMode) {
        [self.gpsDegreeOfPrecision becomeFirstResponder];
    }
    else if(textField == self.gpsDegreeOfPrecision) {
        [self.gpsSpeedRef becomeFirstResponder];
    }
    else if(textField == self.gpsSpeedRef) {
        [self.gpsSpeed becomeFirstResponder];
    }
    else if(textField == self.gpsSpeed) {
        [self.gpsTrackRef becomeFirstResponder];
    }
    else if(textField == self.gpsTrackRef) {
        [self.gpsTrack becomeFirstResponder];
    }
    else if(textField == self.gpsTrack) {
        [self.gpsImgDirectionRef becomeFirstResponder];
    }
    else if(textField == self.gpsImgDirectionRef) {
        [self.gpsImgDirection becomeFirstResponder];
    }
    else if(textField == self.gpsImgDirection) {
        [self.gpsMapDatum becomeFirstResponder];
    }
    else if(textField == self.gpsMapDatum) {
        [self.gpsDestLatRef becomeFirstResponder];
    }
    else if(textField == self.gpsDestLatRef) {
        [self.gpsDestLat becomeFirstResponder];
    }
    else if(textField == self.gpsDestLat) {
        [self.gpsDestLongRef becomeFirstResponder];
    }
    else if(textField == self.gpsDestLongRef) {
        [self.gpsDestLong becomeFirstResponder];
    }
    else if(textField == self.gpsDestLong) {
        [self.gpsDestBearingRef becomeFirstResponder];
    }
    else if(textField == self.gpsDestBearingRef) {
        [self.gpsDestBearing becomeFirstResponder];
    }
    else if(textField == self.gpsDestBearing) {
        [self.gpsDestDistanceRef becomeFirstResponder];
    }
    else if(textField == self.gpsDestDistanceRef) {
        [self.gpsDestDistance becomeFirstResponder];
    }
    else if(textField == self.gpsDestDistance) {
        [self.gpsProcessingMethod becomeFirstResponder];
    }
    else if(textField == self.gpsProcessingMethod) {
        [self.gpsAreaInformation becomeFirstResponder];
    }
    else if(textField == self.gpsAreaInformation) {
        [self.gpsDateStamp becomeFirstResponder];
    }
    else if(textField == self.gpsDateStamp) {
        [self.gpsDifferental becomeFirstResponder];
    }
    else {
        NSLog(@"other option");
    }
    return YES;
}

/**
 *  Converts md5 into an int in string format. Not used right now.
 */
- (NSString *)md5:(NSString *) input
{
    const char *cStr = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

/**
 *  Scrolls to the top of the app.
 */
- (void)scrollToTop: (id)sender {
    [self.scrollView setContentOffset:CGPointMake(0, 0 - self.scrollView.contentInset.top) animated:YES];
}

/**
 *  Shows the date picker when the user starts editing the date.
 */
- (void)selectDate: (id)sender {
    NSLog(@"now inside select date method");
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy:MM:dd"];
    self.dateTimeOriginal.text = [dateFormatter stringFromDate:self.datePicker.date];
}

/**
 *  Shows the time picker when the user starts editing the time.
 */
- (void)selectTime: (id)sender {
    NSLog(@"now inside select time method");
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    self.dateTimeOriginalTime.text = [dateFormatter stringFromDate:self.timePicker.date];
}

/**
 *  Called first when the app loads. Initializes all the views, buttons, labels, and
 *  text fields. Then loads a picture from the photo library.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    //    self.view.backgroundColor = [UIColor whiteColor];
    //    self.view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    [self populateDictionary];
    
    self.view.backgroundColor = UIColorFromRGB(0x99d0f6);
    
    // Dismisses keyboard when the main view is clicked
    UITapGestureRecognizer *tapOnView = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tapOnView];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, 4972)];
    
    [self.view addSubview:self.scrollView];
    
    // Width of scroll view
    CGFloat w = self.scrollView.bounds.size.width;
//    CGFloat h = self.scrollView.bounds.size.height;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self.screenW = screenRect.size.width;
    self.screenH = screenRect.size.height;
    NSLog(@"%f", w);
    
    // Take picture button
    UIButton *takePicture = [UIButton buttonWithType:UIButtonTypeCustom];
    takePicture.frame = CGRectMake(0, 0, w/5, w/5);
    UIImage *takePictureImage = [UIImage imageNamed:@"CameraIconC2.png"];
    [takePicture setImage:takePictureImage forState:UIControlStateNormal];
    [takePicture addTarget:self
                    action:@selector(takePicture)
          forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:takePicture];
    
    // New image button
    UIButton *chooseNewImage = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseNewImage.frame = CGRectMake(w/5, 0, w/5, w/5);
    UIImage *chooseNewImageImage = [UIImage imageNamed:@"PhotoIconC2.png"];
    [chooseNewImage setImage:chooseNewImageImage forState:UIControlStateNormal];
    [chooseNewImage addTarget:self
                       action:@selector(newImageButtonPressed:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:chooseNewImage];
    
    // Reset to actual
    UIButton *resetExif = [UIButton buttonWithType:UIButtonTypeCustom];
    resetExif.frame = CGRectMake(2*w/5, 0, w/5, w/5);
    UIImage *resetExifImage = [UIImage imageNamed:@"ResetIconC2.png"];
    [resetExif setImage:resetExifImage forState:UIControlStateNormal];
    [resetExif addTarget:self
                  action:@selector(resetExif:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:resetExif];
    
    // Delete all
    UIButton *eraseExif = [UIButton buttonWithType:UIButtonTypeCustom];
    eraseExif.frame = CGRectMake(3*w/5, 0, w/5, w/5);
    UIImage *eraseExifImage = [UIImage imageNamed:@"EraseIconC2.png"];
    [eraseExif setImage:eraseExifImage forState:UIControlStateNormal];
    [eraseExif addTarget:self
                  action:@selector(clearExif)
        forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:eraseExif];
    
    // Button for saving the modified image
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(4*w/5, 0, w/5, w/5);
    UIImage *saveButtonImage = [UIImage imageNamed:@"SaveIconC2.png"];
    [saveButton setImage:saveButtonImage forState:UIControlStateNormal];
    [saveButton addTarget:self
                 action:@selector(saveButtonPressed:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:saveButton];
    
    // Button for automatically scrolling to the top
    UIButton *scrollToTop = [UIButton buttonWithType:UIButtonTypeCustom];
    scrollToTop.frame = CGRectMake(20, self.screenH-150, w/5, w/5);
//    [scrollToTop.layer setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.5].CGColor];
    scrollToTop.alpha = 0.6;
    
    UIImage *scrollToTopImage = [UIImage imageNamed:@"UpIconC2.png"];
    [scrollToTop setImage:scrollToTopImage forState:UIControlStateNormal];
    [scrollToTop addTarget:self
                 action:@selector(scrollToTop:)
       forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scrollToTop];
    
    // Description view
    self.descriptionView = [[UIView alloc] initWithFrame:CGRectMake(10, 30, w-20, 120)];
    self.descriptionView.backgroundColor = [UIColor whiteColor];
    [self.descriptionView setAlpha:0.9];
//    [self.view addSubview:self.descriptionView];
    self.descriptionScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, w-20, 120)];
    [self.descriptionView addSubview:self.descriptionScrollView];
    self.popup = [KLCPopup popupWithContentView:self.descriptionView
                  showType:KLCPopupShowTypeSlideInFromTop dismissType:KLCPopupDismissTypeSlideOutToTop maskType:KLCPopupMaskTypeNone dismissOnBackgroundTouch:YES dismissOnContentTouch:NO];
    
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
    
    // File name label
    UILabel *fileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/5, 322, w/2-10, 20)];
    fileNameLabel.text = @"File name";
//    fileNameLabel.textAlignment = NSTextAlignmentRight;
    fileNameLabel.textColor = [UIColor blackColor];
    [fileNameLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:14]];
    [self.scrollView addSubview:fileNameLabel];
    
    // File name
    self.fileName = [[UITextField alloc] init];
//    self.fileName.backgroundColor = [UIColor whiteColor];
    self.fileName.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fileName.delegate = self;
    self.fileName.enabled = NO;
    self.fileName.frame = CGRectMake(w/2, 322, 3*w/10, 20);
    self.fileName.keyboardAppearance = UIKeyboardAppearanceDark;
    self.fileName.tag = 111;
    self.fileName.textColor = [UIColor blackColor];
    [self.fileName setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.fileName];
    
    // File extension label
    UILabel *fileExtensionLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/5, 366, w/2-10, 20)];
    fileExtensionLabel.text = @"File extension";
//    fileExtensionLabel.textAlignment = NSTextAlignmentRight;
    fileExtensionLabel.textColor = [UIColor blackColor];
    [fileExtensionLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:14]];
    [self.scrollView addSubview:fileExtensionLabel];
    
    // File extension
    self.fileExtension = [[UITextField alloc] init];
    self.fileExtension.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fileExtension.delegate = self;
    self.fileExtension.enabled = NO;
    self.fileExtension.frame = CGRectMake(w/2, 366, w/2, 20);
    self.fileExtension.keyboardAppearance = UIKeyboardAppearanceDark;
    self.fileExtension.textColor = [UIColor blackColor];
    [self.fileExtension setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.fileExtension];
    
    // Width and height label
    UILabel *widthAndHeightLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/5, 410, w/2-10, 20)];
    widthAndHeightLabel.text = @"Dimensions";
//    widthAndHeightLabel.textAlignment = NSTextAlignmentRight;
    widthAndHeightLabel.textColor = [UIColor blackColor];
    [widthAndHeightLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:14]];
    [self.scrollView addSubview:widthAndHeightLabel];
    
    // Width and height
    self.widthAndHeight = [[UITextField alloc] init];
    self.widthAndHeight.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.widthAndHeight.delegate = self;
    self.widthAndHeight.enabled = NO;
    self.widthAndHeight.frame = CGRectMake(w/2, 410, w/2, 20);
    self.widthAndHeight.keyboardAppearance = UIKeyboardAppearanceDark;
    self.widthAndHeight.textColor = [UIColor blackColor];
    [self.widthAndHeight setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.widthAndHeight];
    
    // File size label
    UILabel *fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/5, 454, w/2-10, 20)];
    fileSizeLabel.text = @"File size";
//    fileSizeLabel.textAlignment = NSTextAlignmentRight;
    fileSizeLabel.textColor = [UIColor blackColor];
    [fileSizeLabel setFont:[UIFont fontWithName:@"Avenir-Heavy" size:14]];
    [self.scrollView addSubview:fileSizeLabel];
    
    // File size
    self.fileSize = [[UITextField alloc] init];
    self.fileSize.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fileSize.delegate = self;
    self.fileSize.enabled = NO;
    self.fileSize.frame = CGRectMake(w/2, 454, w/2, 20);
    self.fileSize.keyboardAppearance = UIKeyboardAppearanceDark;
    self.fileSize.textColor = [UIColor blackColor];
    [self.fileSize setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.fileSize];
    
    // Table view to hold the data
    self.exifTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 508, w, 2860)];
    self.gpsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 3544, w, 2860)];
    [self.scrollView addSubview:self.exifTableView];
    [self.scrollView addSubview:self.gpsTableView];
    
    // Exif title banner
    UIView *exifTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 508, w, 44)];
    exifTitle.backgroundColor = UIColorFromRGB(0x1b81c8);
    [self.scrollView addSubview:exifTitle];
    
    // Exif title banner text
    UILabel *exifTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/2-20, 520, 40, 20)];
    exifTitleLabel.text = @"EXIF";
    exifTitleLabel.textColor = [UIColor whiteColor];
    [self.scrollView addSubview:exifTitleLabel];
    
    // Date label. created or modified?
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 564, 400, 20)];
    dateLabel.text = @"Date created";
    dateLabel.textColor = [UIColor grayColor];
    [dateLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:dateLabel];
    
//    UIView* gummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    
    // Date original
    self.dateTimeOriginal = [[UITextField alloc] init];
    self.dateTimeOriginal.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.dateTimeOriginal.delegate = self;
    self.dateTimeOriginal.frame = CGRectMake(w/2, 564, w/4, 20);
    self.dateTimeOriginal.keyboardAppearance = UIKeyboardAppearanceDark;
    self.dateTimeOriginal.tag = 0;
    self.dateTimeOriginal.textColor = [UIColor blackColor];
    [self.dateTimeOriginal setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.dateTimeOriginal];
    
    // Time original
    self.dateTimeOriginalTime = [[UITextField alloc] init];
    self.dateTimeOriginalTime.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.dateTimeOriginalTime.delegate = self;
    self.dateTimeOriginalTime.frame = CGRectMake(3*w/4, 564, w/4, 20);
    self.dateTimeOriginalTime.keyboardAppearance = UIKeyboardAppearanceDark;
    self.dateTimeOriginalTime.tag = 1;
    self.dateTimeOriginalTime.textColor = [UIColor blackColor];
    [self.dateTimeOriginalTime setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.dateTimeOriginalTime];
    
    // Date picker for the date field
    self.datePicker = [[UIDatePicker alloc] init];
    self.datePicker.datePickerMode = UIDatePickerModeDate;
    [self.datePicker addTarget:self action:@selector(selectDate:) forControlEvents:UIControlEventValueChanged];
    self.dateTimeOriginal.inputView = self.datePicker;
    
    // Time picker for the date field
    self.timePicker = [[UIDatePicker alloc] init];
    self.timePicker.datePickerMode = UIDatePickerModeTime;
    [self.timePicker addTarget:self action:@selector(selectTime:) forControlEvents:UIControlEventValueChanged];
    self.dateTimeOriginalTime.inputView = self.timePicker;
    
    // Date digitized. Initialized so we don't get NSException
    self.dateTimeDigitized = [[UITextField alloc] init];
    
    // Exif exposure time label
    UILabel *exifExposureTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 608, 400, 20)];
    exifExposureTimeLabel.text = @"Exposure time";
    exifExposureTimeLabel.textColor = [UIColor grayColor];
    [exifExposureTimeLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureTimeLabel];
    
    // Exif exposure time
    self.exifExposureTime = [[UITextField alloc] init];
    self.exifExposureTime.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifExposureTime.delegate = self;
    self.exifExposureTime.frame = CGRectMake(w/2, 608, w/2, 20);
    self.exifExposureTime.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureTime.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.exifExposureTime.tag = 2;
    self.exifExposureTime.textColor = [UIColor blackColor];
    [self.exifExposureTime setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureTime];
    
    // f-number label
    UILabel *exifFNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 652, 400, 20)];
    exifFNumberLabel.text = @"f-number";
    exifFNumberLabel.textColor = [UIColor grayColor];
    [exifFNumberLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFNumberLabel];
    
    // f-number symbol label
    UILabel *fNumberSymbolLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/2, 652, 20, 20)];
    fNumberSymbolLabel.text = @"ƒ/";
    fNumberSymbolLabel.textColor = [UIColor blackColor];
    [self.scrollView addSubview:fNumberSymbolLabel];
    
    // f-number
    self.exifFNumber = [[UITextField alloc] init];
    self.exifFNumber.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFNumber.delegate = self;
    self.exifFNumber.frame = CGRectMake(w/2+20, 652, w/2-20, 20);
    self.exifFNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFNumber.tag = 3;
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
    self.exifExposureProgram.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifExposureProgram.delegate = self;
    self.exifExposureProgram.frame = CGRectMake(w/2, 696, w/2, 20);
    self.exifExposureProgram.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureProgram.tag = 4;
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
    self.exifSpectralSensitivity.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSpectralSensitivity.delegate = self;
    self.exifSpectralSensitivity.frame = CGRectMake(w/2, 740, w/2, 20);
    self.exifSpectralSensitivity.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSpectralSensitivity.tag = 5;
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
    self.exifISOSpeedRatings.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifISOSpeedRatings.delegate = self;
    self.exifISOSpeedRatings.frame = CGRectMake(w/2, 784, w/2, 20);
    self.exifISOSpeedRatings.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifISOSpeedRatings.tag = 6;
    self.exifISOSpeedRatings.textColor = [UIColor blackColor];
    [self.exifISOSpeedRatings setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifISOSpeedRatings];
    
    // OECF label
    UILabel *exifOECF = [[UILabel alloc] initWithFrame:CGRectMake(10, 828, 400, 20)];
    exifOECF.text = @"OECF";
    exifOECF.textColor = [UIColor grayColor];
    [exifOECF setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifOECF];
    
    // OECF
    self.exifOECF = [[UITextField alloc] init];
    self.exifOECF.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifOECF.delegate = self;
    self.exifOECF.frame = CGRectMake(w/2, 828, w/2, 20);
    self.exifOECF.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifOECF.tag = 7;
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
    self.exifVersion.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifVersion.delegate = self;
//    self.exifVersion.enabled = NO;
    self.exifVersion.frame = CGRectMake(w/2, 872, w/2, 20);
    self.exifVersion.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifVersion.tag = 8;
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
    self.exifComponentsConfiguration.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifComponentsConfiguration.delegate = self;
    self.exifComponentsConfiguration.frame = CGRectMake(w/2, 916, w/2, 20);
    self.exifComponentsConfiguration.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifComponentsConfiguration.tag = 9;
    self.exifComponentsConfiguration.textColor = [UIColor blackColor];
    [self.exifComponentsConfiguration setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifComponentsConfiguration];
    
    // Compressed bits per pixel label
    UILabel *exifCompressedBitsPerPixel = [[UILabel alloc] initWithFrame:CGRectMake(10, 960, 400, 20)];
    exifCompressedBitsPerPixel.text = @"Compressed bits per pixel";
    exifCompressedBitsPerPixel.textColor = [UIColor grayColor];
    [exifCompressedBitsPerPixel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifCompressedBitsPerPixel];
    
    // Compressed bits per pixel
    self.exifCompressedBitsPerPixel = [[UITextField alloc] init];
    self.exifCompressedBitsPerPixel.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifCompressedBitsPerPixel.delegate = self;
    self.exifCompressedBitsPerPixel.frame = CGRectMake(w/2, 960, w/2, 20);
    self.exifCompressedBitsPerPixel.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCompressedBitsPerPixel.tag = 10;
    self.exifCompressedBitsPerPixel.textColor = [UIColor blackColor];
    [self.exifCompressedBitsPerPixel setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifCompressedBitsPerPixel];
    
    // Shutter speed value label
    UILabel *exifShutterSpeedValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1004, 400, 20)];
    exifShutterSpeedValue.text = @"Shutter speed value";
    exifShutterSpeedValue.textColor = [UIColor grayColor];
    [exifShutterSpeedValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifShutterSpeedValue];
    
    // Shutter speed value
    self.exifShutterSpeedValue = [[UITextField alloc] init];
    self.exifShutterSpeedValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifShutterSpeedValue.delegate = self;
    self.exifShutterSpeedValue.frame = CGRectMake(w/2, 1004, w/2, 20);
    self.exifShutterSpeedValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifShutterSpeedValue.tag = 11;
    self.exifShutterSpeedValue.textColor = [UIColor blackColor];
    [self.exifShutterSpeedValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifShutterSpeedValue];
    
    // Aperture value label
    UILabel *exifApertureValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1048, 400, 20)];
    exifApertureValue.text = @"Aperture value";
    exifApertureValue.textColor = [UIColor grayColor];
    [exifApertureValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifApertureValue];
    
    // Aperture value
    self.exifApertureValue = [[UITextField alloc] init];
    self.exifApertureValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifApertureValue.delegate = self;
    self.exifApertureValue.frame = CGRectMake(w/2, 1048, w/2, 20);
    self.exifApertureValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifApertureValue.tag = 12;
    self.exifApertureValue.textColor = [UIColor blackColor];
    [self.exifApertureValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifApertureValue];
    
    // Brightness value label
    UILabel *exifBrightnessValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1092, 400, 20)];
    exifBrightnessValue.text = @"Brightness value";
    exifBrightnessValue.textColor = [UIColor grayColor];
    [exifBrightnessValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifBrightnessValue];
    
    // Brightness value
    self.exifBrightnessValue = [[UITextField alloc] init];
    self.exifBrightnessValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifBrightnessValue.delegate = self;
    self.exifBrightnessValue.frame = CGRectMake(w/2, 1092, w/2, 20);
    self.exifBrightnessValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifBrightnessValue.tag = 13;
    self.exifBrightnessValue.textColor = [UIColor blackColor];
    [self.exifBrightnessValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifBrightnessValue];
    
    // Exposure bias value label
    UILabel *exifExposureBiasValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1136, 400, 20)];
    exifExposureBiasValue.text = @"Exposure bias value";
    exifExposureBiasValue.textColor = [UIColor grayColor];
    [exifExposureBiasValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifExposureBiasValue];
    
    // Exposure bias value
    self.exifExposureBiasValue = [[UITextField alloc] init];
    self.exifExposureBiasValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifExposureBiasValue.delegate = self;
    self.exifExposureBiasValue.frame = CGRectMake(w/2, 1136, w/2, 20);
    self.exifExposureBiasValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureBiasValue.tag = 14;
    self.exifExposureBiasValue.textColor = [UIColor blackColor];
    [self.exifExposureBiasValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifExposureBiasValue];
    
    // Max aperture value label
    UILabel *exifMaxApertureValue = [[UILabel alloc] initWithFrame:CGRectMake(10, 1180, 400, 20)];
    exifMaxApertureValue.text = @"Max aperture value";
    exifMaxApertureValue.textColor = [UIColor grayColor];
    [exifMaxApertureValue setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMaxApertureValue];
    
    // Max aperture value
    self.exifMaxApertureValue = [[UITextField alloc] init];
    self.exifMaxApertureValue.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifMaxApertureValue.delegate = self;
    self.exifMaxApertureValue.frame = CGRectMake(w/2, 1180, w/2, 20);
    self.exifMaxApertureValue.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMaxApertureValue.tag = 15;
    self.exifMaxApertureValue.textColor = [UIColor blackColor];
    [self.exifMaxApertureValue setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMaxApertureValue];
    
    // Subject distance label
    UILabel *exifSubjectDistance = [[UILabel alloc] initWithFrame:CGRectMake(10, 1224, 400, 20)];
    exifSubjectDistance.text = @"Subject distance";
    exifSubjectDistance.textColor = [UIColor grayColor];
    [exifSubjectDistance setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectDistance];
    
    // Subject distance
    self.exifSubjectDistance = [[UITextField alloc] init];
    self.exifSubjectDistance.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubjectDistance.delegate = self;
    self.exifSubjectDistance.frame = CGRectMake(w/2, 1224, w/2, 20);
    self.exifSubjectDistance.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectDistance.tag = 16;
    self.exifSubjectDistance.textColor = [UIColor blackColor];
    [self.exifSubjectDistance setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectDistance];
    
    // Metering mode label
    UILabel *exifMeteringMode = [[UILabel alloc] initWithFrame:CGRectMake(10, 1268, 400, 20)];
    exifMeteringMode.text = @"Metering mode";
    exifMeteringMode.textColor = [UIColor grayColor];
    [exifMeteringMode setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMeteringMode];
    
    // Metering mode
    self.exifMeteringMode = [[UITextField alloc] init];
    self.exifMeteringMode.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifMeteringMode.delegate = self;
    self.exifMeteringMode.frame = CGRectMake(w/2, 1268, w/2, 20);
    self.exifMeteringMode.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMeteringMode.tag = 17;
    self.exifMeteringMode.textColor = [UIColor blackColor];
    [self.exifMeteringMode setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMeteringMode];
    
    // Light source label
    UILabel *exifLightSource = [[UILabel alloc] initWithFrame:CGRectMake(10, 1312, 400, 20)];
    exifLightSource.text = @"Light source";
    exifLightSource.textColor = [UIColor grayColor];
    [exifLightSource setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifLightSource];
    
    // Light source
    self.exifLightSource = [[UITextField alloc] init];
    self.exifLightSource.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifLightSource.delegate = self;
    self.exifLightSource.frame = CGRectMake(w/2, 1312, w/2, 20);
    self.exifLightSource.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLightSource.tag = 18;
    self.exifLightSource.textColor = [UIColor blackColor];
    [self.exifLightSource setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLightSource];
    
    // Flash label
    UILabel *exifFlash = [[UILabel alloc] initWithFrame:CGRectMake(10, 1356, 400, 20)];
    exifFlash.text = @"Flash";
    exifFlash.textColor = [UIColor grayColor];
    [exifFlash setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFlash];
    
    // Flash
    self.exifFlash = [[UITextField alloc] init];
    self.exifFlash.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFlash.delegate = self;
    self.exifFlash.frame = CGRectMake(w/2, 1356, w/2, 20);
    self.exifFlash.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlash.tag = 19;
    self.exifFlash.textColor = [UIColor blackColor];
    [self.exifFlash setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFlash];
    
    // Focal length label
    UILabel *exifFocalLength = [[UILabel alloc] initWithFrame:CGRectMake(10, 1400, 400, 20)];
    exifFocalLength.text = @"Focal length";
    exifFocalLength.textColor = [UIColor grayColor];
    [exifFocalLength setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFocalLength];
    
    // Focal length
    self.exifFocalLength = [[UITextField alloc] init];
    self.exifFocalLength.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFocalLength.delegate = self;
    self.exifFocalLength.frame = CGRectMake(w/2, 1400, w/2, 20);
    self.exifFocalLength.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalLength.tag = 20;
    self.exifFocalLength.textColor = [UIColor blackColor];
    [self.exifFocalLength setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFocalLength];
    
    // Subject area label
    UILabel *exifSubjectArea = [[UILabel alloc] initWithFrame:CGRectMake(10, 1444, 400, 20)];
    exifSubjectArea.text = @"Subject area";
    exifSubjectArea.textColor = [UIColor grayColor];
    [exifSubjectArea setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubjectArea];
    
    // Subject area
    self.exifSubjectArea = [[UITextField alloc] init];
    self.exifSubjectArea.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubjectArea.delegate = self;
    self.exifSubjectArea.frame = CGRectMake(w/2, 1444, w/2, 20);
    self.exifSubjectArea.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectArea.tag = 21;
    self.exifSubjectArea.textColor = [UIColor blackColor];
    [self.exifSubjectArea setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubjectArea];
    
    // Maker note label
    UILabel *exifMakerNote = [[UILabel alloc] initWithFrame:CGRectMake(10, 1488, 400, 20)];
    exifMakerNote.text = @"Maker note";
    exifMakerNote.textColor = [UIColor grayColor];
    [exifMakerNote setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifMakerNote];
    
    // Maker note
    self.exifMakerNote = [[UITextField alloc] init];
    self.exifMakerNote.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifMakerNote.delegate = self;
    self.exifMakerNote.frame = CGRectMake(w/2, 1488, w/2, 20);
    self.exifMakerNote.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifMakerNote.tag = 22;
    self.exifMakerNote.textColor = [UIColor blackColor];
    [self.exifMakerNote setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifMakerNote];
    
    // User comment label
    UILabel *exifUserComment = [[UILabel alloc] initWithFrame:CGRectMake(10, 1532, 400, 20)];
    exifUserComment.text = @"User comment";
    exifUserComment.textColor = [UIColor grayColor];
    [exifUserComment setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifUserComment];
    
    // User comment
    self.exifUserComment = [[UITextField alloc] init];
    self.exifUserComment.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifUserComment.delegate = self;
    self.exifUserComment.frame = CGRectMake(w/2, 1532, w/2, 20);
    self.exifUserComment.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifUserComment.tag = 23;
    self.exifUserComment.textColor = [UIColor blackColor];
    [self.exifUserComment setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifUserComment];
    
    // Subsec time label
    UILabel *exifSubsecTime = [[UILabel alloc] initWithFrame:CGRectMake(10, 1576, 400, 20)];
    exifSubsecTime.text = @"Subsec Time";
    exifSubsecTime.textColor = [UIColor grayColor];
    [exifSubsecTime setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTime];
    
    // Subsec time
    self.exifSubsecTime = [[UITextField alloc] init];
    self.exifSubsecTime.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubsecTime.delegate = self;
    self.exifSubsecTime.frame = CGRectMake(w/2, 1576, w/2, 20);
    self.exifSubsecTime.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTime.tag = 24;
    self.exifSubsecTime.textColor = [UIColor blackColor];
    [self.exifSubsecTime setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTime];
    
    // Subsec time original label
    UILabel *exifSubsecTimeOrginal = [[UILabel alloc] initWithFrame:CGRectMake(10, 1620, 400, 20)];
    exifSubsecTimeOrginal.text = @"Subsec Time Original";
    exifSubsecTimeOrginal.textColor = [UIColor grayColor];
    [exifSubsecTimeOrginal setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTimeOrginal];
    
    // Subsec time original
    self.exifSubsecTimeOrginal = [[UITextField alloc] init];
    self.exifSubsecTimeOrginal.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubsecTimeOrginal.delegate = self;
    self.exifSubsecTimeOrginal.frame = CGRectMake(w/2, 1620, w/2, 20);
    self.exifSubsecTimeOrginal.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTimeOrginal.tag = 25;
    self.exifSubsecTimeOrginal.textColor = [UIColor blackColor];
    [self.exifSubsecTimeOrginal setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTimeOrginal];
    
    // Subsec time digitized label
    UILabel *exifSubsecTimeDigitized = [[UILabel alloc] initWithFrame:CGRectMake(10, 1664, 400, 20)];
    exifSubsecTimeDigitized.text = @"Subsec Time Digitized";
    exifSubsecTimeDigitized.textColor = [UIColor grayColor];
    [exifSubsecTimeDigitized setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifSubsecTimeDigitized];
    
    // Subsec time digitized
    self.exifSubsecTimeDigitized = [[UITextField alloc] init];
    self.exifSubsecTimeDigitized.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubsecTimeDigitized.delegate = self;
    self.exifSubsecTimeDigitized.frame = CGRectMake(w/2, 1664, w/2, 20);
    self.exifSubsecTimeDigitized.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubsecTimeDigitized.tag = 26;
    self.exifSubsecTimeDigitized.textColor = [UIColor blackColor];
    [self.exifSubsecTimeDigitized setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifSubsecTimeDigitized];
    
    // Flash pix version label
    UILabel *exifFlashPixVersion = [[UILabel alloc] initWithFrame:CGRectMake(10, 1708, 400, 20)];
    exifFlashPixVersion.text = @"FlashPix version";
    exifFlashPixVersion.textColor = [UIColor grayColor];
    [exifFlashPixVersion setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifFlashPixVersion];
    
    // Flash pix version
    self.exifFlashPixVersion = [[UITextField alloc] init];
    self.exifFlashPixVersion.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFlashPixVersion.delegate = self;
    self.exifFlashPixVersion.frame = CGRectMake(w/2, 1708, w/2, 20);
    self.exifFlashPixVersion.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlashPixVersion.tag = 27;
    self.exifFlashPixVersion.textColor = [UIColor blackColor];
    [self.exifFlashPixVersion setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifFlashPixVersion];
    
    // Color space label
    UILabel *exifColorSpace = [[UILabel alloc] initWithFrame:CGRectMake(10, 1752, 400, 20)];
    exifColorSpace.text = @"Color space";
    exifColorSpace.textColor = [UIColor grayColor];
    [exifColorSpace setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifColorSpace];
    
    // Color space
    self.exifColorSpace = [[UITextField alloc] init];
    self.exifColorSpace.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifColorSpace.delegate = self;
    self.exifColorSpace.frame = CGRectMake(w/2, 1752, w/2, 20);
    self.exifColorSpace.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifColorSpace.tag = 28;
    self.exifColorSpace.textColor = [UIColor blackColor];
    [self.exifColorSpace setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifColorSpace];
    
    // Pixel dimensions label
    UILabel *exifPixelDimensions = [[UILabel alloc] initWithFrame:CGRectMake(10, 1796, w/2, 20)];
    exifPixelDimensions.text = @"Pixel dimensions";
    exifPixelDimensions.textColor = [UIColor grayColor];
    [exifPixelDimensions setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:exifPixelDimensions];
    
    // Pixel X dimension
    self.exifPixelXDimension = [[UITextField alloc] init];
    self.exifPixelXDimension.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifPixelXDimension.delegate = self;
    self.exifPixelXDimension.frame = CGRectMake(w/2, 1796, w/4-15, 20);
    self.exifPixelXDimension.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifPixelXDimension.tag = 29;
    self.exifPixelXDimension.textColor = [UIColor blackColor];
    [self.exifPixelXDimension setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifPixelXDimension];
    
    // x label
    UILabel *xLabel = [[UILabel alloc] initWithFrame:CGRectMake(3*w/4-20, 1796, 400, 20)];
    xLabel.text = @"by";
    xLabel.textColor = [UIColor grayColor];
    [xLabel setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:xLabel];

    // Pixel Y dimension
    self.exifPixelYDimension = [[UITextField alloc] init];
    self.exifPixelYDimension.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifPixelYDimension.delegate = self;
    self.exifPixelYDimension.frame = CGRectMake(3*w/4+20, 1796, w/4-15, 20);
    self.exifPixelYDimension.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifPixelYDimension.tag = 30;
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
    self.exifRelatedSoundFile.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifRelatedSoundFile.delegate = self;
    self.exifRelatedSoundFile.frame = CGRectMake(w/2, 1840, w/2, 20);
    self.exifRelatedSoundFile.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifRelatedSoundFile.tag = 31;
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
    self.exifFlashEnergy.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFlashEnergy.delegate = self;
    self.exifFlashEnergy.frame = CGRectMake(w/2, 1884, w/2, 20);
    self.exifFlashEnergy.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFlashEnergy.tag = 32;
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
    self.exifSpatialFrequencyResponse.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSpatialFrequencyResponse.delegate = self;
    self.exifSpatialFrequencyResponse.frame = CGRectMake(w/2, 1928, w/2, 20);
    self.exifSpatialFrequencyResponse.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSpatialFrequencyResponse.tag = 33;
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
    self.exifFocalPlaneXResolution.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFocalPlaneXResolution.delegate = self;
    self.exifFocalPlaneXResolution.frame = CGRectMake(w/2, 1972, w/2, 20);
    self.exifFocalPlaneXResolution.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneXResolution.tag = 34;
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
    self.exifFocalPlaneYResolution.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFocalPlaneYResolution.delegate = self;
    self.exifFocalPlaneYResolution.frame = CGRectMake(w/2, 2016, w/2, 20);
    self.exifFocalPlaneYResolution.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneYResolution.tag = 35;
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
    self.exifFocalPlaneResolutionUnit.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFocalPlaneResolutionUnit.delegate = self;
    self.exifFocalPlaneResolutionUnit.frame = CGRectMake(w/2, 2060, w/2, 20);
    self.exifFocalPlaneResolutionUnit.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalPlaneResolutionUnit.tag = 36;
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
    self.exifSubjectLocation.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubjectLocation.delegate = self;
    self.exifSubjectLocation.frame = CGRectMake(w/2, 2104, w/2, 20);
    self.exifSubjectLocation.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectLocation.tag = 37;
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
    self.exifExposureIndex.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifExposureIndex.delegate = self;
    self.exifExposureIndex.frame = CGRectMake(w/2, 2148, w/2, 20);
    self.exifExposureIndex.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureIndex.tag = 38;
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
    self.exifSensingMethod.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSensingMethod.delegate = self;
    self.exifSensingMethod.frame = CGRectMake(w/2, 2192, w/2, 20);
    self.exifSensingMethod.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSensingMethod.tag = 39;
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
    self.exifFileSource.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFileSource.delegate = self;
    self.exifFileSource.frame = CGRectMake(w/2, 2236, w/2, 20);
    self.exifFileSource.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFileSource.tag = 40;
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
    self.exifSceneType.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSceneType.delegate = self;
    self.exifSceneType.frame = CGRectMake(w/2, 2280, w/2, 20);
    self.exifSceneType.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSceneType.tag = 41;
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
    self.exifCFAPattern.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifCFAPattern.delegate = self;
    self.exifCFAPattern.frame = CGRectMake(w/2, 2324, w/2, 20);
    self.exifCFAPattern.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCFAPattern.tag = 42;
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
    self.exifCustomRendered.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifCustomRendered.delegate = self;
    self.exifCustomRendered.frame = CGRectMake(w/2, 2368, w/2, 20);
    self.exifCustomRendered.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCustomRendered.tag = 43;
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
    self.exifExposureMode.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifExposureMode.delegate = self;
    self.exifExposureMode.frame = CGRectMake(w/2, 2412, w/2, 20);
    self.exifExposureMode.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifExposureMode.tag = 44;
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
    self.exifWhiteBalance.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifWhiteBalance.delegate = self;
    self.exifWhiteBalance.frame = CGRectMake(w/2, 2456, w/2, 20);
    self.exifWhiteBalance.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifWhiteBalance.tag = 45;
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
    self.exifDigitalZoomRatio.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifDigitalZoomRatio.delegate = self;
    self.exifDigitalZoomRatio.frame = CGRectMake(w/2, 2500, w/2, 20);
    self.exifDigitalZoomRatio.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifDigitalZoomRatio.tag = 46;
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
    self.exifFocalLenIn35mmFilm.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifFocalLenIn35mmFilm.delegate = self;
    self.exifFocalLenIn35mmFilm.frame = CGRectMake(w/2, 2544, w/2, 20);
    self.exifFocalLenIn35mmFilm.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifFocalLenIn35mmFilm.tag = 47;
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
    self.exifSceneCaptureType.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSceneCaptureType.delegate = self;
    self.exifSceneCaptureType.frame = CGRectMake(w/2, 2588, w/2, 20);
    self.exifSceneCaptureType.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSceneCaptureType.tag = 48;
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
    self.exifGainControl.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifGainControl.delegate = self;
    self.exifGainControl.frame = CGRectMake(w/2, 2632, w/2, 20);
    self.exifGainControl.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifGainControl.tag = 49;
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
    self.exifContrast.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifContrast.delegate = self;
    self.exifContrast.frame = CGRectMake(w/2, 2676, w/2, 20);
    self.exifContrast.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifContrast.tag = 50;
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
    self.exifSaturation.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSaturation.delegate = self;
    self.exifSaturation.frame = CGRectMake(w/2, 2720, w/2, 20);
    self.exifSaturation.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSaturation.tag = 51;
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
    self.exifSharpness.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSharpness.delegate = self;
    self.exifSharpness.frame = CGRectMake(w/2, 2764, w/2, 20);
    self.exifSharpness.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSharpness.tag = 52;
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
    self.exifDeviceSettingDescription.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifDeviceSettingDescription.delegate = self;
    self.exifDeviceSettingDescription.frame = CGRectMake(w/2, 2808, w/2, 20);
    self.exifDeviceSettingDescription.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifDeviceSettingDescription.tag = 53;
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
    self.exifSubjectDistRange.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifSubjectDistRange.delegate = self;
    self.exifSubjectDistRange.frame = CGRectMake(w/2, 2852, w/2, 20);
    self.exifSubjectDistRange.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifSubjectDistRange.tag = 54;
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
    self.exifImageUniqueID.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifImageUniqueID.delegate = self;
    self.exifImageUniqueID.frame = CGRectMake(w/2, 2896, w/2, 20);
    self.exifImageUniqueID.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifImageUniqueID.tag = 55;
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
    self.exifGamma.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifGamma.delegate = self;
    self.exifGamma.frame = CGRectMake(w/2, 2940, w/2, 20);
    self.exifGamma.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifGamma.tag = 56;
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
    self.exifCameraOwnerName.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifCameraOwnerName.delegate = self;
    self.exifCameraOwnerName.frame = CGRectMake(w/2, 2984, w/2, 20);
    self.exifCameraOwnerName.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifCameraOwnerName.tag = 57;
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
    self.exifBodySerialNumber.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifBodySerialNumber.delegate = self;
    self.exifBodySerialNumber.frame = CGRectMake(w/2, 3028, w/2, 20);
    self.exifBodySerialNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifBodySerialNumber.tag = 58;
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
    self.exifLensSpecification.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifLensSpecification.delegate = self;
    self.exifLensSpecification.frame = CGRectMake(w/2, 3072, w/2, 20);
    self.exifLensSpecification.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensSpecification.tag = 59;
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
    self.exifLensMake.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifLensMake.delegate = self;
    self.exifLensMake.frame = CGRectMake(w/2, 3116, w/2, 20);
    self.exifLensMake.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensMake.tag = 60;
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
    self.exifLensModel.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifLensModel.delegate = self;
    self.exifLensModel.frame = CGRectMake(w/2, 3160, w/2, 20);
    self.exifLensModel.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensModel.tag = 61;
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
    self.exifLensSerialNumber.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.exifLensSerialNumber.delegate = self;
    self.exifLensSerialNumber.frame = CGRectMake(w/2, 3204, w/2, 20);
    self.exifLensSerialNumber.keyboardAppearance = UIKeyboardAppearanceDark;
    self.exifLensSerialNumber.tag = 62;
    self.exifLensSerialNumber.textColor = [UIColor blackColor];
    [self.exifLensSerialNumber setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.exifLensSerialNumber];
    
    // GPS title banner
    UIView *gpsTitle = [[UIView alloc] initWithFrame:CGRectMake(0, 3236, w, 44)];
    gpsTitle.backgroundColor = UIColorFromRGB(0x1b81c8);
    [self.scrollView addSubview:gpsTitle];
    
    // GPS banner text
    UILabel *gpsTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(w/2-20, 3248, 40, 20)];
    gpsTitleLabel.text = @"GPS";
    gpsTitleLabel.textColor = [UIColor whiteColor];
    [self.scrollView addSubview:gpsTitleLabel];
    
    // Apple maps
    self.gpsMapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 3280, self.screenW, 220)];
    self.gpsMapView.delegate = self;
//    self.gpsMapView.showsUserLocation = YES;
    [self.scrollView addSubview:self.gpsMapView];
    
    //User Heading Button states images
    UIImage *buttonImage = [UIImage imageNamed:@"greyButtonHighlight.png"];
    UIImage *buttonImageHighlight = [UIImage imageNamed:@"greyButton.png"];
    UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
    
    //Configure the button
    self.userHeadingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.userHeadingBtn addTarget:self action:@selector(startShowingUserHeading:) forControlEvents:UIControlEventTouchUpInside];
    //Add state images
    [self.userHeadingBtn setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.userHeadingBtn setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [self.userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    
    //Button shadow
    self.userHeadingBtn.frame = CGRectMake(0,0,39,30);
    self.userHeadingBtn.layer.cornerRadius = 8.0f;
    self.userHeadingBtn.layer.masksToBounds = NO;
    self.userHeadingBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.userHeadingBtn.layer.shadowOpacity = 0.8;
    self.userHeadingBtn.layer.shadowRadius = 1;
    self.userHeadingBtn.layer.shadowOffset = CGSizeMake(0, 1.0f);
    
    [self.gpsMapView addSubview:self.userHeadingBtn];
    
    // Reset location button
    UIImage *resetButtonArrow = [UIImage imageNamed:@"ResetGrey.png"];
    self.resetLocationBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.resetLocationBtn addTarget:self action:@selector(resetMapLocation:) forControlEvents:UIControlEventTouchUpInside];
    [self.resetLocationBtn setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self.resetLocationBtn setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [self.resetLocationBtn setImage:resetButtonArrow forState:UIControlStateNormal];
    self.resetLocationBtn.frame = CGRectMake(39,0,39,30);
    self.resetLocationBtn.layer.cornerRadius = 8.0f;
    self.resetLocationBtn.layer.masksToBounds = NO;
    self.resetLocationBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    self.resetLocationBtn.layer.shadowOpacity = 0.8;
    self.resetLocationBtn.layer.shadowRadius = 1;
    self.resetLocationBtn.layer.shadowOffset = CGSizeMake(0, 1.0f);
    
    [self.gpsMapView addSubview:self.resetLocationBtn];
    
    // Location search bar
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 3500, w, 44)];
    self.searchBar.delegate = self;
    self.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    [self.scrollView addSubview: self.searchBar];

    // GPS version label
    UILabel *gpsVersion = [[UILabel alloc] initWithFrame:CGRectMake(10, 3556, 400, 20)];
    gpsVersion.text = @"GPS version";
    gpsVersion.textColor = [UIColor grayColor];
    [gpsVersion setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsVersion];
    
    // GPS version
    self.gpsVersion = [[UITextField alloc] init];
    self.gpsVersion.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsVersion.delegate = self;
    self.gpsVersion.frame = CGRectMake(w/2, 3556, w/2, 20);
    self.gpsVersion.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsVersion.tag = 71;
    self.gpsVersion.textColor = [UIColor blackColor];
    [self.gpsVersion setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsVersion];
    
    // Latitude ref label
    UILabel *gpsLatitudeRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 3600, 400, 20)];
    gpsLatitudeRef.text = @"Latitude ref";
    gpsLatitudeRef.textColor = [UIColor grayColor];
    [gpsLatitudeRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsLatitudeRef];
    
    // Latitude ref
    self.gpsLatitudeRef = [[UITextField alloc] init];
    self.gpsLatitudeRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsLatitudeRef.delegate = self;
    self.gpsLatitudeRef.enabled = NO;
    self.gpsLatitudeRef.frame = CGRectMake(w/2, 3600, w/2, 20);
    self.gpsLatitudeRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsLatitudeRef.tag = 72;
    self.gpsLatitudeRef.textColor = [UIColor blackColor];
    [self.gpsLatitudeRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsLatitudeRef];
    
    // Latitude label
    UILabel *gpsLatitude = [[UILabel alloc] initWithFrame:CGRectMake(10, 3644, 400, 20)];
    gpsLatitude.text = @"Latitude";
    gpsLatitude.textColor = [UIColor grayColor];
    [gpsLatitude setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsLatitude];
    
    // Latitude
    self.gpsLatitude = [[UITextField alloc] init];
    self.gpsLatitude.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsLatitude.delegate = self;
    self.gpsLatitude.enabled = NO;
    self.gpsLatitude.frame = CGRectMake(w/2, 3644, w/2, 20);
    self.gpsLatitude.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsLatitude.tag = 73;
    self.gpsLatitude.textColor = [UIColor blackColor];
    [self.gpsLatitude setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsLatitude];
    
    // Latitude ref label
    UILabel *gpsLongitudeRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 3688, 400, 20)];
    gpsLongitudeRef.text = @"Longitude ref";
    gpsLongitudeRef.textColor = [UIColor grayColor];
    [gpsLongitudeRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsLongitudeRef];
    
    // Latitude ref
    self.gpsLongitudeRef = [[UITextField alloc] init];
    self.gpsLongitudeRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsLongitudeRef.delegate = self;
    self.gpsLongitudeRef.enabled = NO;
    self.gpsLongitudeRef.frame = CGRectMake(w/2, 3688, w/2, 20);
    self.gpsLongitudeRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsLongitudeRef.tag = 74;
    self.gpsLongitudeRef.textColor = [UIColor blackColor];
    [self.gpsLongitudeRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsLongitudeRef];
    
    // Latitude label
    UILabel *gpsLongitude = [[UILabel alloc] initWithFrame:CGRectMake(10, 3732, 400, 20)];
    gpsLongitude.text = @"Longitude";
    gpsLongitude.textColor = [UIColor grayColor];
    [gpsLongitude setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsLongitude];
    
    // Latitude
    self.gpsLongitude = [[UITextField alloc] init];
    self.gpsLongitude.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsLongitude.delegate = self;
    self.gpsLongitude.enabled = NO;
    self.gpsLongitude.frame = CGRectMake(w/2, 3732, w/2, 20);
    self.gpsLongitude.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsLongitude.tag = 75;
    self.gpsLongitude.textColor = [UIColor blackColor];
    [self.gpsLongitude setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsLongitude];
    
    // Altitude ref label
    UILabel *gpsAltitudeRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 3776, 400, 20)];
    gpsAltitudeRef.text = @"Altitude ref";
    gpsAltitudeRef.textColor = [UIColor grayColor];
    [gpsAltitudeRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsAltitudeRef];
    
    // Altitude ref
    self.gpsAltitudeRef = [[UITextField alloc] init];
    self.gpsAltitudeRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsAltitudeRef.delegate = self;
    self.gpsAltitudeRef.frame = CGRectMake(w/2, 3776, w/2, 20);
    self.gpsAltitudeRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsAltitudeRef.tag = 76;
    self.gpsAltitudeRef.textColor = [UIColor blackColor];
    [self.gpsAltitudeRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsAltitudeRef];
    
    // Altitude label
    UILabel *gpsAltitude = [[UILabel alloc] initWithFrame:CGRectMake(10, 3820, 400, 20)];
    gpsAltitude.text = @"Altitude";
    gpsAltitude.textColor = [UIColor grayColor];
    [gpsAltitude setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsAltitude];
    
    // Altitude
    self.gpsAltitude = [[UITextField alloc] init];
    self.gpsAltitude.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsAltitude.delegate = self;
    self.gpsAltitude.frame = CGRectMake(w/2, 3820, w/2, 20);
    self.gpsAltitude.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsAltitude.tag = 77;
    self.gpsAltitude.textColor = [UIColor blackColor];
    [self.gpsAltitude setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsAltitude];
    
    // Time stamp label
    UILabel *gpsTimeStamp = [[UILabel alloc] initWithFrame:CGRectMake(10, 3864, 400, 20)];
    gpsTimeStamp.text = @"Time stamp";
    gpsTimeStamp.textColor = [UIColor grayColor];
    [gpsTimeStamp setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsTimeStamp];
    
    // Time stamp
    self.gpsTimeStamp = [[UITextField alloc] init];
    self.gpsTimeStamp.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsTimeStamp.delegate = self;
    self.gpsTimeStamp.frame = CGRectMake(w/2, 3864, w/2, 20);
    self.gpsTimeStamp.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsTimeStamp.tag = 78;
    self.gpsTimeStamp.textColor = [UIColor blackColor];
    [self.gpsTimeStamp setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsTimeStamp];
    
    // Satellites label
    UILabel *gpsSatellites = [[UILabel alloc] initWithFrame:CGRectMake(10, 3908, 400, 20)];
    gpsSatellites.text = @"Satellites";
    gpsSatellites.textColor = [UIColor grayColor];
    [gpsSatellites setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsSatellites];
    
    // Satellites
    self.gpsSatellites = [[UITextField alloc] init];
    self.gpsSatellites.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsSatellites.delegate = self;
    self.gpsSatellites.frame = CGRectMake(w/2, 3908, w/2, 20);
    self.gpsSatellites.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsSatellites.tag = 79;
    self.gpsSatellites.textColor = [UIColor blackColor];
    [self.gpsSatellites setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsSatellites];
    
    // Status label
    UILabel *gpsStatus = [[UILabel alloc] initWithFrame:CGRectMake(10, 3952, 400, 20)];
    gpsStatus.text = @"Status";
    gpsStatus.textColor = [UIColor grayColor];
    [gpsStatus setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsStatus];
    
    // Status
    self.gpsStatus = [[UITextField alloc] init];
    self.gpsStatus.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsStatus.delegate = self;
    self.gpsStatus.frame = CGRectMake(w/2, 3952, w/2, 20);
    self.gpsStatus.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsStatus.tag = 80;
    self.gpsStatus.textColor = [UIColor blackColor];
    [self.gpsStatus setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsStatus];
    
    // Measure mode label
    UILabel *gpsMeasureMode = [[UILabel alloc] initWithFrame:CGRectMake(10, 3996, 400, 20)];
    gpsMeasureMode.text = @"Measure mode";
    gpsMeasureMode.textColor = [UIColor grayColor];
    [gpsMeasureMode setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsMeasureMode];
    
    // Measure mode
    self.gpsMeasureMode = [[UITextField alloc] init];
    self.gpsMeasureMode.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsMeasureMode.delegate = self;
    self.gpsMeasureMode.frame = CGRectMake(w/2, 3996, w/2, 20);
    self.gpsMeasureMode.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsMeasureMode.tag = 81;
    self.gpsMeasureMode.textColor = [UIColor blackColor];
    [self.gpsMeasureMode setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsMeasureMode];
    
    // DOP label
    UILabel *gpsDegreeOfPrecision = [[UILabel alloc] initWithFrame:CGRectMake(10, 4040, 400, 20)];
    gpsDegreeOfPrecision.text = @"Degree of precision (DOP)";
    gpsDegreeOfPrecision.textColor = [UIColor grayColor];
    [gpsDegreeOfPrecision setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDegreeOfPrecision];
    
    // DOP
    self.gpsDegreeOfPrecision = [[UITextField alloc] init];
    self.gpsDegreeOfPrecision.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDegreeOfPrecision.delegate = self;
    self.gpsDegreeOfPrecision.frame = CGRectMake(w/2, 4040, w/2, 20);
    self.gpsDegreeOfPrecision.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDegreeOfPrecision.tag = 82;
    self.gpsDegreeOfPrecision.textColor = [UIColor blackColor];
    [self.gpsDegreeOfPrecision setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDegreeOfPrecision];
    
    // Speed ref label
    UILabel *gpsSpeedRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4084, 400, 20)];
    gpsSpeedRef.text = @"Speed ref";
    gpsSpeedRef.textColor = [UIColor grayColor];
    [gpsSpeedRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsSpeedRef];
    
    // Speed ref
    self.gpsSpeedRef = [[UITextField alloc] init];
    self.gpsSpeedRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsSpeedRef.delegate = self;
    self.gpsSpeedRef.frame = CGRectMake(w/2, 4084, w/2, 20);
    self.gpsSpeedRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsSpeedRef.tag = 83;
    self.gpsSpeedRef.textColor = [UIColor blackColor];
    [self.gpsSpeedRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsSpeedRef];
    
    // Speed label
    UILabel *gpsSpeed = [[UILabel alloc] initWithFrame:CGRectMake(10, 4128, 400, 20)];
    gpsSpeed.text = @"Speed";
    gpsSpeed.textColor = [UIColor grayColor];
    [gpsSpeed setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsSpeed];
    
    // Speed
    self.gpsSpeed = [[UITextField alloc] init];
    self.gpsSpeed.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsSpeed.delegate = self;
    self.gpsSpeed.frame = CGRectMake(w/2, 4128, w/2, 20);
    self.gpsSpeed.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsSpeed.tag = 84;
    self.gpsSpeed.textColor = [UIColor blackColor];
    [self.gpsSpeed setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsSpeed];
    
    // Track ref label
    UILabel *gpsTrackRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4172, 400, 20)];
    gpsTrackRef.text = @"Track ref";
    gpsTrackRef.textColor = [UIColor grayColor];
    [gpsTrackRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsTrackRef];
    
    // Track ref
    self.gpsTrackRef = [[UITextField alloc] init];
    self.gpsTrackRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsTrackRef.delegate = self;
    self.gpsTrackRef.frame = CGRectMake(w/2, 4172, w/2, 20);
    self.gpsTrackRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsTrackRef.tag = 85;
    self.gpsTrackRef.textColor = [UIColor blackColor];
    [self.gpsTrackRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsTrackRef];
    
    // Track label
    UILabel *gpsTrack = [[UILabel alloc] initWithFrame:CGRectMake(10, 4216, 400, 20)];
    gpsTrack.text = @"Track";
    gpsTrack.textColor = [UIColor grayColor];
    [gpsTrack setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsTrack];
    
    // Track
    self.gpsTrack = [[UITextField alloc] init];
    self.gpsTrack.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsTrack.delegate = self;
    self.gpsTrack.frame = CGRectMake(w/2, 4216, w/2, 20);
    self.gpsTrack.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsTrack.tag = 86;
    self.gpsTrack.textColor = [UIColor blackColor];
    [self.gpsTrack setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsTrack];
    
    // Image direction ref label
    UILabel *gpsImgDirectionRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4260, 400, 20)];
    gpsImgDirectionRef.text = @"Image direction ref";
    gpsImgDirectionRef.textColor = [UIColor grayColor];
    [gpsImgDirectionRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsImgDirectionRef];
    
    // Image direction ref
    self.gpsImgDirectionRef = [[UITextField alloc] init];
    self.gpsImgDirectionRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsImgDirectionRef.delegate = self;
    self.gpsImgDirectionRef.frame = CGRectMake(w/2, 4260, w/2, 20);
    self.gpsImgDirectionRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsImgDirectionRef.tag = 87;
    self.gpsImgDirectionRef.textColor = [UIColor blackColor];
    [self.gpsImgDirectionRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsImgDirectionRef];
    
    // Image direction label
    UILabel *gpsImgDirection = [[UILabel alloc] initWithFrame:CGRectMake(10, 4304, 400, 20)];
    gpsImgDirection.text = @"Image direction";
    gpsImgDirection.textColor = [UIColor grayColor];
    [gpsImgDirection setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsImgDirection];
    
    // Image direction
    self.gpsImgDirection = [[UITextField alloc] init];
    self.gpsImgDirection.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsImgDirection.delegate = self;
    self.gpsImgDirection.frame = CGRectMake(w/2, 4304, w/2, 20);
    self.gpsImgDirection.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsImgDirection.tag = 88;
    self.gpsImgDirection.textColor = [UIColor blackColor];
    [self.gpsImgDirection setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsImgDirection];
    
    // Map datum label
    UILabel *gpsMapDatum = [[UILabel alloc] initWithFrame:CGRectMake(10, 4348, 400, 20)];
    gpsMapDatum.text = @"Map datum";
    gpsMapDatum.textColor = [UIColor grayColor];
    [gpsMapDatum setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsMapDatum];
    
    // Map datum
    self.gpsMapDatum = [[UITextField alloc] init];
    self.gpsMapDatum.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsMapDatum.delegate = self;
    self.gpsMapDatum.frame = CGRectMake(w/2, 4348, w/2, 20);
    self.gpsMapDatum.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsMapDatum.tag = 89;
    self.gpsMapDatum.textColor = [UIColor blackColor];
    [self.gpsMapDatum setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsMapDatum];
    
    // Destination latitude ref label
    UILabel *gpsDestLatRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4392, 400, 20)];
    gpsDestLatRef.text = @"Destination latitude ref";
    gpsDestLatRef.textColor = [UIColor grayColor];
    [gpsDestLatRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestLatRef];
    
    // Destination latitude ref
    self.gpsDestLatRef = [[UITextField alloc] init];
    self.gpsDestLatRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestLatRef.delegate = self;
    self.gpsDestLatRef.frame = CGRectMake(w/2, 4392, w/2, 20);
    self.gpsDestLatRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestLatRef.tag = 90;
    self.gpsDestLatRef.textColor = [UIColor blackColor];
    [self.gpsDestLatRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestLatRef];
    
    // Destination latitude label
    UILabel *gpsDestLat = [[UILabel alloc] initWithFrame:CGRectMake(10, 4436, 400, 20)];
    gpsDestLat.text = @"Destination latitude";
    gpsDestLat.textColor = [UIColor grayColor];
    [gpsDestLat setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestLat];
    
    // Destination latitude
    self.gpsDestLat = [[UITextField alloc] init];
    self.gpsDestLat.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestLat.delegate = self;
    self.gpsDestLat.frame = CGRectMake(w/2, 4436, w/2, 20);
    self.gpsDestLat.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestLat.tag = 91;
    self.gpsDestLat.textColor = [UIColor blackColor];
    [self.gpsDestLat setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestLat];
    
    // Destination longitude ref label
    UILabel *gpsDestLongRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4480, 400, 20)];
    gpsDestLongRef.text = @"Destination longitude ref";
    gpsDestLongRef.textColor = [UIColor grayColor];
    [gpsDestLongRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestLongRef];
    
    // Destination longitude ref
    self.gpsDestLongRef = [[UITextField alloc] init];
    self.gpsDestLongRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestLongRef.delegate = self;
    self.gpsDestLongRef.frame = CGRectMake(w/2, 4480, w/2, 20);
    self.gpsDestLongRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestLongRef.tag = 92;
    self.gpsDestLongRef.textColor = [UIColor blackColor];
    [self.gpsDestLongRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestLongRef];
    
    // Destination longitude label
    UILabel *gpsDestLong = [[UILabel alloc] initWithFrame:CGRectMake(10, 4524, 400, 20)];
    gpsDestLong.text = @"Destination longitude";
    gpsDestLong.textColor = [UIColor grayColor];
    [gpsDestLong setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestLong];
    
    // Destination longitude
    self.gpsDestLong = [[UITextField alloc] init];
    self.gpsDestLong.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestLong.delegate = self;
    self.gpsDestLong.frame = CGRectMake(w/2, 4524, w/2, 20);
    self.gpsDestLong.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestLong.tag = 93;
    self.gpsDestLong.textColor = [UIColor blackColor];
    [self.gpsDestLong setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestLong];
    
    // Destination bearing ref label
    UILabel *gpsDestBearingRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4568, 400, 20)];
    gpsDestBearingRef.text = @"Destination bearing ref";
    gpsDestBearingRef.textColor = [UIColor grayColor];
    [gpsDestBearingRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestBearingRef];
    
    // Destination bearing ref
    self.gpsDestBearingRef = [[UITextField alloc] init];
    self.gpsDestBearingRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestBearingRef.delegate = self;
    self.gpsDestBearingRef.frame = CGRectMake(w/2, 4568, w/2, 20);
    self.gpsDestBearingRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestBearingRef.tag = 94;
    self.gpsDestBearingRef.textColor = [UIColor blackColor];
    [self.gpsDestBearingRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestBearingRef];
    
    // Destination bearing label
    UILabel *gpsDestBearing = [[UILabel alloc] initWithFrame:CGRectMake(10, 4612, 400, 20)];
    gpsDestBearing.text = @"Destination bearing";
    gpsDestBearing.textColor = [UIColor grayColor];
    [gpsDestBearing setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestBearing];
    
    // Destination bearing
    self.gpsDestBearing = [[UITextField alloc] init];
    self.gpsDestBearing.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestBearing.delegate = self;
    self.gpsDestBearing.frame = CGRectMake(w/2, 4612, w/2, 20);
    self.gpsDestBearing.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestBearing.tag = 95;
    self.gpsDestBearing.textColor = [UIColor blackColor];
    [self.gpsDestBearing setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestBearing];
    
    // Destination distance ref label
    UILabel *gpsDestDistanceRef = [[UILabel alloc] initWithFrame:CGRectMake(10, 4656, 400, 20)];
    gpsDestDistanceRef.text = @"Destination distance ref";
    gpsDestDistanceRef.textColor = [UIColor grayColor];
    [gpsDestDistanceRef setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestDistanceRef];
    
    // Destination distance ref
    self.gpsDestDistanceRef = [[UITextField alloc] init];
    self.gpsDestDistanceRef.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestDistanceRef.delegate = self;
    self.gpsDestDistanceRef.frame = CGRectMake(w/2, 4656, w/2, 20);
    self.gpsDestDistanceRef.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestDistanceRef.tag = 96;
    self.gpsDestDistanceRef.textColor = [UIColor blackColor];
    [self.gpsDestDistanceRef setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestDistanceRef];
    
    // Destination distance label
    UILabel *gpsDestDistance = [[UILabel alloc] initWithFrame:CGRectMake(10, 4700, 400, 20)];
    gpsDestDistance.text = @"Destination distance";
    gpsDestDistance.textColor = [UIColor grayColor];
    [gpsDestDistance setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDestDistance];
    
    // Destination distance
    self.gpsDestDistance = [[UITextField alloc] init];
    self.gpsDestDistance.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDestDistance.delegate = self;
    self.gpsDestDistance.frame = CGRectMake(w/2, 4700, w/2, 20);
    self.gpsDestDistance.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDestDistance.tag = 97;
    self.gpsDestDistance.textColor = [UIColor blackColor];
    [self.gpsDestDistance setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDestDistance];
    
    // Processing method label
    UILabel *gpsProcessingMethod = [[UILabel alloc] initWithFrame:CGRectMake(10, 4744, 400, 20)];
    gpsProcessingMethod.text = @"Processing method";
    gpsProcessingMethod.textColor = [UIColor grayColor];
    [gpsProcessingMethod setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsProcessingMethod];
    
    // Processing method
    self.gpsProcessingMethod = [[UITextField alloc] init];
    self.gpsProcessingMethod.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsProcessingMethod.delegate = self;
    self.gpsProcessingMethod.frame = CGRectMake(w/2, 4744, w/2, 20);
    self.gpsProcessingMethod.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsProcessingMethod.tag = 98;
    self.gpsProcessingMethod.textColor = [UIColor blackColor];
    [self.gpsProcessingMethod setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsProcessingMethod];
    
    // Area information label
    UILabel *gpsAreaInformation = [[UILabel alloc] initWithFrame:CGRectMake(10, 4788, 400, 20)];
    gpsAreaInformation.text = @"Area information";
    gpsAreaInformation.textColor = [UIColor grayColor];
    [gpsAreaInformation setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsAreaInformation];
    
    // Area information
    self.gpsAreaInformation = [[UITextField alloc] init];
    self.gpsAreaInformation.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsAreaInformation.delegate = self;
    self.gpsAreaInformation.frame = CGRectMake(w/2, 4788, w/2, 20);
    self.gpsAreaInformation.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsAreaInformation.tag = 99;
    self.gpsAreaInformation.textColor = [UIColor blackColor];
    [self.gpsAreaInformation setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsAreaInformation];
    
    // Date stamp label
    UILabel *gpsDateStamp = [[UILabel alloc] initWithFrame:CGRectMake(10, 4832, 400, 20)];
    gpsDateStamp.text = @"Date stamp";
    gpsDateStamp.textColor = [UIColor grayColor];
    [gpsDateStamp setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDateStamp];
    
    // Date stamp
    self.gpsDateStamp = [[UITextField alloc] init];
    self.gpsDateStamp.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDateStamp.delegate = self;
    self.gpsDateStamp.frame = CGRectMake(w/2, 4832, w/2, 20);
    self.gpsDateStamp.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDateStamp.tag = 100;
    self.gpsDateStamp.textColor = [UIColor blackColor];
    [self.gpsDateStamp setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDateStamp];
    
    // Differential label
    UILabel *gpsDifferental = [[UILabel alloc] initWithFrame:CGRectMake(10, 4876, 400, 20)];
    gpsDifferental.text = @"Differential applied?";
    gpsDifferental.textColor = [UIColor grayColor];
    [gpsDifferental setFont:[UIFont fontWithName:@"Avenir" size:14]];
    [self.scrollView addSubview:gpsDifferental];
    
    // Differential
    self.gpsDifferental = [[UITextField alloc] init];
    self.gpsDifferental.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.gpsDifferental.delegate = self;
    self.gpsDifferental.frame = CGRectMake(w/2, 4876, w/2, 20);
    self.gpsDifferental.keyboardAppearance = UIKeyboardAppearanceDark;
    self.gpsDifferental.tag = 101;
    self.gpsDifferental.textColor = [UIColor blackColor];
    [self.gpsDifferental setReturnKeyType:UIReturnKeyNext];
    [self.scrollView addSubview:self.gpsDifferental];
    
    // Location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    if(self.locationManager.locationServicesEnabled)
    {
        [self.locationManager startUpdatingLocation];
    }
    
    [self loadPicture];
}

/**
 *  Goes to the previous text field when the user presses previous. Currently not
 *  implemented.
 */
- (void)previousItemPressed {
    NSLog(@"Going to previous item");
}

/**
 *  Resets a single text field to the original value.
 */
- (void)resetPressed {
    NSLog(@"Resetting");
    
    NSString *s = [self.originalValues valueForKey:[self.tags valueForKey:[NSString stringWithFormat:@"%ld", self.currentTag]]];
    
    NSLog(@"%@",s);
    
    if(self.currentlyBeingEdited == self.fileName) {
        self.fileName.text = s;
    }
    else if(self.currentlyBeingEdited == self.dateTimeOriginal) {
        self.dateTimeOriginal.text = s;
    }
    else if(self.currentlyBeingEdited == self.dateTimeOriginalTime) {
        self.dateTimeOriginalTime.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifExposureTime) {
        self.exifExposureTime.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFNumber) {
        self.exifFNumber.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifExposureProgram) {
        self.exifExposureProgram.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSpectralSensitivity) {
        self.exifSpectralSensitivity.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifISOSpeedRatings) {
        self.exifISOSpeedRatings.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifOECF) {
        self.exifOECF.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifVersion) {
        self.exifVersion.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifComponentsConfiguration) {
        self.exifComponentsConfiguration.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifCompressedBitsPerPixel) {
        self.exifCompressedBitsPerPixel.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifShutterSpeedValue) {
        self.exifShutterSpeedValue.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifApertureValue) {
        self.exifApertureValue.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifBrightnessValue) {
        self.exifBrightnessValue.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifExposureBiasValue) {
        self.exifExposureBiasValue.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifMaxApertureValue) {
        self.exifMaxApertureValue.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubjectDistance) {
        self.exifSubjectDistance.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifMeteringMode) {
        self.exifMeteringMode.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifLightSource) {
        self.exifLightSource.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFlash) {
        self.exifFlash.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFocalLength) {
        self.exifFocalLength.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubjectArea) {
        self.exifSubjectArea.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifMakerNote) {
        self.exifMakerNote.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifUserComment) {
        self.exifUserComment.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubsecTime) {
        self.exifSubsecTime.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubsecTimeOrginal) {
        self.exifSubsecTimeOrginal.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubsecTimeDigitized) {
        self.exifSubsecTimeDigitized.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFlashPixVersion) {
        self.exifFlashPixVersion.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifColorSpace) {
        self.exifColorSpace.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifPixelXDimension) {
        self.exifPixelXDimension.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifPixelYDimension) {
        self.exifPixelYDimension.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifRelatedSoundFile) {
        self.exifRelatedSoundFile.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFlashEnergy) {
        self.exifFlashEnergy.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSpatialFrequencyResponse) {
        self.exifSpatialFrequencyResponse.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFocalPlaneXResolution) {
        self.exifFocalPlaneXResolution.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFocalPlaneYResolution) {
        self.exifFocalPlaneYResolution.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFocalPlaneResolutionUnit) {
        self.exifFocalPlaneResolutionUnit.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubjectLocation) {
        self.exifSubjectLocation.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifExposureIndex) {
        self.exifExposureIndex.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSensingMethod) {
        self.exifSensingMethod.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFileSource) {
        self.exifFileSource.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSceneType) {
        self.exifSceneType.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifCFAPattern) {
        self.exifCFAPattern.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifCustomRendered) {
        self.exifCustomRendered.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifExposureMode) {
        self.exifExposureMode.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifWhiteBalance) {
        self.exifWhiteBalance.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifDigitalZoomRatio) {
        self.exifDigitalZoomRatio.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifFocalLenIn35mmFilm) {
        self.exifFocalLenIn35mmFilm.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSceneCaptureType) {
        self.exifSceneCaptureType.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifGainControl) {
        self.exifGainControl.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifContrast) {
        self.exifContrast.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSaturation) {
        self.exifSaturation.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSharpness) {
        self.exifSharpness.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifDeviceSettingDescription) {
        self.exifDeviceSettingDescription.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifSubjectDistRange) {
        self.exifSubjectDistRange.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifImageUniqueID) {
        self.exifImageUniqueID.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifGamma) {
        self.exifGamma.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifCameraOwnerName) {
        self.exifCameraOwnerName.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifBodySerialNumber) {
        self.exifBodySerialNumber.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifLensSpecification) {
        self.exifLensSpecification.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifLensMake) {
        self.exifLensMake.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifLensModel) {
        self.exifLensModel.text = s;
    }
    else if(self.currentlyBeingEdited == self.exifLensSerialNumber) {
        self.exifLensSerialNumber.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsVersion) {
        self.gpsVersion.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsLatitudeRef) {
        self.gpsLatitudeRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsLatitude) {
        self.gpsLatitude.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsLongitudeRef) {
        self.gpsLongitudeRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsLongitude) {
        self.gpsLongitude.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsAltitudeRef) {
        self.gpsAltitudeRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsAltitude) {
        self.gpsAltitude.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsTimeStamp) {
        self.gpsTimeStamp.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsSatellites) {
        self.gpsSatellites.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsStatus) {
        self.gpsStatus.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsMeasureMode) {
        self.gpsMeasureMode.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDegreeOfPrecision) {
        self.gpsDegreeOfPrecision.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsSpeedRef) {
        self.gpsSpeedRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsSpeed) {
        self.gpsSpeed.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsTrackRef) {
        self.gpsTrackRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsTrack) {
        self.gpsTrack.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsImgDirectionRef) {
        self.gpsImgDirectionRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsImgDirection) {
        self.gpsImgDirection.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsMapDatum) {
        self.gpsMapDatum.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestLatRef) {
        self.gpsDestLatRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestLat) {
        self.gpsDestLat.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestLongRef) {
        self.gpsDestLongRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestLong) {
        self.gpsDestLong.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestBearingRef) {
        self.gpsDestBearingRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestBearing) {
        self.gpsDestBearing.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestDistanceRef) {
        self.gpsDestDistanceRef.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDestDistance) {
        self.gpsDestDistance.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsProcessingMethod) {
        self.gpsProcessingMethod.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsAreaInformation) {
        self.gpsAreaInformation.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDateStamp) {
        self.gpsDateStamp.text = s;
    }
    else if(self.currentlyBeingEdited == self.gpsDifferental) {
        self.gpsDifferental.text = s;
    }
    else {
        NSLog(@"failed");
    }
}

/**
 *  Shows a popup view with a description of the text field currently being edited.
 */
- (void)identifyPressed {
    [KLCPopup dismissAllPopups];
    NSLog(@"Identifying item");
    
    self.item.text = @"";
    self.item = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, 300, 20)];
    [self.item setFont:[UIFont fontWithName:@"Avenir-Heavy" size:12]];
    
//    self.itemInfo = [[UITextView alloc] initWithFrame:CGRectMake(20, 50, w-40, 70)];
    self.itemInfo = [[UITextView alloc] initWithFrame:CGRectMake((self.screenW-20)/2-(self.screenW-40)/2, 50, self.screenW-40, 70)];
    [self.itemInfo setFont:[UIFont fontWithName:@"Avenir" size:12]];
    
    [self describeItemWithTag:self.currentTag];
    
    [self.descriptionScrollView addSubview:self.item];
    [self.descriptionScrollView addSubview:self.itemInfo];
    
    [self.popup showWithLayout:KLCPopupLayoutMake(KLCPopupHorizontalLayoutCenter, KLCPopupVerticalLayoutTop)];
}

/**
 *  Contains the actual descriptions.
 */
- (void)describeItemWithTag: (long) tag {
    switch(tag) {
        case 0:
            self.item.text = @"Date created";
            self.itemInfo.text = @"The date that the original image data was generated. The date must be in yyyy:MM:dd format.";
            break;
        case 1:
            self.item.text = @"Date created";
            self.itemInfo.text = @"The time that the original image data was generated. The time must be in HH:mm:ss format.";
            break;
        case 2:
            self.item.text = @"Exposure time/Shutter speed";
            self.itemInfo.text = @"The length of time when the film/digital sensor in the camera is exposed to light. Measured in seconds.";
            break;
        case 3:
            self.item.text = @"f-number";
            self.itemInfo.text = @"The ratio of the lens's focal length to the diameter of the entrance pupil.";
            break;
        case 4:
            self.item.text = @"Exposure program";
            self.itemInfo.text = @"The class of the exposure program used to set exposure when the picture was taken. The values are represented by numbers.\n0 = Not defined\n1 = Manual\n2 = Normal\n3 = Aperture priority\n4 = Shutter priority\n5 = Creative program (biased toward depth of field)\n6 = Action program (biased toward fast shutter speed)\n7 = Portrait mode (for closeup photos with the background out of focus)\n8 = Landscape mode (for landscape photos with the background in focus)";
            break;
        case 5:
            self.item.text = @"Spectral sensitivity";
            self.itemInfo.text = @"Sensitivity to each color channel of the camera used.";
            break;
        case 6:
            self.item.text = @"ISO speed ratings";
            self.itemInfo.text = @"The ISO Speed and ISO Latitude of the camera or input device. This value will not update.";
            break;
        case 7:
            self.item.text = @"OECF";
            self.itemInfo.text = @"Opto-electrical conversion function, which defines the relationship between the optical input of the camera and the image values. This value will not update.";
            break;
        case 8:
            self.item.text = @"Exif version";
            self.itemInfo.text = @"Version of the Exif standard. This value will not update. Each number represents a digit of the version number. Ex: 2.31 = ( 2, 3, 1)";
            break;
        case 9:
            self.item.text = @"Components configuration";
            self.itemInfo.text = @"The channels of each component. This value will not update.";
            break;
        case 10:
            self.item.text = @"Compressed bits per pixel";
            self.itemInfo.text = @"The bits per pixel of the compression mode.";
            break;
        case 11:
            self.item.text = @"Shutter speed value";
            self.itemInfo.text = @"This is not the same as exposure time/shutter speed! This value is log base 2 of the reciprocal of the exposure time.";
            break;
        case 12:
            self.item.text = @"Aperture value";
            self.itemInfo.text = @"This value is log base √2 of the f-number.";
            break;
        case 13:
            self.item.text = @"Brightness value";
            self.itemInfo.text = @"Brightness of the subject.";
            break;
        case 14:
            self.item.text = @"Exposure bias";
            self.itemInfo.text = @"A.k.a. exposure compensation. Deliberately over or under exposing the subject to make up for poor image quality. Measured in number of f-stops.";
            break;
        case 15:
            self.item.text = @"Maximum aperture";
            self.itemInfo.text = @"The smallest f-number of the lens.";
            break;
        case 16:
            self.item.text = @"Subject distance";
            self.itemInfo.text = @"The distance to the focus point (subject). Measured in meters.";
            break;
        case 17:
            self.item.text = @"Metering mode";
            self.itemInfo.text = @"The part of the image that is optimized.";
            break;
        case 18:
            self.item.text = @"Light source";
            self.itemInfo.text = @"The kind of light source. i.e. White balance setting.";
            break;
        case 19:
            self.item.text = @"Flash";
            self.itemInfo.text = @"The status of flash when the image was shot.";
            break;
        case 20:
            self.item.text = @"Focal length";
            self.itemInfo.text = @"The actual focal length of the lens. Measured in millimeters.";
            break;
        case 21:
            self.item.text = @"Subject area";
            self.itemInfo.text = @"The location and area of the main subject in the overall scene.";
            break;
        case 22:
            self.item.text = @"Maker note";
            self.itemInfo.text = @"A tag for manufacturers of Exif writers to record any desired information.";
            break;
        case 23:
            self.item.text = @"User comment";
            self.itemInfo.text = @"User's keywords or comments on the image.";
            break;
        case 24:
            self.item.text = @"Subsec time";
            self.itemInfo.text = @"Fractions of seconds for the date and time.";
            break;
        case 25:
            self.item.text = @"Subsec time original";
            self.itemInfo.text = @"Fractions of seconds for the original date and time.";
            break;
        case 26:
            self.item.text = @"Subsec time digitized";
            self.itemInfo.text = @"Fractions of seconds for the digitized date and time.";
            break;
        case 27:
            self.item.text = @"FlashPix version";
            self.itemInfo.text = @"The FlashPix version supported by an FPXR file. FlashPix is a format for multiresolution tiled images that facilitates fast onscreen viewing. This value will not update.";
            break;
        case 28:
            self.item.text = @"Color space";
            self.itemInfo.text = @"The available range of colors.";
            break;
        case 29:
            self.item.text = @"Pixel X dimension";
            self.itemInfo.text = @"Width of the image in pixels.";
            break;
        case 30:
            self.item.text = @"Pixel Y dimension";
            self.itemInfo.text = @"Height of the image in pixels.";
            break;
        case 31:
            self.item.text = @"Related sound file";
            self.itemInfo.text = @"A sound file related to the image.";
            break;
        case 32:
            self.item.text = @"Flash energy";
            self.itemInfo.text = @"The strobe energy when the image was captured, in beam candle power seconds.";
            break;
        case 33:
            self.item.text = @"Spatial frequency response";
            self.itemInfo.text = @"The spatial frequency table and spatial frequency response values in the direction of image width, image height, and diagonal directions. This value will not update.";
            break;
        case 34:
            self.item.text = @"Focal plane X resolution";
            self.itemInfo.text = @"The number of image-width pixels per focal plane resolution unit.";
            break;
        case 35:
            self.item.text = @"Focal plane Y resolution";
            self.itemInfo.text = @"The number of image-height pixels per focal plane resolution unit.";
            break;
        case 36:
            self.item.text = @"Focal plane resolution unit";
            self.itemInfo.text = @"The unit of measurement for the focal plane X and Y tags.";
            break;
        case 37:
            self.item.text = @"Subject location";
            self.itemInfo.text = @"The location of the main subject in the scene.";
            break;
        case 38:
            self.item.text = @"Exposure index";
            self.itemInfo.text = @"The exposure index selected on the camera or input device at the time the image is captured.";
            break;
        case 39:
            self.item.text = @"Sensing method";
            self.itemInfo.text = @"The image sensor type on the camera or input device.";
            break;
        case 40:
            self.item.text = @"File source";
            self.itemInfo.text = @"The image source.";
            break;
        case 41:
            self.item.text = @"Scene type";
            self.itemInfo.text = @"The image source. Digital still cameras will show a value of 1. This value will not update.";
            break;
        case 42:
            self.item.text = @"CFA pattern";
            self.itemInfo.text = @"The color filter array (CFA) geometric pattern of the image sensor when a one-chip color area sensor is used. This value will not update.";
            break;
        case 43:
            self.item.text = @"Custom rendered";
            self.itemInfo.text = @"Whether special rendering was performed on the image data.";
            break;
        case 44:
            self.item.text = @"Exposure mode";
            self.itemInfo.text = @"The exposure mode that was set when the image was shot.";
            break;
        case 45:
            self.item.text = @"White balance";
            self.itemInfo.text = @"The white balance mode that was set when the image was shot.";
            break;
        case 46:
            self.item.text = @"Digital zoom ratio";
            self.itemInfo.text = @"Amount of zoom when the image was shot.";
            break;
        case 47:
            self.item.text = @"Focal length in 35 mm film";
            self.itemInfo.text = @"Focal length assuming a 35mm film camera. Measured in millimeters.";
            break;
        case 48:
            self.item.text = @"Scene capture type";
            self.itemInfo.text = @"Type of scene that was shot.";
            break;
        case 49:
            self.item.text = @"Gain control";
            self.itemInfo.text = @"The degree of overall image gain adjustment.";
            break;
        case 50:
            self.item.text = @"Contrast";
            self.itemInfo.text = @"The direction of contrast processing applied by the camera when the image was shot.";
            break;
        case 51:
            self.item.text = @"Saturation";
            self.itemInfo.text = @"The direction of saturation processing applied by the camera when the image was shot.";
            break;
        case 52:
            self.item.text = @"Sharpness";
            self.itemInfo.text = @"The direction of sharpness processing applied by the camera when the image was shot.";
            break;
        case 53:
            self.item.text = @"Device setting description";
            self.itemInfo.text = @"Picture-taking conditions of a particular camera model. This value will not update.";
            break;
        case 54:
            self.item.text = @"Subject distance range";
            self.itemInfo.text = @"Distance to the subject.";
            break;
        case 55:
            self.item.text = @"Image unique ID";
            self.itemInfo.text = @"Identifier assigned uniquely to each image.";
            break;
        case 56:
            self.item.text = @"Gamma";
            self.itemInfo.text = @"The gamma correction setting.";
            break;
        case 57:
            self.item.text = @"Camera owner name";
            self.itemInfo.text = @"The name of the camera’s owner.";
            break;
        case 58:
            self.item.text = @"Body serial number";
            self.itemInfo.text = @"The serial number of the camera.";
            break;
        case 59:
            self.item.text = @"Lens specification";
            self.itemInfo.text = @"The specification information for the lens used to photograph the image. This value will not update.";
            break;
        case 60:
            self.item.text = @"Lens make";
            self.itemInfo.text = @"The name of the lens’s manufacturer.";
            break;
        case 61:
            self.item.text = @"Lens model";
            self.itemInfo.text = @"The lens's model.";
            break;
        case 62:
            self.item.text = @"Lens model";
            self.itemInfo.text = @"The lens’s serial number.";
            break;
        case 71:
            self.item.text = @"GPS version";
            self.itemInfo.text = @"The GPS version. This value will not update. Each number represents a digit of the version number. Ex: 2.31 = ( 2, 3, 1)";
            break;
        case 72:
            self.item.text = @"Latitude ref";
            self.itemInfo.text = @"Whether the latitude is north or south. N or S.";
            break;
        case 73:
            self.item.text = @"Latitude";
            self.itemInfo.text = @"The latitude.";
            break;
        case 74:
            self.item.text = @"Longitude ref";
            self.itemInfo.text = @"Whether the longitude is east or west. E or W.";
            break;
        case 75:
            self.item.text = @"Longitude";
            self.itemInfo.text = @"The longitude.";
            break;
        case 76:
            self.item.text = @"Altitude ref";
            self.itemInfo.text = @"The reference altitude. '0' indicates above sea level and '1' indicates below sea level.";
            break;
        case 77:
            self.item.text = @"Altitude";
            self.itemInfo.text = @"The altitude. Measured in meters.";
            break;
        case 78:
            self.item.text = @"Time stamp";
            self.itemInfo.text = @"The time as UTC (Coordinated Universal Time).";
            break;
        case 79:
            self.item.text = @"Satellites";
            self.itemInfo.text = @"The satellites used for GPS measurements.";
            break;
        case 80:
            self.item.text = @"Status";
            self.itemInfo.text = @"The status of the GPS receiver. 'A' indicates a measurement is in progress and 'V' indicates interoperability.";
            break;
        case 81:
            self.item.text = @"Measure mode";
            self.itemInfo.text = @"The measurement mode. '2' indicates 2D measurement and '3' indicates 3D measurement.";
            break;
        case 82:
            self.item.text = @"Degree of precision";
            self.itemInfo.text = @"The degree of precision (DOP) of the data.";
            break;
        case 83:
            self.item.text = @"Speed ref";
            self.itemInfo.text = @"The unit for expressing the GPS receiver speed of movement. 'K' indicates km/hr, 'M' indicates mi/hr, 'N' indicates knots.";
            break;
        case 84:
            self.item.text = @"Speed";
            self.itemInfo.text = @"The GPS receiver speed of movement. Measured in units given by Speed ref.";
            break;
        case 85:
            self.item.text = @"Track ref";
            self.itemInfo.text = @"The reference for the direction of GPS receiver movement. 'T' indicates true direction and 'M' indicates magnetic direction.";
            break;
        case 86:
            self.item.text = @"Track";
            self.itemInfo.text = @"The direction of GPS receiver movement. The values range from 0.00 to 359.99.";
            break;
        case 87:
            self.item.text = @"Image direction ref";
            self.itemInfo.text = @"The reference for the direction of the image. 'T' indicates true direction and 'M' indicates magnetic direction.";
            break;
        case 88:
            self.item.text = @"Image direction";
            self.itemInfo.text = @"The direction of the image.";
            break;
        case 89:
            self.item.text = @"Map datum";
            self.itemInfo.text = @"The geodetic survey data used by the GPS receiver.";
            break;
        case 90:
            self.item.text = @"Destination latitude ref";
            self.itemInfo.text = @"Whether the latitude of the destination point is northern or southern. N or S.";
            break;
        case 91:
            self.item.text = @"Destination latitude";
            self.itemInfo.text = @"The latitude of the destination point.";
            break;
        case 92:
            self.item.text = @"Destination longitude ref";
            self.itemInfo.text = @"Whether the longitude of the destination point is east or west. E or W.";
            break;
        case 93:
            self.item.text = @"Destination longitude";
            self.itemInfo.text = @"The longitude of the destination point.";
            break;
        case 94:
            self.item.text = @"Destination bearing ref";
            self.itemInfo.text = @"The reference for giving the bearing to the destination point. 'T' indicates true direction and 'M' indicates magnetic direction.";
            break;
        case 95:
            self.item.text = @"Destination bearing";
            self.itemInfo.text = @"The bearing to the destination point. The values range from 0.00 to 359.99.";
            break;
        case 96:
            self.item.text = @"Destination distance ref";
            self.itemInfo.text = @"The units for expressing the distance to the destination point. 'K' indicates km/hr, 'M' indicates mi/hr, 'N' indicates knots.";
            break;
        case 97:
            self.item.text = @"Destination distance";
            self.itemInfo.text = @"The distance to the destination point.";
            break;
        case 98:
            self.item.text = @"Processing method";
            self.itemInfo.text = @"The name of the method used for finding a location. This value will not update.";
            break;
        case 99:
            self.item.text = @"Area information";
            self.itemInfo.text = @"The name of the GPS area. This value will not update.";
            break;
        case 100:
            self.item.text = @"Date stamp";
            self.itemInfo.text = @"The data and time information relative to Coordinated Universal Time (UTC). This value will not update.";
            break;
        case 101:
            self.item.text = @"Differential";
            self.itemInfo.text = @"Whether differential correction is applied to the GPS receiver. '0' indicates no differential correction and '1' indicates differential correction was applied.";
            break;
        case 111:
            self.item.text = @"File name";
            self.itemInfo.text = @"The file name.";
            break;
        default:
            break;
    }
}

/**
 *  Populates the dictionary, which pairs the exif/gps objects to the tags of their respective text fields.
 */
- (void)populateDictionary {
    NSLog(@"now populating dict");
    self.tags = [[NSMutableDictionary alloc] init];
    [self.tags setObject:@"dateTimeOriginal" forKey:@"0"];
    [self.tags setObject:@"dateTimeOriginalTime" forKey:@"1"];
    [self.tags setObject:@"exifExposureTime" forKey:@"2"];
    [self.tags setObject:@"exifFNumber" forKey:@"3"];
    [self.tags setObject:@"exifExposureProgram" forKey:@"4"];
    [self.tags setObject:@"exifSpectralSensitivity" forKey:@"5"];
    [self.tags setObject:@"exifISOSpeedRatings" forKey:@"6"];
    [self.tags setObject:@"exifOECF" forKey:@"7"];
    [self.tags setObject:@"exifVersion" forKey:@"8"];
    [self.tags setObject:@"exifComponentsConfiguration" forKey:@"9"];
    [self.tags setObject:@"exifCompressedBitsPerPixel" forKey:@"10"];
    [self.tags setObject:@"exifShutterSpeedValue" forKey:@"11"];
    [self.tags setObject:@"exifApertureValue" forKey:@"12"];
    [self.tags setObject:@"exifBrightnessValue" forKey:@"13"];
    [self.tags setObject:@"exifExposureBiasValue" forKey:@"14"];
    [self.tags setObject:@"exifMaxApertureValue" forKey:@"15"];
    [self.tags setObject:@"exifSubjectDistance" forKey:@"16"];
    [self.tags setObject:@"exifMeteringMode" forKey:@"17"];
    [self.tags setObject:@"exifLightSource" forKey:@"18"];
    [self.tags setObject:@"exifFlash" forKey:@"19"];
    [self.tags setObject:@"exifFocalLength" forKey:@"20"];
    [self.tags setObject:@"exifSubjectArea" forKey:@"21"];
    [self.tags setObject:@"exifMakerNote" forKey:@"22"];
    [self.tags setObject:@"exifUserComment" forKey:@"23"];
    [self.tags setObject:@"exifSubsecTime" forKey:@"24"];
    [self.tags setObject:@"exifSubsecTimeOrginal" forKey:@"25"];
    [self.tags setObject:@"exifSubsecTimeDigitized" forKey:@"26"];
    [self.tags setObject:@"exifFlashPixVersion" forKey:@"27"];
    [self.tags setObject:@"exifColorSpace" forKey:@"28"];
    [self.tags setObject:@"exifPixelXDimension" forKey:@"29"];
    [self.tags setObject:@"exifPixelYDimension" forKey:@"30"];
    [self.tags setObject:@"exifRelatedSoundFile" forKey:@"31"];
    [self.tags setObject:@"exifFlashEnergy" forKey:@"32"];
    [self.tags setObject:@"exifSpatialFrequencyResponse" forKey:@"33"];
    [self.tags setObject:@"exifFocalPlaneXResolution" forKey:@"34"];
    [self.tags setObject:@"exifFocalPlaneYResolution" forKey:@"35"];
    [self.tags setObject:@"exifFocalPlaneResolutionUnit" forKey:@"36"];
    [self.tags setObject:@"exifSubjectLocation" forKey:@"37"];
    [self.tags setObject:@"exifExposureIndex" forKey:@"38"];
    [self.tags setObject:@"exifSensingMethod" forKey:@"39"];
    [self.tags setObject:@"exifFileSource" forKey:@"40"];
    [self.tags setObject:@"exifSceneType" forKey:@"41"];
    [self.tags setObject:@"exifCFAPattern" forKey:@"42"];
    [self.tags setObject:@"exifCustomRendered" forKey:@"43"];
    [self.tags setObject:@"exifExposureMode" forKey:@"44"];
    [self.tags setObject:@"exifWhiteBalance" forKey:@"45"];
    [self.tags setObject:@"exifDigitalZoomRatio" forKey:@"46"];
    [self.tags setObject:@"exifFocalLenIn35mmFilm" forKey:@"47"];
    [self.tags setObject:@"exifSceneCaptureType" forKey:@"48"];
    [self.tags setObject:@"exifGainControl" forKey:@"49"];
    [self.tags setObject:@"exifContrast" forKey:@"50"];
    [self.tags setObject:@"exifSaturation" forKey:@"51"];
    [self.tags setObject:@"exifSharpness" forKey:@"52"];
    [self.tags setObject:@"exifDeviceSettingDescription" forKey:@"53"];
    [self.tags setObject:@"exifSubjectDistRange" forKey:@"54"];
    [self.tags setObject:@"exifImageUniqueID" forKey:@"55"];
    [self.tags setObject:@"exifGamma" forKey:@"56"];
    [self.tags setObject:@"exifCameraOwnerName" forKey:@"57"];
    [self.tags setObject:@"exifBodySerialNumber" forKey:@"58"];
    [self.tags setObject:@"exifLensSpecification" forKey:@"59"];
    [self.tags setObject:@"exifLensMake" forKey:@"60"];
    [self.tags setObject:@"exifLensModel" forKey:@"61"];
    [self.tags setObject:@"exifLensSerialNumber" forKey:@"62"];
    [self.tags setObject:@"gpsVersion" forKey:@"71"];
    [self.tags setObject:@"gpsLatitudeRef" forKey:@"72"];
    [self.tags setObject:@"gpsLatitude" forKey:@"73"];
    [self.tags setObject:@"gpsLongitudeRef" forKey:@"74"];
    [self.tags setObject:@"gpsLongitude" forKey:@"75"];
    [self.tags setObject:@"gpsAltitudeRef" forKey:@"76"];
    [self.tags setObject:@"gpsAltitude" forKey:@"77"];
    [self.tags setObject:@"gpsTimeStamp" forKey:@"78"];
    [self.tags setObject:@"gpsSatellites" forKey:@"79"];
    [self.tags setObject:@"gpsStatus" forKey:@"80"];
    [self.tags setObject:@"gpsMeasureMode" forKey:@"81"];
    [self.tags setObject:@"gpsDegreeOfPrecision" forKey:@"82"];
    [self.tags setObject:@"gpsSpeedRef" forKey:@"83"];
    [self.tags setObject:@"gpsSpeed" forKey:@"84"];
    [self.tags setObject:@"gpsTrackRef" forKey:@"85"];
    [self.tags setObject:@"gpsTrack" forKey:@"86"];
    [self.tags setObject:@"gpsImgDirectionRef" forKey:@"87"];
    [self.tags setObject:@"gpsImgDirection" forKey:@"88"];
    [self.tags setObject:@"gpsMapDatum" forKey:@"89"];
    [self.tags setObject:@"gpsDestLatRef" forKey:@"90"];
    [self.tags setObject:@"gpsDestLat" forKey:@"91"];
    [self.tags setObject:@"gpsDestLongRef" forKey:@"92"];
    [self.tags setObject:@"gpsDestLong" forKey:@"93"];
    [self.tags setObject:@"gpsDestBearingRef" forKey:@"94"];
    [self.tags setObject:@"gpsDestBearing" forKey:@"95"];
    [self.tags setObject:@"gpsDestDistanceRef" forKey:@"96"];
    [self.tags setObject:@"gpsDestDistance" forKey:@"97"];
    [self.tags setObject:@"gpsProcessingMethod" forKey:@"98"];
    [self.tags setObject:@"gpsAreaInformation" forKey:@"99"];
    [self.tags setObject:@"gpsDateStamp" forKey:@"100"];
    [self.tags setObject:@"gpsDifferental" forKey:@"101"];
    [self.tags setObject:@"fileName" forKey:@"111"];
}

/**
 *  Handles what happens when the keyboard is closed. Could come in handy someday.
 */
- (void)donePressed {
    NSLog(@"Done/closing the keyboard");
}

- (void)dealloc {
    [self.mapView removeObserver:self
                  forKeyPath:@"myLocation"
                     context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (!self.firstLocationUpdate) {
        // If the first location update has not yet been recieved, then jump to that
        // location.
        self.firstLocationUpdate = YES;
        CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
        self.mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                         zoom:6];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.gpsMapView setRegion:[self.gpsMapView regionThatFits:region] animated:YES];
}

- (IBAction) startShowingUserHeading:(id)sender{
    self.gpsLatitude.text = [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.latitude];
    if(self.locationManager.location.coordinate.latitude > 0) {
        NSLog(@"north");
        self.gpsLatitudeRef.text = @"N";
    }
    else {
        NSLog(@"south");
        self.gpsLatitudeRef.text = @"S";
    }
    self.gpsLongitude.text = [NSString stringWithFormat:@"%f", self.locationManager.location.coordinate.longitude];
    if(self.locationManager.location.coordinate.longitude > 0) {
        NSLog(@"east");
        self.gpsLongitudeRef.text = @"E";
    }
    else {
        NSLog(@"west");
        self.gpsLongitudeRef.text = @"W";
    }
    
    if(self.gpsMapView.userTrackingMode == 0){
        [self.gpsMapView setUserTrackingMode: MKUserTrackingModeFollow animated: YES];
        
        //Turn on the position arrow
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationBlue.png"];
        [self.userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
    else if(self.gpsMapView.userTrackingMode == 1){
        [self.gpsMapView setUserTrackingMode: MKUserTrackingModeFollowWithHeading animated: YES];
        
        //Change it to heading angle
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationHeadingBlue"];
        [self.userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
    else if(self.gpsMapView.userTrackingMode == 2){
        [self.gpsMapView setUserTrackingMode: MKUserTrackingModeNone animated: YES];
        
        //Put it back again
        UIImage *buttonArrow = [UIImage imageNamed:@"LocationGrey.png"];
        [self.userHeadingBtn setImage:buttonArrow forState:UIControlStateNormal];
    }
}

- (IBAction) resetMapLocation:(id)sender{
    MKCoordinateRegion region;
    region.center.latitude = self.latval;
    region.center.longitude = self.longval;
    region.span.latitudeDelta = 0.01;
    region.span.longitudeDelta = 0.01;
    
    self.gpsLatitude.text = [NSString stringWithFormat:@"%f", self.latval];
    if(self.latval > 0) {
        NSLog(@"north");
        self.gpsLatitudeRef.text = @"N";
    }
    else {
        NSLog(@"south");
        self.gpsLatitudeRef.text = @"S";
    }
    self.gpsLongitude.text = [NSString stringWithFormat:@"%f", self.longval];
    if(self.longval > 0) {
        NSLog(@"east");
        self.gpsLongitudeRef.text = @"E";
    }
    else {
        NSLog(@"west");
        self.gpsLongitudeRef.text = @"W";
    }
    
    [self.gpsMapView setRegion:region animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
//    NSLog(@"you searched %@", searchText);
    CGPoint searchPoint = pointFromRectangle(self.searchBar.frame);
    searchPoint.y -= 64;
    [self.scrollView setContentOffset:(searchPoint) animated:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    CGPoint searchPoint = pointFromRectangle(self.searchBar.frame);
    searchPoint.y -= 64;
    [self.scrollView setContentOffset:(searchPoint) animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:theSearchBar.text completionHandler:^(NSArray *placemarks, NSError *error) {
        //Error checking
        
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        MKCoordinateRegion region;
        region.center.latitude = placemark.region.center.latitude;
        region.center.longitude = placemark.region.center.longitude;
        
        self.gpsLatitude.text = [NSString stringWithFormat:@"%f", region.center.latitude];
        if(region.center.latitude > 0) {
            NSLog(@"north");
            self.gpsLatitudeRef.text = @"N";
        }
        else {
            NSLog(@"south");
            self.gpsLatitudeRef.text = @"S";
        }
        self.gpsLongitude.text = [NSString stringWithFormat:@"%f", region.center.longitude];
        if(region.center.longitude > 0) {
            NSLog(@"east");
            self.gpsLongitudeRef.text = @"E";
        }
        else {
            NSLog(@"west");
            self.gpsLongitudeRef.text = @"W";
        }
        
        MKCoordinateSpan span;
        double radius = placemark.region.radius / 1000; // convert to km
        
        NSLog(@"[searchBarSearchButtonClicked] Radius is %f", radius);
        span.latitudeDelta = radius / 112.0;
        
        region.span = span;
        
        [self.gpsMapView setRegion:region animated:YES];
    }];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end

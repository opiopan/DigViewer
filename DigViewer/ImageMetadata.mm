//
//  ImageMetadata.mm
//  DigViewer
//
//  Created by opiopan on 2014/02/18.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "ImageMetadata.h"
#import "CoreFoundationHelper.h"

#include <math.h>

//-----------------------------------------------------------------------------------------
// メタデータ用dictionary種別定義 ＆ データ値変換データベース
//-----------------------------------------------------------------------------------------
enum PropertyKind {
    propertyALL = 0,
    propertyTIFF,
    propertyGIF,
    propertyJFIF,
    propertyEXIF,
    propertyPNG,
    propertyIPTC,
    propertyGPS,
    propertyRAW,
    propertyCIFF,
    property8BIM,
    propertyDNG,
    propertyEXIFAUX,
    propertyKindNum
};

static struct {
    PropertyKind kind;
    CFStringRef  key;
} propertyDictonaryKeys[] = {
    propertyTIFF,       kCGImagePropertyTIFFDictionary,
    propertyGIF,        kCGImagePropertyGIFDictionary,
    propertyJFIF,       kCGImagePropertyJFIFDictionary,
    propertyEXIF,       kCGImagePropertyExifDictionary,
    propertyPNG,        kCGImagePropertyPNGDictionary,
    propertyIPTC,       kCGImagePropertyIPTCDictionary,
    propertyGPS,        kCGImagePropertyGPSDictionary,
    propertyRAW,        kCGImagePropertyRawDictionary,
    propertyCIFF,       kCGImagePropertyCIFFDictionary,
    property8BIM,       kCGImageProperty8BIMDictionary,
    propertyDNG,        kCGImagePropertyDNGDictionary,
    propertyEXIFAUX,    kCGImagePropertyExifAuxDictionary
};

enum PropertyValueType {pvTypeSimple, pvTypeHeadOfArray, pvTypeSpecial, pvTypeSeparator};

struct TranslationRule;
static NSString* convertDate(ImageMetadata* meta, TranslationRule* rule);
static NSString* convertLensModel(ImageMetadata* meta, TranslationRule* rule);
static NSString* convertExposureTime(ImageMetadata* meta, TranslationRule* rule);
static NSString* convertLensSpec(ImageMetadata* meta, TranslationRule* rule);
static NSString* convertFlash(ImageMetadata* meta, TranslationRule* rule);
static NSString* convertExposureBias(ImageMetadata* meta, TranslationRule* rule);

#define MAPDEF(map) sizeof(map)/sizeof(*map), map
static const char* sensingMethods[] = {
    "Unknown", "Monochrome Area Sensor", "1 Chip Color Sensor", "2 Chip Color Sensor", "3 Chip Color Sensor",
    "Color Sequential Area", "Monochrome Linear", "Trilinear", "Color Sequential Linear"
};
static const char* exposurePrograms[] = {
    "Unknown", "Manual", "Program AE", "Aperture Priority AE", "Shutter Speed Priority AE",
    "Creative (Depth of field priority)", "Action (High speed priority)", "Portrait", "Landscape"
};
static const char* exposureModes[] = {
    "Auto", "Manual", "Auto Bracket"
};
static const char* meteringModes[] = {
    "Unknown", "Average", "Center Weighted Average", "Spot", "Multi Spot", "Multi Segment", "Partial", "Other"
};
static const char* whiteBalances[] = {
    "Auto", "Manual"
};
static const char* contrasts[] = {
    "Normal", "Soft", "Hard"
};
static const char* saturations[] = {
    "Normal", "Low", "High"
};
static const char* sharpnesses[] = {
    "Normal", "Soft", "Hard"
};
static const char* sceneCaptureTypes[] = {
    "Starndard", "Landscape", "Portrait", "Night"
};
static const char* subjectDists[] = {
    "Unknown", "Macro", "Close", "Distant"
};
static const char* customRendereds[] = {
    "None", "Custom Processing"
};

static struct TranslationRule{
    PropertyKind        dictionary;
    CFStringRef         key;
    PropertyValueType   type;
    const char*         keyName;
    const char*         convertingFormat;
    int                 mapSize;
    const char**        map;
    NSString* (*convert)(ImageMetadata* meta, TranslationRule* rule);
}valueTranslationRules[] = {
    propertyEXIF, kCGImagePropertyExifDateTimeOriginal, pvTypeSpecial, "Date Time:", NULL, 0, NULL, convertDate,
    propertyALL, kCGImagePropertyProfileName, pvTypeSimple, "Color Profile:", "%@", 0, NULL, NULL,
    propertyALL, kCGImagePropertyDepth, pvTypeSimple, "Bit Depth:", "%@ bit", 0, NULL, NULL,
    propertyALL, NULL, pvTypeSeparator, NULL, NULL, 0, NULL, NULL,
    propertyTIFF, kCGImagePropertyTIFFMake, pvTypeSimple, "Camera Maker:", "%@", 0, NULL, NULL,
    propertyTIFF, kCGImagePropertyTIFFModel, pvTypeSimple, "Camera Model:", "%@", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifSensingMethod, pvTypeSimple, "Sensing Method:", NULL, MAPDEF(sensingMethods), NULL,
    propertyEXIF, kCGImagePropertyExifLensMake, pvTypeSimple, "Lens Maker:", "%@", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifLensModel, pvTypeSpecial, "Lens Model:", NULL, 0, NULL, convertLensModel,
    propertyEXIF, kCGImagePropertyExifLensSpecification, pvTypeSpecial, "Lens Spec:", NULL, 0, NULL, convertLensSpec,
    propertyALL, NULL, pvTypeSeparator, NULL, NULL, 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifFocalLength, pvTypeSimple, "Focal Length:", "%@ mm", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifFocalLenIn35mmFilm, pvTypeSimple, "Focal Length in 35mm:", "%@ mm", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifExposureTime, pvTypeSpecial, "Exposure Time:", NULL, 0, NULL, convertExposureTime,
    propertyEXIF, kCGImagePropertyExifFNumber, pvTypeSimple, "Aperture:", "f/%@", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifISOSpeedRatings, pvTypeHeadOfArray, "ISO Speed:", "ISO%@", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifExposureBiasValue, pvTypeSpecial, "Exposure Bias:", NULL, 0, NULL, convertExposureBias,
    propertyEXIF, kCGImagePropertyExifExposureProgram, pvTypeSimple, "Exposure Program:", NULL, MAPDEF(exposurePrograms), NULL,
    propertyEXIF, kCGImagePropertyExifExposureMode, pvTypeSimple, "Exposure Mode:", NULL, MAPDEF(exposureModes), NULL,
    propertyEXIF, kCGImagePropertyExifMeteringMode, pvTypeSimple, "Metering Mode:", NULL, MAPDEF(meteringModes), NULL,
    propertyEXIF, kCGImagePropertyExifFlash, pvTypeSpecial, "Flash:", NULL, 0, NULL, convertFlash,
    propertyEXIF, kCGImagePropertyExifFlashEnergy, pvTypeSimple, "Flash Energy:", "%@ BCPS", 0, NULL, NULL,
    propertyEXIF, kCGImagePropertyExifWhiteBalance, pvTypeSimple, "White Balance:", NULL, MAPDEF(whiteBalances), NULL,
    propertyEXIF, kCGImagePropertyExifContrast, pvTypeSimple, "Contrast:", NULL, MAPDEF(contrasts), NULL,
    propertyEXIF, kCGImagePropertyExifSaturation, pvTypeSimple, "Saturation:", NULL, MAPDEF(saturations), NULL,
    propertyEXIF, kCGImagePropertyExifSharpness, pvTypeSimple, "Sharpness:", NULL, MAPDEF(sharpnesses), NULL,
    propertyEXIF, kCGImagePropertyExifSceneCaptureType, pvTypeSimple, "Scene Cpature Type:", NULL, MAPDEF(sceneCaptureTypes), NULL,
    propertyEXIF, kCGImagePropertyExifSubjectDistRange, pvTypeSimple, "Subject Distance Range:", NULL, MAPDEF(subjectDists), NULL,
    propertyEXIF, kCGImagePropertyExifCustomRendered, pvTypeSimple, "Special Effects:", NULL, MAPDEF(customRendereds), NULL,
    propertyALL, NULL, pvTypeSeparator, NULL, NULL, 0, NULL, NULL,
    propertyTIFF, kCGImagePropertyTIFFSoftware, pvTypeSimple, "Processing Software:", "%@", 0, NULL, NULL,
};

//-----------------------------------------------------------------------------------------
// 値変換関数
//-----------------------------------------------------------------------------------------
static NSString* convertDate(ImageMetadata* meta, TranslationRule* rule)
{
    NSString* value = [[meta propertiesAtIndex:rule->dictionary] valueForKey:(__bridge NSString*)rule->key];
    NSString* rc = nil;
    if (value){
        NSRange yyyy = {0, 4};
        NSRange mm = {5, 2};
        NSRange dd = {8, 2};
        rc = [NSString stringWithFormat:@"%@/%@/%@ %@",
              [value substringWithRange:yyyy], [value substringWithRange:mm], [value substringWithRange:dd],
              [value substringFromIndex:11]];
    }
    return rc;
}

static NSString* convertLensModel(ImageMetadata* meta, TranslationRule* rule)
{
    static struct {
        PropertyKind        dictionary;
        CFStringRef         key;
    }metaref[] = {
        propertyEXIF, kCGImagePropertyExifLensModel,
        propertyEXIFAUX, kCGImagePropertyExifAuxLensModel,
        propertyCIFF, kCGImagePropertyCIFFLensModel,
    };
    NSString* value = nil;
    for (int i = 0; i < sizeof(metaref) / sizeof(*metaref); i++){
        value = [[meta propertiesAtIndex:metaref[i].dictionary] valueForKey:(__bridge NSString*)metaref[i].key];
        if (value){
            break;
        }
    }
    return value;
}

static NSString* convertExposureTime(ImageMetadata* meta, TranslationRule* rule)
{
    NSNumber* value = [[meta propertiesAtIndex:rule->dictionary] valueForKey:(__bridge NSString*)rule->key];
    NSString* valueString = nil;
    if (value){
        if (value.doubleValue < 0.5){
            valueString = [NSString stringWithFormat:@"1/%.f sec", 1.0 / value.doubleValue];
        }else{
            valueString = [NSString stringWithFormat:@"%@ sec", value];
        }
    }
    return valueString;
}

static NSString* convertLensSpec(ImageMetadata* meta, TranslationRule* rule)
{
    static struct {
        PropertyKind        dictionary;
        CFStringRef         key;
    }metaref[] = {
        propertyEXIF, kCGImagePropertyExifLensSpecification,
        propertyEXIFAUX, kCGImagePropertyExifAuxLensInfo,
        propertyDNG, kCGImagePropertyDNGLensInfo,
    };
    NSArray* value = nil;
    for (int i = 0; i < sizeof(metaref) / sizeof(*metaref); i++){
        value = [[meta propertiesAtIndex:metaref[i].dictionary] valueForKey:(__bridge NSString*)metaref[i].key];
        if (value){
            break;
        }
    }
    NSString* valueString = nil;
    if (value){
        NSNumber* fLength1 = value[0];
        NSNumber* fLength2 = value[1];
        NSNumber* fNum1 = value[2];
        NSNumber* fNum2 = value[3];
        NSString* lensType = nil;
        NSString* focalLength = nil;
        NSString* fNumber = nil;
        if ([fLength1 isEqualToNumber:fLength2]){
            lensType = NSLocalizedString(@"Fixed Focal Length", nil);
            focalLength = [fLength1 stringValue];
        }else{
            lensType = NSLocalizedString(@"Zoom", nil);
            focalLength = [NSString stringWithFormat:@"%@-%@", fLength1, fLength2];
        }
        if ([fNum1 isEqualToNumber:fNum2]){
            fNumber = [fNum1 stringValue];
        }else{
            fNumber = [NSString stringWithFormat:@"%@-%@", fNum1, fNum2];
        }
        valueString = [NSString stringWithFormat:@"%@ %@mm f/%@", lensType, focalLength, fNumber];
    }
    return valueString;
}

static NSString* convertFlash(ImageMetadata* meta, TranslationRule* rule)
{
    NSNumber* value = [[meta propertiesAtIndex:rule->dictionary] valueForKey:(__bridge NSString*)rule->key];
    NSMutableString* valueString = nil;
    if (value){
        NSInteger code = value.integerValue;
        NSString* separator = NSLocalizedString(@", ", nil);
        NSString* __block currentSeparator = nil;

        valueString = [[NSMutableString alloc] init];
        void (^appendString)(NSString*) = ^(NSString* string){
            if (currentSeparator){
                [valueString appendString:currentSeparator];
            }
            [valueString appendString:string];
            currentSeparator = separator;
        };
        
        switch (code & 0x18){
            case 0x8:
                appendString(NSLocalizedString(@"On", nil));
                break;
            case 0x10:
                appendString(NSLocalizedString(@"Off", nil));
                break;
            case 0x18:
                appendString(NSLocalizedString(@"Auto", nil));
                break;
        }

        if (code & 0x1){
            appendString(NSLocalizedString(@"Fired", nil));
        }else{
            appendString(NSLocalizedString(@"Did not fire", nil));
        }
        
        if (code & 0x20){
            appendString(NSLocalizedString(@"No flash function", nil));
        }
        
        switch(code & 0x6){
            case 0x4:
                appendString(NSLocalizedString(@"Return not detected", nil));
                break;
            case 0x6:
                appendString(NSLocalizedString(@"Return detected", nil));
                break;
        }
        
        if (code & 0x40){
            appendString(NSLocalizedString(@"Red-eye reduction", nil));
        }
    }
    return valueString;
}

static NSString* convertExposureBias(ImageMetadata* meta, TranslationRule* rule)
{
    NSNumber* value = [[meta propertiesAtIndex:rule->dictionary] valueForKey:(__bridge NSString*)rule->key];
    NSString* valueString = nil;
    if (value){
        if (value.doubleValue > 0){
            valueString  = [NSString stringWithFormat:@"+%@ EV", value];
        }else if (value.doubleValue < 0){
            valueString  = [NSString stringWithFormat:@"%@ EV", value];
        }else{
            valueString = NSLocalizedString(@"None", nil);
        }
    }
    return valueString;
}

//-----------------------------------------------------------------------------------------
// ImageMetadataクラス implementation
//-----------------------------------------------------------------------------------------
@implementation ImageMetadata{
    NSString*       _name;
    NSString*       _type;
    NSString*       _geometry;
    NSDictionary*   _properties[propertyKindNum];
    NSArray*        _summary;
    GPSInfo*        _gpsInfo;
    NSArray*        _gpsInfoStrings;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)initWithPathNode:(PathNode *)pathNode
{
    self = [self init];
    if (self){
        _name = pathNode.name;
        NSWorkspace* workspace = [NSWorkspace sharedWorkspace];
        if (pathNode.isImage){
            NSError* error;
            _type = [workspace localizedDescriptionForType:[workspace typeOfFile:pathNode.imagePath error:&error]];
            NSURL* url = [NSURL fileURLWithPath:pathNode.imagePath];
            ECGImageSourceRef imageSource(CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL));
            _properties[propertyALL] = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            for (int i = 0; i < sizeof(propertyDictonaryKeys) / sizeof(propertyDictonaryKeys[0]); i++){
                _properties[propertyDictonaryKeys[i].kind] =
                    [_properties[propertyALL] valueForKey:(__bridge NSString*)propertyDictonaryKeys[i].key];
            }
            NSNumber* x = [_properties[propertyALL] valueForKey:(__bridge NSString*)kCGImagePropertyPixelWidth];
            NSNumber* y = [_properties[propertyALL] valueForKey:(__bridge NSString*)kCGImagePropertyPixelHeight];
            if (x && y){
                _geometry = [NSString stringWithFormat:@"%@ x %@", x, y];
            }
        }else{
            _type = [workspace localizedDescriptionForType:@"public.folder"];
        }
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// サマリー取得
//-----------------------------------------------------------------------------------------
- (NSArray*)summary
{
    if (!_summary){
        NSMutableArray* array = [[NSMutableArray alloc] init];
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"File Name:", nil) value:_name]];
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Type:", nil) value:_type]];
        if (_properties[propertyALL] || !_name){
            NSMutableArray* section = [[NSMutableArray alloc] init];
            [section addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Image size:", nil) value:_geometry]];
            int validRowCount = _geometry ? 1 : 0;
            for (int i = 0; i < sizeof(valueTranslationRules) / sizeof(*valueTranslationRules); i++){
                struct TranslationRule* rule = valueTranslationRules + i;
                NSString* keyString = nil;
                NSString* valueString = nil;
                if (rule->type == pvTypeSeparator){
                    if (validRowCount > 0 || !_name){
                        [array addObjectsFromArray:section];
                    }
                    section = [[NSMutableArray alloc] initWithObjects:[ImageMetadataKV kvWithKey:nil value:nil], nil];
                    validRowCount = 0;
                }else{
                    keyString = NSLocalizedString(@(rule->keyName), nil);
                    if (rule->type != pvTypeSpecial){
                        id value = [_properties[rule->dictionary] valueForKey:(__bridge NSString*)rule->key];
                        if (rule->type == pvTypeHeadOfArray){
                            value = ((NSArray*)value)[0];
                        }
                        if (value){
                            if (rule->map){
                                NSInteger index = [(NSNumber*)value integerValue];
                                if (index >= 0 && index < rule->mapSize){
                                    valueString = NSLocalizedString(@(rule->map[index]), nil);
                                }else{
                                    valueString = NSLocalizedString(@"Unknown", nil);
                                }
                            }else{
                                valueString = [NSString stringWithFormat:@(rule->convertingFormat), value];
                            }
                        }
                    }else{
                        valueString = rule->convert(self, rule);
                    }
                    [section addObject:[ImageMetadataKV kvWithKey:keyString value:valueString]];
                    validRowCount += valueString ? 1 : 0;
                }
            }
            if (validRowCount > 0 || !_name){
                [array addObjectsFromArray:section];
            }
        }
        _summary = array;
    }
    
    return _summary;
}

//-----------------------------------------------------------------------------------------
// GPS情報取得
//-----------------------------------------------------------------------------------------
- (GPSInfo*)gpsInfo
{
    NSDictionary* base = _properties[propertyALL];
    NSDictionary* exif = _properties[propertyEXIF];
    NSDictionary* gps = _properties[propertyGPS];
    if (!_gpsInfo && gps){
        _gpsInfo = [[GPSInfo alloc] init];
        // 緯度
        double latitude =
            [[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSLatitude] doubleValue] *
            ([[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSLatitudeRef] isEqualToString:@"N"] ? 1.0 : -1.0);
        _gpsInfo.latitude = [NSNumber numberWithDouble:latitude];
        
        // 経度
        double longitude =
            [[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSLongitude] doubleValue] *
            ([[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSLongitudeRef] isEqualToString:@"E"] ? 1.0 : -1.0);
        _gpsInfo.longitude = [NSNumber numberWithDouble:longitude];
        
        // 高度
        NSNumber* altitudeValue = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSAltitude];
        if (altitudeValue){
            double altitude =
                [altitudeValue doubleValue] *
                ([[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSAltitudeRef] intValue] ? -1.0 : 1.0);
            _gpsInfo.altitude = [NSNumber numberWithDouble:altitude];
        }
        
        // 撮影画像の方向
        NSNumber* imageDirectionValue = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSImgDirection];
        if (imageDirectionValue){
            _gpsInfo.imageDirection = imageDirectionValue;
            _gpsInfo.imageDirectionKind =
                [[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSImgDirectionRef] isEqualToString:@"T"] ?
                NSLocalizedString(@"True Direction", nil) : NSLocalizedString(@"Magnetic Direction", nil);
        }
        
        // 速度
        NSNumber* headingValue = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSTrack];
        if (headingValue){
            _gpsInfo.heading = headingValue;
            _gpsInfo.headingKind =
                [[gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSTrackRef] isEqualToString:@"T"] ?
                NSLocalizedString(@"True Direction", nil) : NSLocalizedString(@"Magnetic Direction", nil);
            _gpsInfo.velocity = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSSpeed];
            NSString* velocityUnit = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSSpeedRef];
            _gpsInfo.velocityUnit = [velocityUnit isEqualToString:@"K"] ? NSLocalizedString(@"km/h", nil) :
                                    [velocityUnit isEqualToString:@"M"] ? NSLocalizedString(@"mph", nil) :
                                    NSLocalizedString(@"knot", nil);
        }
        
        // GPS日時
        NSString* time = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSTimeStamp];
        if (time){
            NSString* date = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSDateStamp];
            if (date){
                NSRange yyyy = {0, 4};
                NSRange mm = {5, 2};
                NSRange dd = {8, 2};
                _gpsInfo.dateTime = [NSString stringWithFormat:@"%@/%@/%@ %@ UTC",
                                     [date substringWithRange:yyyy], [date substringWithRange:mm], [date substringWithRange:dd],
                                     time];
            }else{
                _gpsInfo.dateTime = [time stringByAppendingString:@" UTC"];
            }

        }
        
        // 測位方法
        NSString* measureMode = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSMeasureMode];
        if (measureMode){
            _gpsInfo.measureMode = [measureMode isEqualToString:@"2"] ? NSLocalizedString(@"2D", nil) :
                                                                        NSLocalizedString(@"3D", nil);
        }
        
        // 地図種別
        _gpsInfo.geodeticReferenceSystem = [gps valueForKey:(__bridge NSString*)kCGImagePropertyGPSMapDatum];
        
        // 焦点距離 (35mm換算) & 画像の向き
        _gpsInfo.focalLengthIn35mm = [exif valueForKey:(__bridge NSString*)kCGImagePropertyExifFocalLenIn35mmFilm];
        _gpsInfo.rotation = [base valueForKey:(__bridge NSString*)kCGImagePropertyOrientation];
    }
    return _gpsInfo;
}

- (NSArray*)gpsInfoStrings
{
    GPSInfo* gpsInfo = self.gpsInfo;
    if (!_gpsInfoStrings){
        NSMutableArray* array = [[NSMutableArray alloc] init];
        _gpsInfoStrings = array;
        
        // 緯度
        NSString* value = nil;
        if (gpsInfo && gpsInfo.latitude){
            double latitude = [gpsInfo.latitude doubleValue];
            NSString* format = latitude >= 0 ? NSLocalizedString(@"%@ N", nil) :
                                               NSLocalizedString(@"%@ S", nil);
            value = [NSString stringWithFormat:format, [self convertToDegrees:latitude]];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Latitude:", nil) value:value]];

        // 経度
        value = nil;
        if (gpsInfo && gpsInfo.longitude){
            double longitude = [gpsInfo.longitude doubleValue];
            NSString* format = longitude >= 0 ? NSLocalizedString(@"%@ E", nil) :
                                                NSLocalizedString(@"%@ W", nil);
            value = [NSString stringWithFormat:format, [self convertToDegrees:longitude]];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Longitude:", nil) value:value]];

        // 高度
        value = nil;
        if (gpsInfo && gpsInfo.altitude){
            value = [NSString stringWithFormat:@"%.1f m", [gpsInfo.altitude doubleValue]];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Altitude:", nil) value:value]];
        
        // 撮影方向
        value = nil;
        if (gpsInfo && gpsInfo.imageDirection){
            value = [NSString stringWithFormat:@"%.1f° (%@)", [gpsInfo.imageDirection doubleValue], gpsInfo.imageDirectionKind];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Image Direction:", nil) value:value]];
        
        // 速度
        value = nil;
        if (gpsInfo && gpsInfo.heading){
            value = [NSString stringWithFormat:@"%.1f° (%@)", [gpsInfo.heading doubleValue], gpsInfo.headingKind];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Track Direction:", nil) value:value]];
        value = nil;
        if (gpsInfo && gpsInfo.velocity){
            value = [NSString stringWithFormat:@"%.1f %@", [gpsInfo.velocity doubleValue], gpsInfo.velocityUnit];
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Track Speed:", nil) value:value]];

        // 日時
        value = nil;
        if (gpsInfo && gpsInfo.dateTime){
            value = gpsInfo.dateTime;
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"GPS Date Time:", nil) value:value]];
        
        // 測位方法
        value = nil;
        if (gpsInfo && gpsInfo.measureMode){
            value = gpsInfo.measureMode;
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Measure Mode:", nil) value:value]];

        // 地図種別
        value = nil;
        if (gpsInfo && gpsInfo.geodeticReferenceSystem){
            value = gpsInfo.geodeticReferenceSystem;
        }
        [array addObject:[ImageMetadataKV kvWithKey:NSLocalizedString(@"Geodetic Reference System:", nil) value:value]];
    }
    return _gpsInfoStrings;
}

- (NSString*)convertToDegrees:(double)value
{
    double deg, min, sec;
    double mod1 = modf(fabs(value), &deg);
    double mod2 = modf(mod1 * 60, &min);
    sec = mod2 * 60;
    return [NSString stringWithFormat:@"%.0f° %.0f' %.1f\"", deg, min, sec];
}

//-----------------------------------------------------------------------------------------
// 属性辞書返却
//-----------------------------------------------------------------------------------------
- (NSDictionary*)propertiesAtIndex:(int)index
{
    NSDictionary* properties = nil;
    if (index > 0 && index < propertyKindNum){
        properties = _properties[index];
    }
    return properties;
}

@end

//-----------------------------------------------------------------------------------------
// NSArrayController向けKey Value Store
//-----------------------------------------------------------------------------------------
@implementation ImageMetadataKV

+ (id)kvWithKey:(NSString *)key value:(NSString *)value
{
    ImageMetadataKV* kv = [[ImageMetadataKV alloc] init];
    if (kv){
        kv.key = key;
        kv.value = value;
    }
    return kv;
}

@end

//-----------------------------------------------------------------------------------------
// GPS情報ラッパー
//-----------------------------------------------------------------------------------------
@implementation GPSInfo

@end

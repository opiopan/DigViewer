//
//  Condition.m
//  DigViewer
//
//  Created by opiopan on 2015/07/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "Condition.h"
#import "Condition.h"
#import "Lens.h"

@implementation LLMatchingProperties
@end

@implementation Condition

@dynamic conditionType;
@dynamic operatorType;
@dynamic target;
@dynamic valueDouble;
@dynamic valueString;
@dynamic children;
@dynamic lens;
@dynamic parent;

//-----------------------------------------------------------------------------------------
// 自動生成されない属性の実装
//-----------------------------------------------------------------------------------------
- (Condition*)me
{
    return self;
}

- (NSImage*)icon
{
    return self.conditionType.intValue == LFCONDITION_TYPE_COMPARISON ? [NSImage imageNamed:NSImageNameActionTemplate] :
                                                                        [NSImage imageNamed:NSImageNameStatusAvailable];
}

- (NSDictionary *)package
{
    return @{@"name":[self summary], @"icon":[self icon]};
}

//-----------------------------------------------------------------------------------------
// 属性のアップデート
//-----------------------------------------------------------------------------------------
- (void)updateProperties
{
    [self willChangeValueForKey:@"me"];
    [self willChangeValueForKey:@"summary"];
    [self willChangeValueForKey:@"icon"];
    [self willChangeValueForKey:@"package"];
    [self didChangeValueForKey:@"me"];
    [self didChangeValueForKey:@"summary"];
    [self didChangeValueForKey:@"icon"];
    [self didChangeValueForKey:@"package"];
}

//-----------------------------------------------------------------------------------------
// サマリーテキスト生成
//-----------------------------------------------------------------------------------------
- (NSString *)summary
{
    switch (self.conditionType.intValue) {
        case LFCONDITION_TYPE_AND:
            return @"AND";
        case LFCONDITION_TYPE_OR:
            return @"OR";
        case LFCONDITION_TYPE_NAND:
            return @"NAND";
        case LFCONDITION_TYPE_NOR:
            return @"NOR";
        default:
            return [self summaryForComparison];
    }
}

- (NSString*) summaryForComparison
{
    NSString* key = nil;
    switch (self.operatorType.intValue) {
        case LFCONDITION_OP_EQ:
            key = @"LFCONDITION_SUMMARY_EQ";
            break;
        case LFCONDITION_OP_NE:
            key = @"LFCONDITION_SUMMARY_NE";
            break;
        case LFCONDITION_OP_GT:
            key = @"LFCONDITION_SUMMARY_GT";
            break;
        case LFCONDITION_OP_GE:
            key = @"LFCONDITION_SUMMARY_GE";
            break;
        case LFCONDITION_OP_LT:
            key = @"LFCONDITION_SUMMARY_LT";
            break;
        case LFCONDITION_OP_LE:
            key = @"LFCONDITION_SUMMARY_LE";
            break;
        case LFCONDITION_OP_LEFTHAND_MATCH:
            key = @"LFCONDITION_SUMMARY_LEFTHAND_MATCH";
            break;
        case LFCONDITION_OP_RIGHTHAND_MATCH:
            key = @"LFCONDITION_SUMMARY_RIGHTHAND_MATCH";
            break;
        case LFCONDITION_OP_PARTIAL_MATCH:
            key = @"LFCONDITION_SUMMARY_PARTIAL_MATCH";
            break;
        case LFCONDITION_OP_IS_NULL:
            key = @"LFCONDITION_SUMMARY_IS_NULL";
            break;
    }
    NSString* format = NSLocalizedString(key, nil);
    NSString* target = [Condition stringForTarget:self.target.intValue].lowercaseString;
    NSString* value = nil;
    if ([Condition targetIsString:self.target.intValue]){
        value = self.valueString ? [NSString stringWithFormat:@"\"%@\"", self.valueString] : @"\"\"";
    }else{
        value = self.valueDouble ? self.valueDouble.stringValue : @"0";
    }
    
    return [NSString stringWithFormat:format, target, value];
}

//-----------------------------------------------------------------------------------------
// マッチングテスト
//-----------------------------------------------------------------------------------------
- (BOOL)matchConditionWithProperties:(LLMatchingProperties *)properties
{
    if (self.conditionType.intValue == LFCONDITION_TYPE_COMPARISON){
        return [self compareWithProperties:properties];
    }else{
        BOOL rc = NO;
        
        switch (self.conditionType.intValue){
            case LFCONDITION_TYPE_AND:
            case LFCONDITION_TYPE_NAND:
                rc = YES;
                for (Condition* child in self.children){
                    rc = rc && [child matchConditionWithProperties:properties];
                    if (!rc){
                        break;
                    }
                }
                break;
            case LFCONDITION_TYPE_OR:
            case LFCONDITION_TYPE_NOR:
                rc = NO;
                for (Condition* child in self.children){
                    rc = rc || [child matchConditionWithProperties:properties];
                    if (rc){
                        break;
                    }
                }
                break;
        }
        
        switch (self.conditionType.intValue){
            case LFCONDITION_TYPE_NAND:
            case LFCONDITION_TYPE_NOR:
                rc = !rc;
        }
        
        return rc;
    }
}

- (BOOL)compareWithProperties:(LLMatchingProperties*)properties
{
    id value = nil;
    switch (self.target.intValue){
        case LFCONDITION_TARGET_CAMERA_MAKE:
            value = properties.cameraMake;
            break;
        case LFCONDITION_TARGET_CAMERA_NAME:
            value = properties.cameraModel;
            break;
        case LFCONDITION_TARGET_LENS_MAKE:
            value = properties.lensMake;
            break;
        case LFCONDITION_TARGET_LENS_NAME:
            value = properties.lensModel;
            break;
        case LFCONDITION_TARGET_FOCAL_LENGTH:
            value = properties.focalLength;
            break;
        case LFCONDITION_TARGET_FOCAL_LENGTH35:
            value = properties.focalLength35;
            break;
        case LFCONDITION_TARGET_APERTURE:
            value = properties.aperture;
            break;
    }
    
    BOOL rc = NO;
    switch (self.target.intValue){
        case LFCONDITION_TARGET_CAMERA_MAKE:
        case LFCONDITION_TARGET_CAMERA_NAME:
        case LFCONDITION_TARGET_LENS_MAKE:
        case LFCONDITION_TARGET_LENS_NAME:
            switch (self.operatorType.intValue) {
                case LFCONDITION_OP_EQ:
                    rc = value && [value isEqualToString:self.valueString];
                    break;
                case LFCONDITION_OP_NE:
                    rc = value || ![value isEqualToString:self.valueString];
                    break;
                case LFCONDITION_OP_LEFTHAND_MATCH:
                    rc = value && [value hasPrefix:self.valueString];
                    break;
                case LFCONDITION_OP_RIGHTHAND_MATCH:
                    rc = value && [value hasSuffix:self.valueString];
                    break;
                case LFCONDITION_OP_PARTIAL_MATCH:{
                    NSRange initial = {NSNotFound, 0};
                    NSRange range = value ? [((NSString*)value) rangeOfString:self.valueString] : initial;
                    rc = range.location != NSNotFound;
                    break;
                case LFCONDITION_OP_IS_NULL:
                    rc = !value;
                    break;
                }
            }
            break;
        case LFCONDITION_TARGET_FOCAL_LENGTH:
        case LFCONDITION_TARGET_FOCAL_LENGTH35:
        case LFCONDITION_TARGET_APERTURE:
            switch (self.operatorType.intValue) {
                case LFCONDITION_OP_EQ:
                    rc = value && [value doubleValue] == self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_NE:
                    rc = !value || [value doubleValue] != self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_GT:
                    rc = value && [value doubleValue] > self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_GE:
                    rc = value && [value doubleValue] >= self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_LT:
                    rc = value && [value doubleValue] < self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_LE:
                    rc = value && [value doubleValue] <= self.valueDouble.doubleValue;
                    break;
                case LFCONDITION_OP_IS_NULL:
                    rc = !value;
                    break;
            }
            break;
    }
    
    return rc;
}

//-----------------------------------------------------------------------------------------
// ターゲット種別判定
//-----------------------------------------------------------------------------------------
+ (BOOL)targetIsString:(enum LFCONDITION_TARGET)target
{
    return target != LFCONDITION_TARGET_FOCAL_LENGTH &&
           target != LFCONDITION_TARGET_FOCAL_LENGTH35 &&
           target != LFCONDITION_TARGET_APERTURE;

}

//-----------------------------------------------------------------------------------------
// ターゲット、演算子種別の文字列変換
//-----------------------------------------------------------------------------------------
+ (NSString*)stringForTarget:(enum LFCONDITION_TARGET)target
{
    NSString* key = nil;
    switch (target) {
        case LFCONDITION_TARGET_CAMERA_MAKE:
            key = @"LFCONDITION_TARGET_CAMERA_MAKE";
            break;
        case LFCONDITION_TARGET_CAMERA_NAME:
            key = @"LFCONDITION_TARGET_CAMERA_NAME";
            break;
        case LFCONDITION_TARGET_LENS_MAKE:
            key = @"LFCONDITION_TARGET_LENS_MAKE";
            break;
        case LFCONDITION_TARGET_LENS_NAME:
            key = @"LFCONDITION_TARGET_LENS_NAME";
            break;
        case LFCONDITION_TARGET_FOCAL_LENGTH:
            key = @"LFCONDITION_TARGET_FOCAL_LENGTH";
            break;
        case LFCONDITION_TARGET_FOCAL_LENGTH35:
            key = @"LFCONDITION_TARGET_FOCAL_LENGTH35";
            break;
        case LFCONDITION_TARGET_APERTURE:
            key = @"LFCONDITION_TARGET_APERTURE";
            break;
    }
    return NSLocalizedString(key, nil);
}

+ (NSString*)stringForOperator:(enum LFCONDITION_OP)op
{
    NSString* key = nil;
    switch (op) {
        case LFCONDITION_OP_EQ:
            key = @"LFCONDITION_OP_EQ";
            break;
        case LFCONDITION_OP_NE:
            key = @"LFCONDITION_OP_NE";
            break;
        case LFCONDITION_OP_GT:
            key = @"LFCONDITION_OP_GT";
            break;
        case LFCONDITION_OP_GE:
            key = @"LFCONDITION_OP_GE";
            break;
        case LFCONDITION_OP_LT:
            key = @"LFCONDITION_OP_LT";
            break;
        case LFCONDITION_OP_LE:
            key = @"LFCONDITION_OP_LE";
            break;
        case LFCONDITION_OP_LEFTHAND_MATCH:
            key = @"LFCONDITION_OP_LEFTHAND_MATCH";
            break;
        case LFCONDITION_OP_RIGHTHAND_MATCH:
            key = @"LFCONDITION_OP_RIGHTHAND_MATCH";
            break;
        case LFCONDITION_OP_PARTIAL_MATCH:
            key = @"LFCONDITION_OP_PARTIAL_MATCH";
            break;
        case LFCONDITION_OP_IS_NULL:
            key = @"LFCONDITION_OP_IS_NULL";
            break;
    }
    return NSLocalizedString(key, nil);
}

@end

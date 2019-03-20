//
//  NSString+Emojize.m
//  Field Recorder
//
//  Created by Jonathan Beilin on 11/5/12.
//  Copyright (c) 2014 DIY. All rights reserved.
//

#import "NSString+Emojize.h"
#import "emojis.h"

@implementation NSString (Emojize)

- (NSDictionary *)emojizedString
{
    return [NSString emojizedStringWithString:self];
}

+ (NSDictionary *)emojizedStringWithString:(NSString *)text
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    static dispatch_once_t dDetector = 0;
    static NSDataDetector *urlDetector = nil;
    NSMutableArray *matchingRanges = [NSMutableArray new];
    NSMutableArray *matchingLengthChanges = [NSMutableArray new];
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"(:[a-z0-9-+_]+:)" options:NSRegularExpressionCaseInsensitive error:NULL];
    });
    
    dispatch_once(&dDetector, ^{
        urlDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
    });
    __block NSString *resultText = text;
    NSRange matchingRange = NSMakeRange(0, [resultText length]);
    NSArray<NSTextCheckingResult *> *urlMatches = [urlDetector matchesInString:text options:NSMatchingReportCompletion range:matchingRange];
    [regex enumerateMatchesInString:resultText options:NSMatchingReportCompletion range:matchingRange usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if ( result &&
            ([result resultType] == NSTextCheckingTypeRegularExpression) &&
            !(flags & NSMatchingInternalError) ) {
            
            NSRange range = result.range;
            if (range.location != NSNotFound) {
                NSRange intersectionRange = NSMakeRange(0, 0);
                for (NSTextCheckingResult *urlMatch in urlMatches) {
                    intersectionRange = NSIntersectionRange(urlMatch.range, range);
                    if (intersectionRange.length <= 0) {
                        break;
                    }
                }
                NSString *code = [text substringWithRange:range];
                NSString *unicode = self.emojiAliases[code];
                if (unicode && !intersectionRange.length > 0) {
                    resultText = [resultText stringByReplacingOccurrencesOfString:code withString:unicode];
                    [matchingRanges addObject:[NSValue valueWithRange: range]];
                    //range.length with be the number of characters reduced
                    range.length -= [unicode length];
                    [matchingLengthChanges addObject:[NSValue valueWithRange: range]];
                }
            }
        }
    }];
    
    return @{@"emojizedString" : resultText, @"emojiRanges" : matchingRanges, @"emojiLengthChanges" : matchingLengthChanges};
}

+ (NSDictionary *)emojiAliases {
    static NSDictionary *_emojiAliases;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _emojiAliases = EMOJI_HASH;
    });
    return _emojiAliases;
}

@end

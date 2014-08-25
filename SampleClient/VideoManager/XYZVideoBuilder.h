#import <Foundation/Foundation.h>

@interface XYZVideoBuilder : NSObject

+ (NSArray *)videosFromJSON:(NSData *)objectNotation error:(NSError **)error;

+ (NSArray *)singleVideoFromJSON:(NSData *)objectNotation error:(NSError **)error;

@end
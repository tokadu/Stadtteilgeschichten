#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface XYZVideo : NSObject

@property NSString *videoId;
@property NSString *title;
@property NSString *qrTag;
@property NSString *formattedAddress;
@property NSString *latitude;
@property NSString *longitude;
@property NSString *length;
@property NSString *playbackUrl;
@property NSString *videoDescription;
@property NSString *thumbnailUrl;
@property NSString *resolution;
@property NSArray *relatedVideos;

@end

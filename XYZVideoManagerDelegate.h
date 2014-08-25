#import <Foundation/Foundation.h>

@protocol XYZVideoManagerDelegate

@required
- (void)operationFailedWithError:(NSError *)error;

@optional
- (void)didReceiveVideos:(id)videos;
- (void)uploadCompleted;
- (void)didReceiveEncodingTypes:(NSArray *)encodingTypes;
@end
//
//  BrightCoveVideoUploadOperation.h
//
//  Created by Cory Hymel on 2/6/14.
//  Copyright (c) 2014 Simble. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Your BrightCove API key goes here.
 */
#define kBrightCoveWriteAPIKey @""

/**
 A simple NSOperation for uploading a local video to BrightCove. This operation works independent of their SDK.
 */
@interface SBBrightCoveVideoUploadOperation : NSOperation

/**
 Initilize the operation with a video item URL and file extension.
 
 @param videoURL The NSURL to the local video you want to upload to BrightCove. 
 @param fileExtension The file extension for the local video. Do not include "." in it. Simply pass in "m4v" or "mov". DO NOT pass in ".m4v".

 @return self
 */
- (id)initWithLocalVideoWithURL:(NSURL*)videoURL fileExtenstion:(NSString*)fileExtension;


/**
 The name of the video. Do not inlude a file extension in this.
 
 @note Optional. If this is not set, the video name will be set as, "MMddyyyyHHmm" using the current `NSDate` for reference.
 */
@property NSString *videoName;


/**
 The video description. 
 
 @note Optional. If not set, the video description will be set as "Created at: MMddyyyyHHmm" using the current `NSDate` for reference.
 */
@property NSString *videoDescription;


/**
 Completion block called once the upload operation has been completed.
 
 @param success If the operation was successful or not
 @param errorDisplayString As opposed to an NSError, this is pretty formatted string to display to the user
 
 @note Optional.
 */
@property (copy)void(^completion)(BOOL success, NSString *errorDisplayString);

@end

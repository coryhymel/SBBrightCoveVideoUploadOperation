SBBrightCoveVideoUploadOperation
================================

A simple NSOperation subclass for uploading video to BrightCove independent of their SDK. 


## Initialization 
Initialize with a NSURL to a local video file along with an extension. Do not include "." in it. Simply pass in "m4v" or "mov". DO NOT pass in ".m4v".
`- (id)initWithLocalVideoWithURL:(NSURL*)videoURL fileExtenstion:(NSString*)fileExtension`


## Optional Properties
 You can optionally set the video name. If you do not explicitly set the video name, it will be generated using the current `NSDate` in the format of `MMddyyyyHHmm`.
`@property NSString *videoName`


 You can optionally set the video description. If you do not explicitly set the video description, it will be generated using the current `NSDate` in the format of: "Created at: `MMddyyyyHHmm`".
`@property NSString *videoDescription`


 A completion block that is called when the operation is complete or if an error occurred. The `errorDisplayString` is a human readable string describing the error that occurred. 
`@property (copy)void(^completion)(BOOL success, NSString *errorDisplayString)`
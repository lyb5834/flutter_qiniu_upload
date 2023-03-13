#import "FlutterQiniuUploadPlugin.h"
#import "QiniuSDK.h"

@interface FlutterQiniuUploadPlugin ()
<
FlutterStreamHandler
>
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) QNUploadManager * uploadManager;
@property (nonatomic, assign) BOOL isCancel;

@end

@implementation FlutterQiniuUploadPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_qiniu_upload"
            binaryMessenger:[registrar messenger]];
  FlutterEventChannel* changingChannel = [FlutterEventChannel eventChannelWithName:@"flutter_qiniu_upload/event" binaryMessenger: [registrar messenger]];
  FlutterQiniuUploadPlugin* instance = [[FlutterQiniuUploadPlugin alloc] init];
  [changingChannel setStreamHandler:instance];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"init" isEqualToString:call.method]) {
      NSString * fixedZone = call.arguments[@"fixedZone"];
      NSString * recorderPath = call.arguments[@"recorderPath"];
      NSLog(@"fixedZone = %@ | recorderPath = %@",fixedZone, recorderPath);
      QNConfiguration *config = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
          if (fixedZone != nil && fixedZone.length > 0) {
              builder.zone = [QNFixedZone createWithHost:@[fixedZone]];
          }
          if (recorderPath != nil && recorderPath.length > 0) {
              //设置断点续传
              NSError *error;
              builder.recorder = [QNFileRecorder fileRecorderWithFolder:recorderPath error:&error];
          }
      }];
      _uploadManager = [[QNUploadManager alloc] initWithConfiguration:config];
      result(@(YES));
  } else if ([@"cancel" isEqualToString:call.method]) {
      self.isCancel = [call.arguments boolValue];
  } else if ([@"upload" isEqualToString:call.method]) {
      NSDictionary * arguments = call.arguments;
      NSString * filePath = arguments[@"filePath"];
      NSString * token = arguments[@"token"];
      NSString * key = arguments[@"key"];
      
      NSDictionary * params = [arguments.allKeys containsObject:@"params"] ? arguments[@"params"] : nil;
      NSString * mimeType = [arguments.allKeys containsObject:@"mimeType"] ? arguments[@"mimeType"] : nil;
      BOOL checkCrc = [arguments.allKeys containsObject:@"checkCrc"] ? [arguments[@"checkCrc"] boolValue] : NO;
      
      __weak typeof(self) weakSelf = self;
      QNUploadOption *uploadOption = [[QNUploadOption alloc]initWithMime:mimeType progressHandler:^(NSString *key, float percent) {
          
          __strong typeof(weakSelf)self = weakSelf;
          NSDictionary * backDic = @{@"key" : key, @"percent" : [NSString stringWithFormat:@"%.2f",percent]};
          if (self.eventSink) {
              self.eventSink(@{@"type" : @"percent" , @"data" : backDic});
          }
          
      } params:params checkCrc:checkCrc cancellationSignal:^BOOL{
//          if (self.eventSink) {
//              self.eventSink(@{@"type" : @"cancel"});
//          }
          return self.isCancel;
      }];
      
      [self.uploadManager putFile:filePath key:key token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
          if (info.isOK) {
              NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resp options:NSJSONWritingPrettyPrinted error:nil];
              NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
              result(jsonString);
          } else {
              result([FlutterError errorWithCode:[NSString stringWithFormat:@"%d",info.statusCode] message:info.message details:info.message]);
          }
      } option:uploadOption];
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark - FlutterStreamHandler


- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    if (self.eventSink == nil) {
        self.eventSink = events;
    }
    return nil;
}

@end

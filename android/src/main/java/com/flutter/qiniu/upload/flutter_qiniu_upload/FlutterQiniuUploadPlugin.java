package com.flutter.qiniu.upload.flutter_qiniu_upload;

import static com.qiniu.android.storage.Configuration.RESUME_UPLOAD_VERSION_V1;

import androidx.annotation.NonNull;

import com.qiniu.android.common.FixedZone;
import com.qiniu.android.http.ResponseInfo;
import com.qiniu.android.storage.Configuration;
import com.qiniu.android.storage.FileRecorder;
import com.qiniu.android.storage.UpCancellationSignal;
import com.qiniu.android.storage.UpCompletionHandler;
import com.qiniu.android.storage.UpProgressBytesHandler;
import com.qiniu.android.storage.UploadManager;
import com.qiniu.android.storage.UploadOptions;
import com.qiniu.android.utils.Json;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FlutterQiniuUploadPlugin */
public class FlutterQiniuUploadPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private MethodChannel channel;
  private EventChannel eventChannel;
  private EventChannel.EventSink eventSink;
  private UploadManager mUploadManager;
  private boolean isCancel = false;
  private final String TAG = "QiNiu";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_qiniu_upload");
    channel.setMethodCallHandler(this);
    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_qiniu_upload/event");
    eventChannel.setStreamHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("init")) {
      if (call.arguments instanceof Map) {
        Map<String, Object> map = (Map) call.arguments;
        String fixedZone = map.containsKey("fixedZone") ? map.get("fixedZone").toString() : "";
        String recorderPath = map.containsKey("recorderPath") ? map.get("recorderPath").toString() : "";
        Log.d(TAG,"fixedZone = " + fixedZone + "|" + " recorderPath = " + recorderPath);
        FixedZone zone = null;
        if (!fixedZone.isEmpty()) {
           zone = new FixedZone(new String[]{fixedZone});
        }
        FileRecorder recorder = null;
        try {
          recorder = new FileRecorder(recorderPath);
        } catch (IOException e) {
          e.printStackTrace();
        }

        Configuration config = new Configuration.Builder()
                .recorder(recorder)
                .zone(zone)
                .build();
        if (mUploadManager == null) {
          mUploadManager = new UploadManager(config);
        }
      }
      result.success(true);
    } else if (call.method.equals("cancel")) {
      if (call.arguments instanceof Boolean) {
        isCancel = (boolean)call.arguments;
      }
      result.success(true);
    } else if (call.method.equals("upload")) {
      if (call.arguments instanceof Map) {
        Map<String, Object> map = (Map) call.arguments;
        Log.d(TAG,"upload params = " + map);
        String filePath = map.get("filePath").toString();
        String token = map.get("token").toString();
        String key = map.get("key").toString();

        Map<String, String> params = new HashMap<>();
        String mimeType = null;
        boolean checkCrc = false;

        if (map.containsKey("params")) {
          params = (Map<String, String>) map.get("params");
        }
        if (map.containsKey("mimeType")) {
          mimeType = map.get("mimeType").toString();
        }
        if (map.containsKey("checkCrc")) {
          checkCrc = (boolean) map.get("checkCrc");
        }

        UploadOptions options = new UploadOptions(params, mimeType, checkCrc, (mKey, percent) -> {
          Log.d(TAG, "percent = " + percent);
          HashMap<String, Object> eventBack = new HashMap<>();
          HashMap<String, String> dataMap = new HashMap<>();
          dataMap.put("key" , mKey);
          dataMap.put("percent", String.valueOf(percent));
          eventBack.put("type" , "percent");
          eventBack.put("data" , dataMap);
          if (eventSink != null) {
            eventSink.success(eventBack);
          }
        }, () -> {
//          HashMap<String, Object> eventBack = new HashMap<>();
//          eventBack.put("type" , "cancel");
//          if (eventSink != null) {
//            eventSink.success(eventBack);
//          }
          return isCancel;
        });

        if (mUploadManager != null) {
          mUploadManager.put(filePath, key, token, (mKey, info, response) -> {
            if (info.isOK()) {
              try {
                String jsonString = response.toString();
                Log.d(TAG, jsonString);
                result.success(jsonString);
              } catch (Exception error) {
                Log.e(TAG, error.getMessage());
                result.error(String.valueOf(info.statusCode), info.message, info.message);
              }
            } else {
              Log.e(TAG, "七牛上传失败: " + info.error);
              result.error(String.valueOf(info.statusCode), info.error, info.error);
            }
          }, options);
        }
      }
    }
    else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
    if (eventSink == null) {
      eventSink = events;
    }
  }

  @Override
  public void onCancel(Object arguments) {
    eventSink = null;
  }
}

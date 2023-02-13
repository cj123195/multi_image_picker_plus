package com.tianxin.multi_image_picker_plus

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.text.TextUtils
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import com.sangcomz.fishbun.FishBun
import com.sangcomz.fishbun.FishBunCreator
import com.sangcomz.fishbun.adapter.image.impl.GlideAdapter
import com.sangcomz.fishbun.define.Define

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.nio.ByteBuffer
import java.util.*
import kotlin.math.abs

/** MultiImagePickerPlusPlugin */
class MultiImagePickerPlusPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private var channel: MethodChannel? = null
  private var activity: Activity? = null
  private val channelName = "multi_image_picker_plus"
  private val requestThumbnail = "requestThumbnail"
  private val requestOriginal = "requestOriginal"
  private val requestMetadata = "requestMetadata"
  private val pickImages = "pickImages"
  private val selectedAssets = "selectedAssets"
  private val androidOptions = "androidOptions"
  private val requestCodeChoose = 1001
  private var context: Context? = null
  private var messenger: BinaryMessenger? = null
  private var pendingResult: Result? = null
  private var methodCall: MethodCall? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    messenger = flutterPluginBinding.binaryMessenger

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, channelName)
    channel!!.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (!setPendingMethodCallAndResult(call, result)) {
      finishWithAlreadyActiveError(result)
      return
    }

    if (pickImages == call.method) {
      val options =
        call.argument<HashMap<String, String>>(androidOptions)!!
      val selectedAssets =
        methodCall!!.argument<ArrayList<String>>(selectedAssets)!!
      presentPicker(selectedAssets, options)
    } else if (requestOriginal == call.method) {
      val identifier = call.argument<String>("identifier")
      val quality = call.argument<Any>("quality") as Int
      if (!this.uriExists(identifier!!)) {
        finishWithError("ASSET_DOES_NOT_EXIST", "The requested image does not exist.")
      } else {
        val scope = CoroutineScope(Dispatchers.Main)
        scope.launch(Dispatchers.Main) {
          val buffer = getImage(identifier, quality)
          if (buffer != null) {
            messenger?.send("multi_image_picker_plus/image/$identifier.original", buffer)
            buffer.clear()
          }
          finishWithSuccess()
        }
      }
    } else if (requestThumbnail == call.method) {
      val identifier = call.argument<String>("identifier")
//            val width = call.argument<Any>("width") as Int
//            val height = call.argument<Any>("height") as Int
      val quality = call.argument<Any>("quality") as Int
      if (!this.uriExists(identifier!!)) {
        finishWithError("ASSET_DOES_NOT_EXIST", "The requested image does not exist.")
      } else {
        val scope = CoroutineScope(Dispatchers.Main)
        scope.launch(Dispatchers.Main) {
          val buffer = getThumbnail(identifier, quality)
          if (buffer != null) {
            messenger!!.send("multi_image_picker_plus/image/$identifier.thumb", buffer)
            buffer.clear()
            finishWithSuccess()
          }
        }
        finishWithSuccess()
      }
    } else if (requestMetadata == call.method) {
      val identifier = call.argument<String>("identifier")
      var uri = Uri.parse(identifier)

      // Scoped storage related code. We can only get gps location if we ask for original image
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        uri = MediaStore.setRequireOriginal(uri!!)
      }
      try {
        val `in` = context!!.contentResolver.openInputStream(uri!!)!!
        val exifInterface = ExifInterface(`in`)
        finishWithSuccess(getPictureExif(exifInterface, uri))
      } catch (e: IOException) {
        finishWithError("Exif error", e.toString())
      }
    } else {
      pendingResult!!.notImplemented()
      clearMethodCallAndResult()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel!!.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    binding.addActivityResultListener(this)
    activity = binding.activity
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == requestCodeChoose && resultCode == Activity.RESULT_CANCELED) {
      finishWithError("CANCELLED", "The user has cancelled the selection")
    } else if (requestCode == requestCodeChoose && resultCode == Activity.RESULT_OK) {
      val photos: List<Uri>? = data!!.getParcelableArrayListExtra(Define.INTENT_PATH)
      if (photos == null) {
        clearMethodCallAndResult()
        return false
      }
      val result: MutableList<HashMap<String, Any?>?> = ArrayList(photos.size)
      for (uri in photos) {
        val map = HashMap<String, Any?>()
        map["identifier"] = uri.toString()
        var `is`: InputStream?
        var width = 0
        var height = 0
        try {
          `is` = context!!.contentResolver.openInputStream(uri)
          val dbo = BitmapFactory.Options()
          dbo.inJustDecodeBounds = true
          dbo.inScaled = false
          dbo.inSampleSize = 1
          BitmapFactory.decodeStream(`is`, null, dbo)
          `is`?.close()
          val orientation: Int = getOrientation(context!!, uri)
          if (orientation == 90 || orientation == 270) {
            width = dbo.outHeight
            height = dbo.outWidth
          } else {
            width = dbo.outWidth
            height = dbo.outHeight
          }
        } catch (e: IOException) {
          e.printStackTrace()
        }
        map["width"] = width
        map["height"] = height
        map["name"] = getFileName(uri)
        result.add(map)
      }
      finishWithSuccess(result)
      return true
    } else {
      finishWithSuccess(emptyList<Any>())
      clearMethodCallAndResult()
    }
    return false
  }

  override fun onDetachedFromActivityForConfigChanges() {
    context = null
    if (channel != null) {
      channel!!.setMethodCallHandler(null)
      channel = null
    }
    messenger = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    binding.addActivityResultListener(this)
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  private fun getCorrectlyOrientedImage(context: Context, photoUri: Uri): Bitmap? {
    var `is` = context.contentResolver.openInputStream(photoUri)
    val dbo = BitmapFactory.Options()
    dbo.inScaled = false
    dbo.inSampleSize = 1
    dbo.inJustDecodeBounds = true
    BitmapFactory.decodeStream(`is`, null, dbo)
    `is`?.close()
    val orientation: Int = getOrientation(context, photoUri)
    var srcBitmap: Bitmap
    `is` = context.contentResolver.openInputStream(photoUri)
    srcBitmap = BitmapFactory.decodeStream(`is`)
    `is`?.close()
    if (orientation > 0) {
      val matrix = Matrix()
      matrix.postRotate(orientation.toFloat())
      srcBitmap = Bitmap.createBitmap(
        srcBitmap, 0, 0, srcBitmap.width,
        srcBitmap.height, matrix, true
      )
    }
    return srcBitmap
  }

  private fun getOrientation(context: Context, photoUri: Uri): Int {
    var rotationDegrees = 0
    try {
      val `in` = context.contentResolver.openInputStream(photoUri)!!
      val exifInterface = ExifInterface(
        `in`
      )
      when (exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)) {
        ExifInterface.ORIENTATION_ROTATE_90 -> rotationDegrees = 90
        ExifInterface.ORIENTATION_ROTATE_180 -> rotationDegrees = 180
        ExifInterface.ORIENTATION_ROTATE_270 -> rotationDegrees = 270
      }
    } catch (ignored: Exception) {
    }
    return rotationDegrees
  }

  private suspend fun getImage(
    identifier: String,
    quality: Int
  ): ByteBuffer? = withContext(Dispatchers.IO) {
    val uri = Uri.parse(identifier)
    var bytesArray: ByteArray? = null
    try {
      if (activity == null || activity!!.isFinishing) return@withContext null
      val bitmap: Bitmap =
        getCorrectlyOrientedImage(activity!!, uri)
          ?: return@withContext null
      val bitmapStream = ByteArrayOutputStream()
      bitmap.compress(Bitmap.CompressFormat.JPEG, quality, bitmapStream)
      bytesArray = bitmapStream.toByteArray()
      bitmap.recycle()
    } catch (e: IOException) {
      e.printStackTrace()
    }
    assert(bytesArray != null)
    if (bytesArray == null) {
      return@withContext null
    }
    val buffer = ByteBuffer.allocateDirect(bytesArray.size)
    buffer.put(bytesArray)
    return@withContext buffer
  }

  private suspend fun getThumbnail(
    identifier: String,
    quality: Int
  ): ByteBuffer? = withContext(Dispatchers.IO) {
    val uri = Uri.parse(identifier)
    var bytesArray: ByteArray? = null
    try {
      if (activity == null || activity!!.isFinishing) return@withContext null
      val bitmap: Bitmap =
        getCorrectlyOrientedImage(activity!!, uri)
          ?: return@withContext null
      val bitmapStream = ByteArrayOutputStream()
      bitmap.compress(Bitmap.CompressFormat.JPEG, quality, bitmapStream)
      bytesArray = bitmapStream.toByteArray()
      bitmap.recycle()
    } catch (e: IOException) {
      e.printStackTrace()
    }
    assert(bytesArray != null)
    if (bytesArray == null) {
      return@withContext null
    }
    val buffer = ByteBuffer.allocateDirect(bytesArray.size)
    buffer.put(bytesArray)
    return@withContext buffer
  }

  private fun getPictureExif(
    exifInterface: ExifInterface,
    uri: Uri?
  ): HashMap<String, Any?> {
    val result = HashMap<String, Any?>()

    // API LEVEL 24
    val tagsStr = arrayOf(
      ExifInterface.TAG_DATETIME,
      ExifInterface.TAG_GPS_DATESTAMP,
      ExifInterface.TAG_GPS_LATITUDE_REF,
      ExifInterface.TAG_GPS_LONGITUDE_REF,
      ExifInterface.TAG_GPS_PROCESSING_METHOD,
      ExifInterface.TAG_IMAGE_WIDTH,
      ExifInterface.TAG_IMAGE_LENGTH,
      ExifInterface.TAG_MAKE,
      ExifInterface.TAG_MODEL
    )
    val tagsDouble = arrayOf(
      ExifInterface.TAG_APERTURE_VALUE,
      ExifInterface.TAG_FLASH,
      ExifInterface.TAG_FOCAL_LENGTH,
      ExifInterface.TAG_GPS_ALTITUDE,
      ExifInterface.TAG_GPS_ALTITUDE_REF,
      ExifInterface.TAG_GPS_LONGITUDE,
      ExifInterface.TAG_GPS_LATITUDE,
      ExifInterface.TAG_IMAGE_LENGTH,
      ExifInterface.TAG_IMAGE_WIDTH,
      ExifInterface.TAG_ISO_SPEED,
      ExifInterface.TAG_ORIENTATION,
      ExifInterface.TAG_WHITE_BALANCE,
      ExifInterface.TAG_EXPOSURE_TIME
    )
    val exifStr: HashMap<String, Any?> = getExifStr(exifInterface, tagsStr)
    result.putAll(exifStr)
    val exifDouble: HashMap<String, Any> = getExifDouble(exifInterface, tagsDouble)
    result.putAll(exifDouble)

    // A Temp fix while location data is not returned from the exifInterface due to the errors. It also
    // covers Android >= 10 not loading GPS information from getExifDouble
    if (exifDouble.isEmpty()
      || !exifDouble.containsKey(ExifInterface.TAG_GPS_LATITUDE)
      || !exifDouble.containsKey(ExifInterface.TAG_GPS_LONGITUDE)
    ) {
      if (uri != null) {
        val hotfixMap: HashMap<String, Any> =
          if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) getLatLng(uri) else getLatLng(
            exifInterface,
          )
        result.putAll(hotfixMap)
      }
    }
    if (Build.VERSION.SDK_INT == Build.VERSION_CODES.M) {
      val tags23 = arrayOf(
        ExifInterface.TAG_DATETIME_DIGITIZED,
        ExifInterface.TAG_SUBSEC_TIME,
        ExifInterface.TAG_SUBSEC_TIME_DIGITIZED,
        ExifInterface.TAG_SUBSEC_TIME_ORIGINAL
      )
      val exif23: HashMap<String, Any?> = getExifStr(exifInterface, tags23)
      result.putAll(exif23)
    }
    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.M) {
      val tags24Str = arrayOf(
        ExifInterface.TAG_ARTIST,
        ExifInterface.TAG_CFA_PATTERN,
        ExifInterface.TAG_COMPONENTS_CONFIGURATION,
        ExifInterface.TAG_COPYRIGHT,
        ExifInterface.TAG_DATETIME_ORIGINAL,
        ExifInterface.TAG_DEVICE_SETTING_DESCRIPTION,
        ExifInterface.TAG_EXIF_VERSION,
        ExifInterface.TAG_FILE_SOURCE,
        ExifInterface.TAG_FLASHPIX_VERSION,
        ExifInterface.TAG_GPS_AREA_INFORMATION,
        ExifInterface.TAG_GPS_DEST_BEARING_REF,
        ExifInterface.TAG_GPS_DEST_DISTANCE_REF,
        ExifInterface.TAG_GPS_DEST_LATITUDE_REF,
        ExifInterface.TAG_GPS_DEST_LONGITUDE_REF,
        ExifInterface.TAG_GPS_IMG_DIRECTION_REF,
        ExifInterface.TAG_GPS_MAP_DATUM,
        ExifInterface.TAG_GPS_MEASURE_MODE,
        ExifInterface.TAG_GPS_SATELLITES,
        ExifInterface.TAG_GPS_SPEED_REF,
        ExifInterface.TAG_GPS_STATUS,
        ExifInterface.TAG_GPS_TRACK_REF,
        ExifInterface.TAG_GPS_VERSION_ID,
        ExifInterface.TAG_IMAGE_DESCRIPTION,
        ExifInterface.TAG_IMAGE_UNIQUE_ID,
        ExifInterface.TAG_INTEROPERABILITY_INDEX,
        ExifInterface.TAG_MAKER_NOTE,
        ExifInterface.TAG_OECF,
        ExifInterface.TAG_RELATED_SOUND_FILE,
        ExifInterface.TAG_SCENE_TYPE,
        ExifInterface.TAG_SOFTWARE,
        ExifInterface.TAG_SPATIAL_FREQUENCY_RESPONSE,
        ExifInterface.TAG_SPECTRAL_SENSITIVITY,
        ExifInterface.TAG_SUBSEC_TIME_DIGITIZED,
        ExifInterface.TAG_SUBSEC_TIME_ORIGINAL,
        ExifInterface.TAG_USER_COMMENT
      )
      val tags24Double = arrayOf(
        ExifInterface.TAG_APERTURE_VALUE,
        ExifInterface.TAG_BITS_PER_SAMPLE,
        ExifInterface.TAG_BRIGHTNESS_VALUE,
        ExifInterface.TAG_COLOR_SPACE,
        ExifInterface.TAG_COMPRESSED_BITS_PER_PIXEL,
        ExifInterface.TAG_COMPRESSION,
        ExifInterface.TAG_CONTRAST,
        ExifInterface.TAG_CUSTOM_RENDERED,
        ExifInterface.TAG_DIGITAL_ZOOM_RATIO,
        ExifInterface.TAG_EXPOSURE_BIAS_VALUE,
        ExifInterface.TAG_EXPOSURE_INDEX,
        ExifInterface.TAG_EXPOSURE_MODE,
        ExifInterface.TAG_EXPOSURE_PROGRAM,
        ExifInterface.TAG_FLASH_ENERGY,
        ExifInterface.TAG_FOCAL_LENGTH_IN_35MM_FILM,
        ExifInterface.TAG_FOCAL_PLANE_RESOLUTION_UNIT,
        ExifInterface.TAG_FOCAL_PLANE_X_RESOLUTION,
        ExifInterface.TAG_FOCAL_PLANE_Y_RESOLUTION,
        ExifInterface.TAG_F_NUMBER,
        ExifInterface.TAG_GAIN_CONTROL,
        ExifInterface.TAG_GPS_DEST_BEARING,
        ExifInterface.TAG_GPS_DEST_DISTANCE,
        ExifInterface.TAG_GPS_DEST_LATITUDE,
        ExifInterface.TAG_GPS_DEST_LONGITUDE,
        ExifInterface.TAG_GPS_DIFFERENTIAL,
        ExifInterface.TAG_GPS_DOP,
        ExifInterface.TAG_GPS_IMG_DIRECTION,
        ExifInterface.TAG_GPS_SPEED,
        ExifInterface.TAG_GPS_TRACK,
        ExifInterface.TAG_JPEG_INTERCHANGE_FORMAT,
        ExifInterface.TAG_JPEG_INTERCHANGE_FORMAT_LENGTH,
        ExifInterface.TAG_LIGHT_SOURCE,
        ExifInterface.TAG_MAX_APERTURE_VALUE,
        ExifInterface.TAG_METERING_MODE,
        ExifInterface.TAG_PHOTOMETRIC_INTERPRETATION,
        ExifInterface.TAG_PIXEL_X_DIMENSION,
        ExifInterface.TAG_PIXEL_Y_DIMENSION,
        ExifInterface.TAG_PLANAR_CONFIGURATION,
        ExifInterface.TAG_PRIMARY_CHROMATICITIES,
        ExifInterface.TAG_REFERENCE_BLACK_WHITE,
        ExifInterface.TAG_RESOLUTION_UNIT,
        ExifInterface.TAG_ROWS_PER_STRIP,
        ExifInterface.TAG_SAMPLES_PER_PIXEL,
        ExifInterface.TAG_SATURATION,
        ExifInterface.TAG_SCENE_CAPTURE_TYPE,
        ExifInterface.TAG_SENSING_METHOD,
        ExifInterface.TAG_SHARPNESS,
        ExifInterface.TAG_SHUTTER_SPEED_VALUE,
        ExifInterface.TAG_STRIP_BYTE_COUNTS,
        ExifInterface.TAG_STRIP_OFFSETS,
        ExifInterface.TAG_SUBJECT_AREA,
        ExifInterface.TAG_SUBJECT_DISTANCE,
        ExifInterface.TAG_SUBJECT_DISTANCE_RANGE,
        ExifInterface.TAG_SUBJECT_LOCATION,
        ExifInterface.TAG_THUMBNAIL_IMAGE_LENGTH,
        ExifInterface.TAG_THUMBNAIL_IMAGE_WIDTH,
        ExifInterface.TAG_TRANSFER_FUNCTION,
        ExifInterface.TAG_WHITE_POINT,
        ExifInterface.TAG_X_RESOLUTION,
        ExifInterface.TAG_Y_CB_CR_COEFFICIENTS,
        ExifInterface.TAG_Y_CB_CR_POSITIONING,
        ExifInterface.TAG_Y_CB_CR_SUB_SAMPLING,
        ExifInterface.TAG_Y_RESOLUTION
      )
      val exif24Str: HashMap<String, Any?> = getExifStr(exifInterface, tags24Str)
      result.putAll(exif24Str)
      val exif24Double: HashMap<String, Any> =
        getExifDouble(exifInterface, tags24Double)
      result.putAll(exif24Double)
    }
    return result
  }

  private fun getExifStr(
    exifInterface: ExifInterface,
    tags: Array<String>
  ): HashMap<String, Any?> {
    val result = HashMap<String, Any?>()
    for (tag in tags) {
      val attribute = exifInterface.getAttribute(tag)
      if (!TextUtils.isEmpty(attribute)) {
        result[tag] = attribute
      }
    }
    return result
  }

  private fun getExifDouble(
    exifInterface: ExifInterface,
    tags: Array<String>
  ): HashMap<String, Any> {
    val result = HashMap<String, Any>()
    for (tag in tags) {
      val attribute = exifInterface.getAttributeDouble(tag, 0.0)
      if (attribute != 0.0) {
        result[tag] = attribute
      }
    }
    return result
  }

  private fun uriExists(identifier: String): Boolean {
    val uri = Uri.parse(identifier)
    val fileName: String? = this.getFileName(uri)
    return fileName != null
  }

  private fun getLatLng(exifInterface: ExifInterface): HashMap<String, Any> {
    val result = HashMap<String, Any>()
    val latLong = exifInterface.latLong
    if (latLong != null && latLong.size == 2) {
      result[ExifInterface.TAG_GPS_LATITUDE] = abs(
        latLong[0]
      )
      result[ExifInterface.TAG_GPS_LONGITUDE] = abs(
        latLong[1]
      )
    }
    return result
  }

  private fun getLatLng(uri: Uri): HashMap<String, Any> {
    val result = HashMap<String, Any>()
    val latitudeStr = "latitude"
    val longitudeStr = "longitude"
    val latLngList = listOf(latitudeStr, longitudeStr)
    val indexNotPresent = -1
    val uriScheme = uri.scheme ?: return result
    if (uriScheme == "content") {
      val cursor =
        context!!.contentResolver.query(uri, null, null, null, null) ?: return result
      try {
        val columnNames = cursor.columnNames
        val columnNamesList = listOf(*columnNames)
        for (lngStr in latLngList) {
          cursor.moveToFirst()
          val index = columnNamesList.indexOf(lngStr)
          if (index > indexNotPresent) {
            val `val` = cursor.getDouble(index)
            // Inserting it as abs as it is the ref the define if the value should be negative or positive
            if (lngStr == latitudeStr) {
              result[ExifInterface.TAG_GPS_LATITUDE] = abs(`val`)
            } else {
              result[ExifInterface.TAG_GPS_LONGITUDE] = abs(`val`)
            }
          }
        }
      } catch (e: NullPointerException) {
        e.printStackTrace()
      } finally {
        try {
          cursor.close()
        } catch (e: NullPointerException) {
          e.printStackTrace()
        }
      }
    }
    return result
  }

  @SuppressLint("Recycle")
  private fun getFileName(uri: Uri): String? {
    var result: String? = null
    if (uri.scheme == "content") {
      val cursor = context!!.contentResolver.query(uri, null, null, null, null)
      try {
        if (cursor != null && cursor.moveToFirst()) {
          var index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
          if (index < 0) {
            index = 0
          }
          result = cursor.getString(index)
        }
      } finally {
        cursor!!.close()
      }
    }
    if (result == null) {
      val cut = uri.path?.lastIndexOf('/')
      if (cut == null || cut == -1) {
        return null
      } else {
        result = uri.path!!.substring(cut + 1)
      }
    }
    return result
  }

  private fun presentPicker(
    selectedAssets: ArrayList<String>,
    options: HashMap<String, String>
  ) {
    val maxImages = options["maxImages"]
    val enableCamera = options["enableCamera"]
    val actionBarColor = options["actionBarColor"]
    val statusBarColor = options["statusBarColor"]
    val lightStatusBar = options["lightStatusBar"]
    val actionBarTitle = options["actionBarTitle"]
    val actionBarTitleColor = options["actionBarTitleColor"]
    val allViewTitle = options["allViewTitle"]
    val startInAllView = options["startInAllView"]
    val useDetailsView = options["useDetailsView"]
    val selectCircleStrokeColor = options["selectCircleStrokeColor"]
    val selectionLimitReachedText = options["selectionLimitReachedText"]
    val textOnNothingSelected = options["textOnNothingSelected"]
    val backButtonDrawable = options["backButtonDrawable"]
    val okButtonDrawable = options["okButtonDrawable"]
    val autoCloseOnSelectionLimit = options["autoCloseOnSelectionLimit"]
    val selectedUris = ArrayList<Uri>()
    for (path in selectedAssets) {
      selectedUris.add(Uri.parse(path))
    }
    val fishBun: FishBunCreator = FishBun.with(activity!!)
      .setImageAdapter(GlideAdapter())
      .setMaxCount(maxImages?.toInt()!!)
      .setCamera(enableCamera == "true")
      .setRequestCode(requestCodeChoose)
      .setSelectedImages(selectedUris)
      .exceptGif(true)
      .setIsUseDetailView(useDetailsView == "true")
      .setReachLimitAutomaticClose(autoCloseOnSelectionLimit == "true")
      .isStartInAllView(startInAllView == "true")
    if (textOnNothingSelected!!.isNotEmpty()) {
      fishBun.textOnNothingSelected(textOnNothingSelected)
    }
    if (backButtonDrawable!!.isNotEmpty()) {
      val id = context!!.resources.getIdentifier(
        backButtonDrawable,
        "drawable",
        context!!.packageName
      )
      fishBun.setHomeAsUpIndicatorDrawable(ContextCompat.getDrawable(context!!, id))
    }
    if (okButtonDrawable!!.isNotEmpty()) {
      val id = context!!.resources.getIdentifier(
        okButtonDrawable,
        "drawable",
        context!!.packageName
      )
      fishBun.setDoneButtonDrawable(ContextCompat.getDrawable(context!!, id))
    }
    if (actionBarColor != null && actionBarColor.isNotEmpty()) {
      val color = Color.parseColor(actionBarColor)
      if (statusBarColor != null && statusBarColor.isNotEmpty()) {
        val statusBarColorInt = Color.parseColor(statusBarColor)
        if (lightStatusBar != null && lightStatusBar.isNotEmpty()) {
          val lightStatusBarValue = lightStatusBar == "true"
          fishBun.setActionBarColor(color, statusBarColorInt, lightStatusBarValue)
        } else {
          fishBun.setActionBarColor(color, statusBarColorInt)
        }
      } else {
        fishBun.setActionBarColor(color)
      }
    }
    if (actionBarTitle != null && actionBarTitle.isNotEmpty()) {
      fishBun.setActionBarTitle(actionBarTitle)
    }
    if (selectionLimitReachedText != null && selectionLimitReachedText.isNotEmpty()) {
      fishBun.textOnImagesSelectionLimitReached(selectionLimitReachedText)
    }
    if (selectCircleStrokeColor != null && selectCircleStrokeColor.isNotEmpty()) {
      fishBun.setSelectCircleStrokeColor(Color.parseColor(selectCircleStrokeColor))
    }
    if (actionBarTitleColor != null && actionBarTitleColor.isNotEmpty()) {
      val color = Color.parseColor(actionBarTitleColor)
      fishBun.setActionBarTitleColor(color)
    }
    if (allViewTitle != null && allViewTitle.isNotEmpty()) {
      fishBun.setAllViewTitle(allViewTitle)
    }
    fishBun.startAlbum()
  }

  private fun finishWithSuccess(imagePathList: List<*>) {
    if (pendingResult != null) pendingResult!!.success(imagePathList)
    clearMethodCallAndResult()
  }

  private fun finishWithSuccess(hashMap: HashMap<String, Any?>) {
    if (pendingResult != null) pendingResult!!.success(hashMap)
    clearMethodCallAndResult()
  }

  private fun finishWithSuccess() {
    if (pendingResult != null) pendingResult!!.success(true)
    clearMethodCallAndResult()
  }

  private fun finishWithAlreadyActiveError(result: Result?) {
    result?.error("already_active", "Image picker is already active", null)
  }

  private fun finishWithError(errorCode: String, errorMessage: String) {
    if (pendingResult != null) pendingResult!!.error(errorCode, errorMessage, null)
    clearMethodCallAndResult()
  }

  private fun clearMethodCallAndResult() {
    methodCall = null
    pendingResult = null
  }

  private fun setPendingMethodCallAndResult(
    methodCall: MethodCall, result: Result
  ): Boolean {
    if (pendingResult != null) {
      return false
    }
    this.methodCall = methodCall
    pendingResult = result
    return true
  }
}

import Flutter
import UIKit
import Photos
import BSImagePicker

extension PHAsset {

    var originalFilename: String? {

        var fname:String?

        if #available(iOS 9.0, *) {
            let resources = PHAssetResource.assetResources(for: self)
            if let resource = resources.last {
                fname = resource.originalFilename
            }
        }

        if fname == nil {
            // this is an undocumented workaround that works as of iOS 9.1
            fname = self.value(forKey: "filename") as? String
        }

        return fname
    }
}

fileprivate extension UIViewController {
    class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}

public class MultiImagePickerPlusPlugin: NSObject, FlutterPlugin {
    var imagesResult: FlutterResult?
    var messenger: FlutterBinaryMessenger;

    let genericError = "500"

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger;
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "multi_image_picker_plus", binaryMessenger: registrar.messenger())

        let instance = MultiImagePickerPlusPlugin.init(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch (call.method) {
        case "pickImages":
            let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()

            if (status == PHAuthorizationStatus.denied) {
                return result(FlutterError(code: "PERMISSION_PERMANENTLY_DENIED", message: "The user has denied the gallery access.", details: nil))
            }

            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let options = arguments["iosOptions"] as! Dictionary<String, AnyObject>
            let selectedAssets = arguments["selectedAssets"] as! Array<String>

            let vc: ImagePickerController
            if selectedAssets.count > 0 {
                let result: PHFetchResult<PHAsset> = PHAsset.fetchAssets(withLocalIdentifiers: selectedAssets, options: nil)
                var selectedAssets: [PHAsset] = []
                for index in 1...result.count {
                    selectedAssets.append(result.object(at: index - 1))
                }

                vc = ImagePickerController(selectedAssets: selectedAssets)
            } else {
               vc =  ImagePickerController()
            }

            if #available(iOS 13.0, *) {
                // Disables iOS 13 swipe to dismiss - to force user to press cancel or done.
                vc.isModalInPresentation = true
            }

            if (!(options["doneButton"] is NSNull)) {
                let doneButton = options["doneButton"] as! Dictionary<String, AnyObject>
                if(!(doneButton["title"] is NSNull)) {
                    let title = doneButton["title"] as! String
                    if(!title.isEmpty) {
                        vc.doneButtonTitle = title
                    }
                    if(!(doneButton["tintColor"] is NSNull)) {
                        vc.doneButton.tintColor = hexToUIColor(hex: doneButton["tintColor"] as! Int)
                    }
                }
            }
            if (!(options["cancelButton"] is NSNull)) {
                let cancelButton = options["cancelButton"] as! Dictionary<String, AnyObject>
                if(!(cancelButton["title"] is NSNull)) {
                    let title = cancelButton["title"] as! String
                    if(!title.isEmpty) {
                        vc.cancelButton = UIBarButtonItem(title: title, style: .done, target: nil, action: nil)
                    }
                    if(!(cancelButton["tintColor"] is NSNull)) {
                        vc.cancelButton.tintColor = hexToUIColor(hex: cancelButton["tintColor"] as! Int)
                    }
                }
            }
            if(!(options["albumButtonColor"] is NSNull)) {
                vc.albumButton.tintColor = hexToUIColor(hex: options["albumButtonColor"] as! Int)
            }

            if (!(options["settings"] is NSNull)) {
                let settings = options["settings"] as! Dictionary<String, AnyObject>

                if(!(settings["theme"] is NSNull)) {
                    setTheme(theme: settings["theme"] as! Dictionary<String, AnyObject>, vc: vc)
                }
                if(!(settings["selection"] is NSNull)) {
                    setSelection(selection: settings["selection"] as! Dictionary<String, AnyObject>, vc: vc)
                }
                if(!(settings["list"] is NSNull)) {
                    setList(list: settings["list"] as! Dictionary<String, AnyObject>, vc: vc)
                }
                if(!(settings["dismiss"] is NSNull)) {
                    setDismiss(dismiss: settings["dismiss"] as! Dictionary<String, AnyObject>, vc: vc)
                }
                if(!(settings["fetch"] is NSNull)) {
                    setFetch(fetch: settings["fetch"] as! Dictionary<String, AnyObject>, vc: vc)
                }
                if(!(settings["previewEnabled"] is NSNull)) {
                    vc.settings.preview.enabled = settings["previewEnabled"] as! Bool
                }
            }

            UIViewController.topViewController()?.presentImagePicker(vc, animated: true,
                select: { (asset: PHAsset) -> Void in
                }, deselect: { (asset: PHAsset) -> Void in
                }, cancel: { (assets: [PHAsset]) -> Void in
                    result(FlutterError(code: "CANCELLED", message: "The user has cancelled the selection", details: nil))
                }, finish: { (assets: [PHAsset]) -> Void in
                    var results = [NSDictionary]();
                    for asset in assets {
                        results.append([
                            "identifier": asset.localIdentifier,
                            "width": asset.pixelWidth,
                            "height": asset.pixelHeight,
                            "name": asset.originalFilename!
                        ]);
                    }
                    result(results);
                }, completion: nil)
            break;
        case "requestThumbnail":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let identifier = arguments["identifier"] as! String
            let width = arguments["width"] as! Int
            let height = arguments["height"] as! Int
            let quality = arguments["quality"] as! Int
            let compressionQuality = Float(quality) / Float(100)
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()

            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.resizeMode = PHImageRequestOptionsResizeMode.exact
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.version = .current

            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)

            if (assets.count > 0) {
                let asset: PHAsset = assets[0];

                let ID: PHImageRequestID = manager.requestImage(
                    for: asset,
                    targetSize: CGSize(width: width, height: height),
                    contentMode: PHImageContentMode.aspectFill,
                    options: options,
                    resultHandler: {
                        (image: UIImage?, info) in
                        self.messenger.send(onChannel: "multi_image_picker_plus/image/" + identifier + ".thumb", message: image?.jpegData(compressionQuality: CGFloat(compressionQuality)))
                        })

                if(PHInvalidImageRequestID != ID) {
                    return result(true);
                }
            }

            return result(FlutterError(code: "ASSET_DOES_NOT_EXIST", message: "The requested image does not exist.", details: nil))
        case "requestOriginal":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let identifier = arguments["identifier"] as! String
            let quality = arguments["quality"] as! Int
            let compressionQuality = Float(quality) / Float(100)
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()

            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true
            options.version = .current

            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)

            if (assets.count > 0) {
                let asset: PHAsset = assets[0];

                let ID: PHImageRequestID = manager.requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: PHImageContentMode.aspectFill,
                    options: options,
                    resultHandler: {
                        (image: UIImage?, info) in
                        self.messenger.send(onChannel: "multi_image_picker_plus/image/" + identifier + ".original", message: image!.jpegData(compressionQuality: CGFloat(compressionQuality)))
                })

                if(PHInvalidImageRequestID != ID) {
                    return result(true);
                }
            }

            return result(FlutterError(code: "ASSET_DOES_NOT_EXIST", message: "The requested image does not exist.", details: nil))
        case "requestMetadata":
            let arguments = call.arguments as! Dictionary<String, AnyObject>
            let identifier = arguments["identifier"] as! String
            let operationQueue = OperationQueue()

            let assets: PHFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            operationQueue.addOperation {
                self.readPhotosMetadata(result: assets, operationQueue: operationQueue, callback: result)
            }
            break;
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func readPhotosMetadata(result: PHFetchResult<PHAsset>, operationQueue: OperationQueue, callback: @escaping FlutterResult) {
        let imageManager = PHImageManager.default()
        result.enumerateObjects({object , index, stop in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            imageManager.requestImageData(for: object, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                operationQueue.addOperation {
                    guard let data = imageData,
                        let metadata = type(of: self).fetchPhotoMetadata(data: data) else {
                            print("metadata not found for \(object)")
                            return
                    }
                    callback(metadata)
                }
            })
        })
    }

    static func fetchPhotoMetadata(data: Data) -> [String: Any]? {
        guard let selectedImageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
            let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil) as? [String: Any] else {
                return nil
        }
        return imagePropertiesDictionary

    }

    func hexToUIColor (hex:Int) -> UIColor {
        return UIColor(
            red: CGFloat((hex & 0x00ff0000) >> 16) / 255,
            green: CGFloat((hex & 0x0000ff00) >> 8) / 255,
            blue: CGFloat((hex & 0x000000ff) >> 0) / 255,
            alpha: CGFloat((hex & 0xff000000) >> 24) / 255
        )
    }

    private func setFetch(fetch: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(fetch["album"] is NSNull)) {
            setAlbum(album: fetch["album"] as! Dictionary<String, AnyObject>, vc: vc)
        }
        if(!(fetch["assets"] is NSNull)) {
            setAssets(assets: fetch["assets"] as! Dictionary<String, AnyObject>, vc: vc)
        }
        if(!(fetch["preview"] is NSNull)) {
            setPreview(preview: fetch["preview"] as! Dictionary<String, AnyObject>, vc: vc)
        }
    }

    private func setAlbum(album: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(album["options"] is NSNull)) {
            setFetchOptions(data: album["options"] as! Dictionary<String, AnyObject>, options: vc.settings.fetch.album.options)
        }
        if(!(album["fetchResults"] is NSNull)) {
            let fetchResults = album["fetchResults"] as! Array<Dictionary<String, AnyObject>>
            if(!fetchResults.isEmpty) {
                vc.settings.fetch.album.fetchResults = fetchResults.map{ result in
                    var options: PHFetchOptions
                    if(!(result["options"] is NSNull)) {
                        options = PHFetchOptions()
                        setFetchOptions(data: result["options"] as! Dictionary<String, AnyObject>, options: options)
                    } else {
                        options = vc.settings.fetch.album.options
                    }
                    let type: PHAssetCollectionType = PHAssetCollectionType(rawValue: result["type"] as! Int)!
                    let subtype: PHAssetCollectionSubtype = PHAssetCollectionSubtype(rawValue: result["subtype"] as! Int)!
                    return PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
                }
            }
        }
    }

    private func setAssets(assets: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(assets["supportedMediaTypes"] is NSNull)) {
            let mediaTypes = assets["supportedMediaTypes"] as! Array<String>
            if(!mediaTypes.isEmpty) {
                var supportedMediaTypes: Set<Settings.Fetch.Assets.MediaTypes> = Set();
                for mediaType in mediaTypes {
                    if mediaType == "image" {
                        supportedMediaTypes.insert(Settings.Fetch.Assets.MediaTypes.image)
                    } else {
                        supportedMediaTypes.insert(Settings.Fetch.Assets.MediaTypes.video)
                    }
                }
                vc.settings.fetch.assets.supportedMediaTypes = supportedMediaTypes
            }
        }
        if(!(assets["options"] is NSNull)) {
            setFetchOptions(data: assets["options"] as! Dictionary<String, AnyObject>, options: vc.settings.fetch.assets.options)
        }
    }

    private func setPreview(preview: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(preview["photoOptions"] is NSNull)) {
            let photoOptions = preview["photoOptions"] as! Dictionary<String, AnyObject>
            if(!(photoOptions["version"] is NSNull)) {
                vc.settings.fetch.preview.photoOptions.version = PHImageRequestOptionsVersion(rawValue: photoOptions["version"] as! Int)!
            }
            if(!(photoOptions["deliveryMode"] is NSNull)) {
                vc.settings.fetch.preview.photoOptions.deliveryMode = PHImageRequestOptionsDeliveryMode(rawValue: photoOptions["deliveryMode"] as! Int)!
            }
            if(!(photoOptions["resizeMode"] is NSNull)) {
                vc.settings.fetch.preview.photoOptions.resizeMode = PHImageRequestOptionsResizeMode(rawValue: photoOptions["resizeMode"] as! Int)!
            }
            if(!(photoOptions["normalizedCropRect"] is NSNull)) {
                let rect = photoOptions["normalizedCropRect"] as! Dictionary<String, Double>
                vc.settings.fetch.preview.photoOptions.normalizedCropRect = CGRect(x: rect["x"]!, y: rect["y"]!, width: rect["width"]!, height: rect["height"]!)
            }
            if(!(photoOptions["isNetworkAccessAllowed"] is NSNull)) {
                vc.settings.fetch.preview.photoOptions.isNetworkAccessAllowed = photoOptions["isNetworkAccessAllowed"] as! Bool
            }
            if(!(photoOptions["isSynchronous"] is NSNull)) {
                vc.settings.fetch.preview.photoOptions.isSynchronous = photoOptions["isSynchronous"] as! Bool
            }
        }

        if(!(preview["livePhotoOptions"] is NSNull)) {
            let livePhotoOptions = preview["livePhotoOptions"] as! Dictionary<String, AnyObject>
            if(!(livePhotoOptions["version"] is NSNull)) {
                vc.settings.fetch.preview.livePhotoOptions.version = PHImageRequestOptionsVersion(rawValue: livePhotoOptions["version"] as! Int)!
            }
            if(!(livePhotoOptions["deliveryMode"] is NSNull)) {
                vc.settings.fetch.preview.livePhotoOptions.deliveryMode = PHImageRequestOptionsDeliveryMode(rawValue: livePhotoOptions["deliveryMode"] as! Int)!
            }
            if(!(livePhotoOptions["isNetworkAccessAllowed"] is NSNull)) {
                vc.settings.fetch.preview.livePhotoOptions.isNetworkAccessAllowed = livePhotoOptions["isNetworkAccessAllowed"] as! Bool
            }
        }

        if(!(preview["videoOptions"] is NSNull)) {
            let videoOptions = preview["videoOptions"] as! Dictionary<String, AnyObject>
            if(!(videoOptions["version"] is NSNull)) {
                vc.settings.fetch.preview.videoOptions.version = PHVideoRequestOptionsVersion(rawValue: videoOptions["version"] as! Int)!
            }
            if(!(videoOptions["deliveryMode"] is NSNull)) {
                vc.settings.fetch.preview.videoOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode(rawValue: videoOptions["deliveryMode"] as! Int)!
            }
            if(!(videoOptions["isNetworkAccessAllowed"] is NSNull)) {
                vc.settings.fetch.preview.videoOptions.isNetworkAccessAllowed = videoOptions["isNetworkAccessAllowed"] as! Bool
            }
        }
    }

    private func setFetchOptions(data: Dictionary<String, AnyObject>, options: PHFetchOptions) {
        if(!(data["predicate"] is NSNull)) {
            let predicate = data["predicate"] as! Dictionary<String, AnyObject>
            options.predicate = NSPredicate(format: predicate["format"] as! String, argumentArray: predicate["arguments"] as! [Any]?)
        }
        if(!(data["sortDescriptors"] is NSNull)) {
            let sortDescriptors = data["sortDescriptors"] as! Array<Dictionary<String, AnyObject>>
            if(!sortDescriptors.isEmpty) {
                options.sortDescriptors = sortDescriptors.map({item in
                    var key: String?
                    if(!(item["key"] is NSNull)) {
                        key = item["key"] as! String?;
                    }
                    return NSSortDescriptor(key: key, ascending: item["ascending"] as! Bool)
                })
            }

        }
        if(!(data["includeHiddenAssets"] is NSNull)) {
            options.includeHiddenAssets = data["includeHiddenAssets"] as! Bool
        }
        if(!(data["includeAllBurstAssets"] is NSNull)) {
            options.includeAllBurstAssets = data["includeAllBurstAssets"] as! Bool
        }
        if(!(data["fetchLimit"] is NSNull)) {
            options.fetchLimit = data["fetchLimit"] as! Int
        }
        if(!(data["wantsIncrementalChangeDetails"] is NSNull)) {
            options.wantsIncrementalChangeDetails = data["wantsIncrementalChangeDetails"] as! Bool
        }
    }

    private func setList(list: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(list["spacing"]  is NSNull)) {
            vc.settings.list.spacing = list["spacing"] as! Double
        }
        if(!(list["cellsPerRow"]  is NSNull)) {
            vc.settings.list.cellsPerRow = {(verticalSize: UIUserInterfaceSizeClass, horizontalSize: UIUserInterfaceSizeClass) -> Int in
                return list["cellsPerRow"] as! Int
            }
        }
    }

    private func setDismiss(dismiss: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(dismiss["enabled"]  is NSNull)) {
            vc.settings.dismiss.enabled = dismiss["enabled"] as! Bool
        }
        if(!(dismiss["allowSwipe"]  is NSNull)) {
            vc.settings.dismiss.allowSwipe = dismiss["allowSwipe"] as! Bool
        }
    }

    private func setSelection(selection: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(selection["max"]  is NSNull)) {
            vc.settings.selection.max = selection["max"] as! Int
        }
        if(!(selection["min"] is NSNull)) {
            vc.settings.selection.min = selection["min"] as! Int
        }
        if(!(selection["unselectOnReachingMax"] is NSNull)) {
            vc.settings.selection.unselectOnReachingMax = selection["unselectOnReachingMax"] as! Bool
        }
    }

    private func setTheme(theme: Dictionary<String, AnyObject>, vc: ImagePickerController) {
        if(!(theme["selectionStyle"] is NSNull)) {
            let selectionStyle = theme["selectionStyle"] as! String

            if selectionStyle == "checked" {
                vc.settings.theme.selectionStyle = Settings.Theme.SelectionStyle.checked
            } else if selectionStyle == "numbered" {
                vc.settings.theme.selectionStyle = Settings.Theme.SelectionStyle.numbered
            }
        }
        setColor(hex: theme["backgroundColor"], attributes: &vc.settings.theme.backgroundColor)
        setColor(hex: theme["selectionFillColor"], attributes: &vc.settings.theme.selectionFillColor)
        setColor(hex: theme["selectionStrokeColor"], attributes: &vc.settings.theme.selectionStrokeColor)
        setColor(hex: theme["selectionShadowColor"], attributes: &vc.settings.theme.selectionShadowColor)
        setTitle(data: theme["previewTitleAttributes"], attributes: &vc.settings.theme.previewTitleAttributes)
        setTitle(data: theme["previewSubtitleAttributes"], attributes: &vc.settings.theme.previewSubtitleAttributes)
        setTitle(data: theme["albumTitleAttributes"], attributes: &vc.settings.theme.albumTitleAttributes)
    }

    private func setTitle(data: AnyObject?, attributes: inout [NSAttributedString.Key: Any]) {
        if(!(data is NSNull)) {
            let titleAttributes = data as! Dictionary<String, AnyObject>
            if (!(titleAttributes["fontSize"] is NSNull)) {
                attributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: titleAttributes["fontSize"] as! Double)
            }
            if (!(titleAttributes["foregroundColor"] is NSNull)) {
                attributes[NSAttributedString.Key.foregroundColor] = hexToUIColor(hex: titleAttributes["foregroundColor"] as! Int)
            }
        }
    }

    private func setColor(hex: AnyObject?, attributes: inout UIColor) {
        if(!(hex is NSNull)) {
            attributes = hexToUIColor(hex: hex as! Int)
        }
    }
}

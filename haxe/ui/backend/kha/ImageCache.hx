package haxe.ui.backend.kha;

import haxe.ui.assets.ImageInfo;

class ImageCache {
    private static var _images:Map<String, ImageInfo> = new Map<String, ImageInfo>();
    
    public static function has(resourceId:String, autoLoad:Bool = true):Bool {
        var b = _images.exists(resourceId);
        if (b == false && autoLoad == true) {
            Toolkit.assets.getImage(resourceId, function(imageInfo:ImageInfo) {
                if (imageInfo == null) {
                    return;
                }
                _images.set(resourceId, imageInfo);
            });
        }
        return b;
    }
    
    public static function get(resourceId:String) {
        return _images.get(resourceId);
    }
}
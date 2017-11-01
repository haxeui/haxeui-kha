package haxe.ui.backend;

import haxe.io.Bytes;
import haxe.ui.assets.FontInfo;
import haxe.ui.assets.ImageInfo;
import kha.Assets;
import kha.Font;
import kha.Image;

class AssetsBase {
    public function new() {

    }

    public function getTextDelegate(resourceId:String):String {
        return null;
    }

    private function getImageInternal(resourceId:String, callback:ImageInfo->Void):Void {
        var img:Image = Reflect.field(Assets.images, resourceId);
        if (img != null) {
            var imageInfo:ImageInfo = {
                width: img.realWidth,
                height: img.realHeight,
                data: img
            }
            callback(imageInfo);
        } else {
            callback(null);
        }
    }

    private function getImageFromHaxeResource(resourceId:String, callback:String->ImageInfo->Void) {
        var bytes:Bytes = Resource.getBytes(resourceId);

        var extension = resourceId.split(".").pop();
        Image.fromEncodedBytes(bytes, extension, function(image) {
            var imageInfo:ImageInfo = {
                width: image.realWidth,
                height: image.realHeight,
                data: image
            }
            callback(resourceId, imageInfo);
        }, function(error) {
            trace("Problem loading image: " + error);
            callback(resourceId, null);
        });
    }

    private function getFontInternal(resourceId:String, callback:FontInfo->Void):Void {
        if (Reflect.hasField(Assets.fonts, resourceId)) {
            callback(cast Reflect.field(Assets.fonts, resourceId));
        } else {
            callback(null);            
        }
    }

    private function getFontFromHaxeResource(resourceId:String, callback:String->FontInfo->Void) {
        var bytes:Bytes = Resource.getBytes(resourceId);
        var fontInfo = {
            data: Font.fromBytes(bytes)
        }
        callback(resourceId, fontInfo);
    }
}
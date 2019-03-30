package haxe.ui.backend;

import haxe.io.Bytes;
import haxe.ui.assets.FontInfo;
import haxe.ui.assets.ImageInfo;
import kha.Assets;
import kha.Font;
import kha.Image;

class AssetsImpl extends AssetsBase {
    private override function getImageInternal(resourceId:String, callback:ImageInfo->Void):Void {
        if (resourceId.indexOf(".") != -1) {
            var parts = resourceId.split(".");
            parts.pop();
            resourceId = parts.join(".");
        }
        if (resourceId.indexOf("/") != -1) {
            resourceId = resourceId.split("/").pop();
        }
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

    private override function getImageFromHaxeResource(resourceId:String, callback:String->ImageInfo->Void) {
        var bytes:Bytes = Resource.getBytes(resourceId);
        imageFromBytes(bytes, function(imageInfo) {
            callback(resourceId, imageInfo);
        });
    }

    public override function imageFromBytes(bytes:Bytes, callback:ImageInfo->Void) {
        Image.fromEncodedBytes(bytes, extensionFromMagicBytes(bytes), function(image) {
            var imageInfo:ImageInfo = {
                width: image.realWidth,
                height: image.realHeight,
                data: image
            }
            callback(imageInfo);
        }, function(error) {
            trace("Problem loading image: " + error);
            callback(null);
        });
    }
    
    // .jpg:  FF D8 FF
    // .png:  89 50 4E 47 0D 0A 1A 0A
    // .gif:  GIF87a      
    //        GIF89a
    // .tiff: 49 49 2A 00
    //        4D 4D 00 2A
    // .bmp:  BM 
    // .webp: RIFF ???? WEBP 
    // .ico   00 00 01 00
    //        00 00 02 00 ( cursor files )
    private function extensionFromMagicBytes(bytes:Bytes):String {
        var ext = "";
        
        if (compareBytes(bytes, [0xFF, 0xD8, 0xFF]) == true) {
            ext = "jpeg";
        } else if (compareBytes(bytes, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) == true) {
            ext = "png";
        }
        
        return ext;
    }
    
    private function compareBytes(bytes:Bytes, startsWith:Array<Int>):Bool {
        var b = true;
        var i = 0;
        for (t in startsWith) {
            if (bytes.get(i) != t) {
                b = false;
                break;
            }
            i++;
        }
        return b;
    }
    
    private override function getFontInternal(resourceId:String, callback:FontInfo->Void):Void {
        var font = Assets.fonts.get(resourceId);
        if (font != null) {
            callback({ data: font });
        } else {
            callback(null);            
        }
    }

    private override function getFontFromHaxeResource(resourceId:String, callback:String->FontInfo->Void) {
        var bytes:Bytes = Resource.getBytes(resourceId);
        var fontInfo = {
            data: Font.fromBytes(bytes)
        }
        callback(resourceId, fontInfo);
    }
}
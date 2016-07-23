package haxe.ui.backend;
import haxe.io.Bytes;
import haxe.ui.assets.FontInfo;
import haxe.ui.assets.ImageInfo;
import kha.Assets;
import kha.Image;

#if js
import js.Browser;
import js.html.*;
#end

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

        #if js
        
        var image = Browser.document.createImageElement();
		image.onload = function(e) {
            var img:Image = Image.fromImage(image, true);
			var imageInfo:ImageInfo = {
				width: img.realWidth,
				height: img.realHeight,
				data: img
			}
			callback(resourceId, imageInfo);
		}
		var base64:String = haxe.crypto.Base64.encode(bytes);
		image.src = "data:image/png;base64," + base64;
        
        #elseif flash
        
        #end
    }

    private function getFontInternal(resourceId:String, callback:FontInfo->Void):Void {
        callback(null);
    }
    
    private function getFontFromHaxeResource(resourceId:String, callback:String->FontInfo->Void) {
        callback(resourceId, null);
    }
}
package haxe.ui.backend.kha;

import haxe.ui.util.Variant;
import haxe.ui.assets.ImageInfo;
import haxe.ui.loaders.image.ImageLoaderBase;
import haxe.ui.components.Image;

class TileImageLoader extends ImageLoaderBase {
    public override function load(resource:Variant, callback:ImageInfo->Void) {
        var stringResource:String = resource;
        var n = stringResource.indexOf("://");
        stringResource = stringResource.substring(n + 3);
        var parts = stringResource.split(",");
        stringResource = parts[0];

        Toolkit.assets.getImage(stringResource, callback);
    }

    public override function postProcess(resource:Variant, image:Image) {
        var stringResource:String = resource;
        var n = stringResource.indexOf("://");
        stringResource = stringResource.substring(n + 3);
        var parts = stringResource.split(",");
        if (parts.length == 5) {
            var sx = Std.parseFloat(parts[1]);
            var sy = Std.parseFloat(parts[2]);
            var sw = Std.parseFloat(parts[3]);
            var sh = Std.parseFloat(parts[4]);
            image.getImageDisplay().subImage(sx, sy, sw, sh);
        }
    }
}
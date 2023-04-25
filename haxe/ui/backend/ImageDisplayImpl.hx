package haxe.ui.backend;

import kha.Image;
import kha.FastFloat;

class ImageDisplayImpl extends ImageBase {
    public var _buffer:Image = null;
    
    //***********************************************************************************************************
    // Validation functions
    //***********************************************************************************************************

    private override function validateData() {
        if (_imageInfo != null) {
            _buffer = _imageInfo.data;
            var w:FastFloat = _imageInfo.width;
            var h:FastFloat = _imageInfo.height;
            if (isSubImage) {
                w = sw;
                h = sh;
            }

            if (_imageWidth <= 0) {
                _imageWidth = w;
            }
            if (_imageHeight <= 0) {
                _imageHeight = h;
            }
            if (isSubImage) {
                _imageWidth = w;
                cast(parentComponent, haxe.ui.components.Image).originalWidth = w;

                _imageHeight = h;
                cast(parentComponent, haxe.ui.components.Image).originalHeight = h;
            }

            aspectRatio = w / h;
        } else {
            dispose();
            _imageWidth = 0;
            _imageHeight = 0;
        }
    }
    
    public var scaled(get, null):Bool;
    private function get_scaled():Bool {
        if (_imageInfo == null) {
            return false;
        }
        return (_imageWidth != _imageInfo.width || _imageHeight != _imageInfo.height);
    }

    private var isSubImage:Bool = false;
    private var sx:FastFloat;
    private var sy:FastFloat;
    private var sw:FastFloat;
    private var sh:FastFloat;
    public function subImage(sx:FastFloat, sy:FastFloat, sw:FastFloat, sh:FastFloat) {
        isSubImage = true;
        this.sx = sx;
        this.sy = sy;
        this.sw = sw;
        this.sh = sh;
    }
}
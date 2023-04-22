package haxe.ui.backend;

import haxe.ui.geom.Rectangle;
import haxe.ui.core.Component;
import haxe.ds.Either;
import haxe.ui.assets.ImageInfo;
import kha.Image;

class ImageDisplayImpl extends ImageBase {
    public var _buffer:Image = null;
    
    //***********************************************************************************************************
    // Validation functions
    //***********************************************************************************************************

    private override function validateData() {
        if (_imageInfo != null) {
            _buffer = _imageInfo.data;
            if (_imageWidth <= 0) {
                _imageWidth = _imageInfo.width;
            }
            if (_imageHeight <= 0) {
                _imageHeight = _imageInfo.height;
            }
            aspectRatio = _imageInfo.width / _imageInfo.height;
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
}
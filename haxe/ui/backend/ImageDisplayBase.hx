package haxe.ui.backend;
import haxe.ui.geom.Rectangle;
import haxe.ui.core.Component;
import haxe.ds.Either;
import haxe.ui.assets.ImageInfo;
import kha.Image;

class ImageDisplayBase {
    public function new() {
    }

    public var _buffer:Image = null;
    public var parentComponent:Component;
    public var aspectRatio:Float = 1; // width x height

    private var _left:Float = 0;
    private var _top:Float = 0;
    private var _imageWidth:Float = 0;
    private var _imageHeight:Float = 0;
    private var _imageInfo:ImageInfo;
    private var _imageClipRect:Rectangle;
    
    
    //***********************************************************************************************************
    // Validation functions
    //***********************************************************************************************************

    private function validateData() {
        if (_imageInfo != null) {
            dispose();
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
    
    private function validatePosition() {
        
    }
    
    private function validateDisplay() {
        
    }
    
    public function dispose() {
        /*
        if (_buffer != null) {
            _buffer.unload();
            _buffer = null;
        }
        */
    }
}
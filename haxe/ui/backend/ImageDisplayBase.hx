package haxe.ui.backend;
import haxe.ui.util.Rectangle;
import haxe.ui.core.Component;
import haxe.ds.Either;
import haxe.ui.assets.ImageInfo;
import kha.Image;

class ImageDisplayBase {
    public function new() {
    }

    public var _buffer:Image = null;
    private var _left:Float = 0;
    private var _top:Float = 0;
    private var _imageWidth:Float = -1;
    private var _imageHeight:Float = -1;

    public var parentComponent:Component;
    public var aspectRatio:Float = 1; // width x height

    public var left(get, set):Float;
    private function get_left():Float {
        return _left;
    }
    private function set_left(value:Float):Float {
        _left = value;
        return value;
    }

    public var top(get, set):Float;
    private function get_top():Float {
        return _top;
    }
    private function set_top(value:Float):Float {
        _top = value;
        return value;
    }

    public var imageWidth(get, set):Float;
    private function set_imageWidth(value:Float):Float {
        return value;
    }

    private function get_imageWidth():Float {
        return _imageWidth;
    }

    public var imageHeight(get, set):Float;
    private function set_imageHeight(value:Float):Float {
        return value;
    }

    private function get_imageHeight():Float {
        return _imageHeight;
    }

    private var _imageInfo:ImageInfo;
    public var imageInfo(get, set):ImageInfo;
    private function get_imageInfo():ImageInfo {
        return _imageInfo;
    }
    private function set_imageInfo(value:ImageInfo):ImageInfo {
        dispose();
        _imageInfo = value;
        _buffer = _imageInfo.data;
        _imageWidth = _imageInfo.width;
        _imageHeight = _imageInfo.height;
        aspectRatio = _imageInfo.width / _imageInfo.height;
        return value;
    }

    public var imageClipRect(get, set):Rectangle;
    private var _imageClipRect:Rectangle;
    public function get_imageClipRect():Rectangle {
        return _imageClipRect;
    }
    private function set_imageClipRect(value:Rectangle):Rectangle {
        _imageClipRect = value;

        //TODO
        if(value == null) {

        } else {

        }

        return value;
    }

    public function dispose() {
        if (_buffer != null) {
            _buffer.unload();
            _buffer = null;
        }
    }
}
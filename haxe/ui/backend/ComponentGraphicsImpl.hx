package haxe.ui.backend;

import haxe.io.Bytes;
import haxe.ui.core.Component;
import haxe.ui.geom.Point;
import kha.math.Vector2;
import kha.Image;
import kha.graphics2.Graphics;
import kha.graphics4.TextureFormat;
import kha.graphics4.Usage;
import kha.Color as Kolor;
import haxe.ui.util.Color;

using haxe.ui.backend.kha.GraphicsExtension;

class ComponentGraphicsImpl extends ComponentGraphicsBase {
    static inline final BEZIER_SEGMENTS = 20;

    public function new(component:Component) {
        super(component);
    }
    
    private var _image:Image = null;
    private var _hasImage:Bool = false;
    private var _lastBytes:Bytes = null;

    inline function getKolor(c:Color, a:Int=255) 
        return Kolor.fromBytes(c.r, c.g, c.b, a);
    
    public function renderTo(g:Graphics) {
        var currentPosition:Point = new Point();
        var currentStrokeColor:Color = -1;
        var currentStrokeThickness:Float = 1;
        var currentStrokeAlpha:Int = 255;
        var currentFillColor:Color = -1;
        var currentFillAlpha:Int = 255;
        
        var sx = _component.screenLeft;
        var sy = _component.screenTop;
        var w = _component.width;
        var h = _component.height;

        final getFillKolor = () -> getKolor(currentFillColor, currentFillAlpha);
        final getStrokeKolor = () -> getKolor(currentStrokeColor, currentStrokeAlpha);
        
        for (command in _drawCommands) {
            switch (command) {
                case Clear:
                    g.color = Kolor.White;
                    g.fillRect(sx, sy, w, h);
                case MoveTo(x, y):
                    currentPosition.x = x;
                    currentPosition.y = y;
                case LineTo(x, y):
                    if (currentStrokeColor != -1) {
                        g.color = getStrokeKolor();
                        g.drawLine(sx + currentPosition.x,
                                   sy + currentPosition.y,
                                   sx + x,
                                   sy + y,
                                   currentStrokeThickness /* + .5 */);
                    }
                    currentPosition.x = x;
                    currentPosition.y = y;
                case StrokeStyle(color, thickness, alpha):
                    if (thickness != null) {
                        currentStrokeThickness = thickness;
                    }
                    if (color != null) {
                        currentStrokeColor = color;
                    } else {
                        currentStrokeColor = -1;
                    }
                    if (alpha != null) {
                        currentStrokeAlpha = Std.int(alpha * 255);
                    }
                case FillStyle(color, alpha):
                    if (color != null) {
                        currentFillColor = color;
                    } else {
                        currentFillColor = -1;
                    }
                    if (alpha != null) {
                        currentFillAlpha = Std.int(alpha * 255);
                    }
                case Circle(x, y, radius):
                    if (currentFillColor != -1) {
                        g.color = getFillKolor();
                        g.fillCircle(sx + x, sy + y, radius + currentStrokeThickness);
                    }
                    if (currentStrokeColor != -1) {
                        g.color = getStrokeKolor();
                        g.drawCircle(sx + x, sy + y, radius + currentStrokeThickness, currentStrokeThickness);
                    }
                case CurveTo(controlX, controlY, anchorX, anchorY):
                    if (currentStrokeColor != -1) {
                        g.color = getStrokeKolor();
                        final bezX = [sx + currentPosition.x, sx + controlX, sx + anchorX];
                        final bezY = [sy + currentPosition.y, sy + controlY, sy + anchorY];
                        g.drawQuadraticBezier(bezX, bezY, BEZIER_SEGMENTS, currentStrokeThickness);
                    }
                    currentPosition.x = anchorX;
                    currentPosition.y = anchorY;
                case CubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY):
                    if (currentStrokeColor != -1) {
                        g.color = getStrokeKolor();
                        final bezX = [sx + currentPosition.x, sx + controlX1, sx + controlX2, sx + anchorX];
                        final bezY = [sy + currentPosition.y, sy + controlY1, sy + controlY2, sy + anchorY];
                        g.drawCubicBezier(bezX, bezY, BEZIER_SEGMENTS, currentStrokeThickness);
                    }
                    currentPosition.x = anchorX;
                    currentPosition.y = anchorY;
               case Rectangle(x, y, width, height):
                    if (currentFillColor != -1) {
                        g.color = getFillKolor();
                        g.fillRect(sx + x, sy + y, width, height);
                    }
                    if (currentStrokeColor != -1) {
                        g.color = getStrokeKolor();
                        g.drawRect(sx + x, sy + y, width, height, currentStrokeThickness);
                    }
               case SetPixel(x, y, color):
                    g.color = getKolor(color);
                    g.fillRect(sx + x, sy + y, 1.0, 1.0); // probably not right
               case SetPixels(pixels):   
                // TODO
                //    if (_hasTexture == false) {
                //        _hasTexture = true;
                //        var image = Image.fromBytes(data, 
                //                                    Std.int(_component.width), 
                //                                    Std.int(_component.height), 
                //                                    TextureFormat.RGBA32,
                //                                    Usage.DynamicUsage,
                //                                    true);
                //        _texture = LoadTextureFromImage(image);
                //        _lastBytes = pixels;
                //        //UnloadImage(image);
                //    } else if (_lastBytes != pixels) {
                //        _lastBytes = pixels;
                //        var data = NativeArray.address(pixels.getData(), 0);
                //        UpdateTexture(_texture, data.rawCast());
                //    }
                   

                //    DrawTexture(_texture, sx, sy, Colors.WHITE);
               case Image(resource, x, y, width, height):
                // TODO
            }
        }
    }
}
package haxe.ui.backend.kha;

import haxe.ui.backend.kha.ImageCache;
import haxe.ui.filters.DropShadow;
import haxe.ui.filters.Filter;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import haxe.ui.styles.Style;
import haxe.ui.util.ColorUtil;
import kha.Color;
import kha.graphics2.Graphics;

class StyleHelper {
    public static function paintStyle(g:Graphics, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        /*
        x = Math.ffloor(x);
        y = Math.ffloor(y);
        w = Math.fceil(w);
        h = Math.fceil(h);
        */

        if (w <= 0 || h <= 0) {
            return;
        }

        x = Std.int(x);
        y = Std.int(y);
        w = Std.int(w);
        h = Std.int(h);
        
        x *= Toolkit.scaleX;
        y *= Toolkit.scaleY;
        w *= Toolkit.scaleX;
        h *= Toolkit.scaleY;
        
        var orgX = x;
        var orgY = y;
        var orgW = w;
        var orgH = h;

        var alpha:Int = 0xFF000000;
        if (style.backgroundColor != null) {
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }

                var arr:Array<Int> = null;
                var n:Int = 0;
                if (gradientType == "vertical") {
                    arr = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, Std.int(h));
                    for (c in arr) {
                        g.color = c | alpha;
                        g.fillRect(x, y + n, w, 1);
                        g.color = Color.White;
                        n++;
                    }
                } else if (gradientType == "horizontal") {
                    arr = ColorUtil.buildColorArray(style.backgroundColor, style.backgroundColorEnd, Std.int(w));
                    for (c in arr) {
                        g.color = c | alpha;
                        g.fillRect(x + n, y, 1, h);
                        g.color = Color.White;
                        n++;
                    }
                }
            } else {
                g.color = style.backgroundColor | alpha;
                g.fillRect(x, y, w, h);
                g.color = Color.White;
            }
        }
        
        if (style.backgroundImage != null) {
            if (ImageCache.has(style.backgroundImage)) {
                var imageInfo = ImageCache.get(style.backgroundImage);
                
                var trc:Rectangle = new Rectangle(0, 0, imageInfo.width, imageInfo.height);
                if (style.backgroundImageClipTop != null
                    && style.backgroundImageClipLeft != null
                    && style.backgroundImageClipBottom != null
                    && style.backgroundImageClipRight != null) {
                        trc = new Rectangle(style.backgroundImageClipLeft,
                                            style.backgroundImageClipTop,
                                            style.backgroundImageClipRight - style.backgroundImageClipLeft,
                                            style.backgroundImageClipBottom - style.backgroundImageClipTop);
                }

                var slice:Rectangle = null;
                if (style.backgroundImageSliceTop != null
                    && style.backgroundImageSliceLeft != null
                    && style.backgroundImageSliceBottom != null
                    && style.backgroundImageSliceRight != null) {
                    slice = new Rectangle(style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceTop,
                                          style.backgroundImageSliceRight - style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceBottom - style.backgroundImageSliceTop);
                }

                if (slice == null) {
                    if (style.backgroundImageRepeat == null) {
                        g.drawSubImage(imageInfo.data, x, y, 0, 0, trc.width, trc.height);
                    } else if (style.backgroundImageRepeat == "stretch") {
                        g.drawScaledImage(imageInfo.data, x, y, w, h);
                    } else {
                        g.drawSubImage(imageInfo.data, x, y, 0, 0, trc.width, trc.height);
                    }
                } else {
                    var rects:Slice9Rects = Slice9.buildRects(w, h, trc.width, trc.height, slice);
                    var srcRects:Array<Rectangle> = rects.src;
                    var dstRects:Array<Rectangle> = rects.dst;
                    for (i in 0...srcRects.length) {
                        var srcRect = new Rectangle(srcRects[i].left + trc.left,
                                                    srcRects[i].top + trc.top,
                                                    srcRects[i].width,
                                                    srcRects[i].height);
                        var dstRect = dstRects[i];
                        g.drawScaledSubImage(imageInfo.data, srcRect.left, srcRect.top, srcRect.width, srcRect.height,
                                                             x + dstRect.left, y + dstRect.top, dstRect.width, dstRect.height);
                    }
                }
            }
        }
        
        if (style.borderLeftSize != null &&
            style.borderLeftSize == style.borderRightSize &&
            style.borderLeftSize == style.borderBottomSize &&
            style.borderLeftSize == style.borderTopSize
            
            && style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor) { // full border

            var borderSize:Int = Std.int(style.borderLeftSize * Toolkit.scale);
            g.color = style.borderLeftColor | alpha;
            g.fillRect(x, y, w, borderSize); // top
            g.fillRect(x, y + h - borderSize, w, borderSize); // bottom
            g.fillRect(x, y, borderSize, h); // left
            g.fillRect(x + w - borderSize, y, borderSize, h); // right
            g.color = Color.White;    
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                g.color = style.borderTopColor | alpha;
                g.fillRect(x, y, w, (style.borderTopSize * Toolkit.scale)); // top
                g.color = Color.White;
            }
            
            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                g.color = style.borderBottomColor | alpha;
                g.fillRect(x, y + h - (style.borderBottomSize * Toolkit.scale), w, (style.borderBottomSize * Toolkit.scale)); // bottom
                g.color = Color.White;
            }

            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                g.color = style.borderLeftColor | alpha;
                g.fillRect(x, y, (style.borderLeftSize * Toolkit.scale), h); // left
                g.color = Color.White;
            }
            
            if (style.borderRightSize != null && style.borderRightSize > 0) {
                g.color = style.borderRightColor | alpha;
                g.fillRect(x + w - (style.borderRightSize * Toolkit.scale), y, (style.borderRightSize * Toolkit.scale), h); // right
                g.color = Color.White;
            }
        }        
        
        if (style.filter != null) {
            var f:Filter = style.filter[0];
            if ((f is DropShadow)) {
                var dropShadow:DropShadow = cast(f, DropShadow);
                if (dropShadow.inner == true) {
                    drawShadow(g, dropShadow.color, x, y, w, h, Std.int(dropShadow.distance), dropShadow.inner);
                } else {
                    drawShadow(g, dropShadow.color, orgX - 1, orgY - 1, orgW, orgH, Std.int(dropShadow.distance), dropShadow.inner);
                }
            }
        }
    }

    private static function drawShadow(g:Graphics, color:Int, x:Float, y:Float, w:Float, h:Float, size:Int, inset:Bool = false):Void {
        size = Std.int(size * Toolkit.scale);
        if (inset == false) {
            for (i in 0...size) {
                g.color = color | 0x30000000;
                g.fillRect(x + i + 1, y + h + 1 + i, w + 0, 1); // bottom
                g.fillRect(x + w + 1 + i, y + i + 1, 1, h + 1); // right
            }
        } else {
            for (i in 0...size) {
                g.color = color | 0x30000000;
                g.fillRect(x + i, y + i, w - i, 1); // top
                g.fillRect(x + i, y + i, 1, h - i); // left
            }
        }
        g.color = Color.White;
    }
}
package haxe.ui.backend.kha;

import haxe.ui.assets.ImageInfo;
import haxe.ui.styles.Style;
import haxe.ui.util.ColorUtil;
import haxe.ui.util.Rectangle;
import haxe.ui.util.Slice9;
import kha.Color;
import kha.graphics2.Graphics;

class StyleHelper {
    public static function paintStyle(g:Graphics, style:Style, x:Float, y:Float, w:Float, h:Float):Void {
        x = Math.ffloor(x);
        y = Math.ffloor(y);
        w = Math.fceil(w);
        h = Math.fceil(h);

        if (w <= 0 || h <= 0) {
            return;
        }

        var alpha:Int = 0xFF000000;
        if (style.opacity != null) {
            alpha = Std.int(style.opacity * 255) << 24;
        }

        if (style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor) { // full border

            var borderSize:Int = Std.int(style.borderLeftSize);

            g.color = style.borderLeftColor | alpha;
            x++;
            w--;
            h--;
            for (i in 0...borderSize) {
                g.drawRect(x, y, w, h);
                x++;
                y++;
                w-=2;
                h-=2;
            }
            g.color = Color.White;
            x--;
            w++;
            h++;
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                g.color = style.borderTopColor | alpha;
                g.fillRect(x, y, w, style.borderTopSize); // top
                g.color = Color.White;
                y += style.borderTopSize;
                h -= style.borderTopSize;
            }

            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                g.color = style.borderLeftColor | alpha;
                g.fillRect(x, y, style.borderLeftSize, h); // left
                g.color = Color.White;
                x += style.borderLeftSize;
                w -= style.borderLeftSize;
            }

            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                g.color = style.borderBottomColor | alpha;
                g.fillRect(x, y + h - style.borderBottomSize, w, style.borderBottomSize); // bottom
                g.color = Color.White;
                h -= style.borderBottomSize;
            }

            if (style.borderRightSize != null && style.borderRightSize > 0) {
                g.color = style.borderRightColor | alpha;
                g.fillRect(x + w - style.borderRightSize, y, style.borderRightSize, h + 1); // right
                g.color = Color.White;
                w -= style.borderRightSize;
            }
        }

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
            Toolkit.assets.getImage(style.backgroundImage, function(imageInfo:ImageInfo) {
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
            });
        }

        if (style.filter != null) {
            drawShadow(g, 0x888888 | 0x444444, x, y, w, h, 1, true);
        }
    }

    private static function drawShadow(g:Graphics, color:Int, x:Float, y:Float, w:Float, h:Float, size:Int, inset:Bool = false):Void {
        g.color = color | 0x7F000000;
        if (inset == false) {
            for (i in 0...size) {
                g.fillRect(x + i, y + w + 1 + i, w + 1, 1); // bottom
                g.fillRect(x + w + 1 + i, y + i, 1, h + 2); // right
            }
        } else {
            for (i in 0...size) {
                g.fillRect(x + i, y + i, w - i, 1); // top
                g.fillRect(x + i, y + i, 1, h - i); // left
            }
        }
        g.color = Color.White;
    }
}
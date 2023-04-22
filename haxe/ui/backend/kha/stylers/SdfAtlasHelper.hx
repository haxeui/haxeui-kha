package haxe.ui.backend.kha.stylers;

import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import haxe.ui.geom.Slice9.Slice9Rects;
import kha.Image;
import haxe.ui.styles.Style;
import kha.graphics2.Graphics;

class SdfAtlasHelper {
    private static var _atlasItems:Map<String, SdfAtlasRectInfo> = new Map<String, SdfAtlasRectInfo>();
    private static var _atlases:Array<StfAtlasInfo> = new Array<StfAtlasInfo>();

    public static inline function isEligible(s:Style):Bool {
        return (s.borderRadius != null && s.borderRadius > 0)
               || (s.borderRadiusTopLeft != null && s.borderRadiusTopLeft > 0)
               || (s.borderRadiusTopRight != null && s.borderRadiusTopRight > 0)
               || (s.borderRadiusBottomLeft != null && s.borderRadiusBottomLeft > 0)
               || (s.borderRadiusBottomRight != null && s.borderRadiusBottomRight > 0)
        ;
    }

    public static inline function cacheKeyFromStyle(s:Style):String {
        return s.borderRadiusTopLeft + "_"
             + s.borderRadiusTopRight + "_"
             + s.borderRadiusBottomLeft + "_"
             + s.borderRadiusBottomRight + "_"
             + s.borderRadius + "_"
             + s.borderColor + "_"
             + s.borderTopColor + "_"
             + s.borderLeftColor + "_"
             + s.borderBottomColor + "_"
             + s.borderRightColor + "_"
             + s.borderSize + "_"
             + s.borderTopSize + "_"
             + s.borderLeftSize + "_"
             + s.borderBottomSize + "_"
             + s.borderRightSize + "_"
             + s.backgroundColor + "_"
             + s.backgroundColorEnd + "_"
             + s.backgroundGradientStyle
        ;
    }

    public static function getInfo(g:Graphics, s:Style):SdfAtlasRectInfo {
        var key = cacheKeyFromStyle(s);
        var info = _atlasItems.get(key);
        if (info != null) {
            return info;
        }

        var atlas:StfAtlasInfo = _atlases[_atlases.length - 1];
        if (atlas == null) {
            atlas = new StfAtlasInfo();
            _atlases.push(atlas);
        }

        if (atlas.isFull) {
            atlas = new StfAtlasInfo();
            _atlases.push(atlas);
        }

        info = atlas.drawStyle(g, s);
        _atlasItems.set(key, info);
        return info;
    }
}

class StfAtlasInfo {
    public static inline var sizeW = 50;
    public static inline var sizeH = 50;
    public static inline var maxW = 1000;
    public static inline var maxH = 1000;

    public var nextX:Float = 0;
    public var nextY:Float = 0;
    public var buffer:Image = null;
    public var isFull:Bool = false;

    private var painter:SDFPainter = null;

    public function new() {
        buffer = Image.createRenderTarget(maxW, maxH);
        painter = new SDFPainter(buffer);
    }

    public function drawStyle(g:Graphics, style:Style) {
        if (isFull) {
            return null;
        }
        g.disableScissor();
        g.end();
        painter.begin(false);

        var info:SdfAtlasRectInfo = {
            altlas: this
        };

        var tr:Float = 0;
        var br:Float = 0;
        var tl:Float = 0;
        var bl:Float = 0;

        var smooth = 0.5;
        var border:Float = 0;
        var bottomLeftColor:Int = 0;
        var topLeftColor:Int = 0;
        var topRightColor:Int = 0;
        var bottomRightColor:Int = 0;
        var borderColor:Int = 0;

        var radiusModifier = 1;
        if (style.borderRadius != null) {
            tr = style.borderRadius + radiusModifier;
            br = style.borderRadius + radiusModifier;
            tl = style.borderRadius + radiusModifier;
            bl = style.borderRadius + radiusModifier;
        } else {
            if (style.borderRadiusTopRight != null) {
                tr = style.borderRadiusTopRight + radiusModifier;
            }
            if (style.borderRadiusBottomRight != null) {
                br = style.borderRadiusBottomRight + radiusModifier;
            }
            if (style.borderRadiusTopLeft != null) {
                tl = style.borderRadiusTopLeft + radiusModifier;
            }
            if (style.borderRadiusBottomLeft != null) {
                bl = style.borderRadiusBottomLeft + radiusModifier;
            }
        }

        var alpha = 0xff000000;
        painter.opacity = 1;
        if (style.backgroundColor == null) {
            painter.opacity = 0;
        } else {
            if (style.opacity != null && style.opacity != 1) {
                painter.opacity = style.opacity;
            } else {
                painter.opacity = 1;
            }
        }
        if (style.borderColor != null) {
            borderColor = style.borderColor | alpha;
        } else {
            if (style.borderLeftColor != null) {
                borderColor = style.borderLeftColor | alpha;
            }
            if (style.borderTopColor != null) {
                borderColor = style.borderTopColor | alpha;
            }
            if (style.borderBottomColor != null) {
                borderColor = style.borderBottomColor | alpha;
            }
            if (style.borderRightColor != null) {
                borderColor = style.borderRightColor | alpha;
            }
        }

        if (style.borderLeftSize != null && style.borderLeftSize > 0) {
            border = style.borderLeftSize + .5;
        }
        if (style.borderTopSize != null && style.borderTopSize > 0) {
            border = style.borderTopSize + .5;
        }
        if (style.borderBottomSize != null && style.borderBottomSize > 0) {
            border = style.borderBottomSize + .5;
        }
        if (style.borderRightSize != null && style.borderRightSize > 0) {
            border = style.borderRightSize + .5;
        }

        if (style.backgroundColor != null) {
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientStyle = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientStyle = style.backgroundGradientStyle;
                }
                if (gradientStyle == "vertical") {
                    bottomLeftColor = style.backgroundColorEnd | alpha;
                    topLeftColor = style.backgroundColor | alpha;
                    topRightColor = style.backgroundColor | alpha;
                    bottomRightColor = style.backgroundColorEnd | alpha;
                } else {
                    bottomLeftColor = style.backgroundColor | alpha;
                    topLeftColor = style.backgroundColor | alpha;
                    topRightColor = style.backgroundColorEnd | alpha;
                    bottomRightColor = style.backgroundColorEnd | alpha;
                }
            } else {
                bottomLeftColor = style.backgroundColor | alpha;
                topLeftColor = style.backgroundColor | alpha;
                topRightColor = style.backgroundColor | alpha;
                bottomRightColor = style.backgroundColor | alpha;
            }
        }

        painter.sdfRect(nextX, nextY, sizeW, sizeH, {
                        tr: tr,
                        br: br,
                        tl: tl,
                        bl: bl
                    },
                    border, borderColor,
                    smooth,
                    bottomLeftColor, topLeftColor, topRightColor, bottomRightColor);

        info.offsetX = nextX;
        info.offsetY = nextY;
        var tl2 = tl;
        if (bl > tl2) {
            tl2 = bl;
        }
        var br2 = br;
        if (tr > br2) {
            br2 = tr;
        }
        if (tl2 == 0 && br2 != 0) {
            tl2 = br2;
        }
        if (br2 == 0 && tl2 != 0) {
            br2 = tl2;
        }
        var sw:Float = sizeW;
        var sh:Float = sizeH;
        if (style.borderBottomSize == 0) {
            sh -= style.borderTopSize;
        }
        if (style.borderTopSize == 0) {
            info.offsetY += style.borderBottomSize;
            sh -= style.borderBottomSize;
        }
        if (style.borderRightSize == 0) {
            sw -= style.borderLeftSize;
        }
        if (style.borderLeftSize == 0) {
            info.offsetX += style.borderRightSize;
            sw -= style.borderRightSize;
        }
        var slice = new Rectangle(tl2, tl2, sw - (tl2 + br2), sh - (tl2 + br2));
        info.srcRects = Slice9.buildSrcRects(sw, sh,  slice);

        nextX += sizeW;
        if (nextX >= maxW) {
            nextX = 0;
            nextY += sizeH;
            if (nextY >= maxH) {
                isFull = true;
            }
        }

        painter.end();
        g.begin(false);

        return info;
    }
}

@:structInit
class SdfAtlasRectInfo {
    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    public var altlas:StfAtlasInfo;

    public var srcRects:Array<Rectangle> = null;
}
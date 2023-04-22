package haxe.ui.backend.kha;

// from: https://github.com/tizilogic/kha-sdf-painter

import kha.Canvas;
import kha.Color;
import kha.FastFloat;
import kha.Image;
import kha.Shaders;
import kha.arrays.Float32Array;
import kha.graphics4.BlendingFactor;
import kha.graphics4.Graphics;
import kha.graphics4.Graphics2;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.PipelineState;
import kha.math.FastVector2;
import kha.math.FastMatrix4;


typedef CornerRadius = {tr:FastFloat, ?br:Null<FastFloat>, ?tl:Null<FastFloat>, ?bl:Null<FastFloat>};

class SDFRectPainter {
	var projectionMatrix: FastMatrix4;
	static var standardSDFRectPipeline: PipelineCache = null;
	static var structure: VertexStructure = null;
	static inline var bufferSize: Int = 300;
	static inline var vertexSize: Int = 20;
	static var bufferIndex: Int;
	static var rectVertexBuffer: VertexBuffer;
	static var rectVertices: Float32Array;
	static var indexBuffer: IndexBuffer;
	var g: Graphics;
	var myPipeline: PipelineCache = null;
	public var pipeline(get, set): PipelineCache;

	public function new(g4: Graphics) {
		this.g = g4;
		bufferIndex = 0;
		initShaders();
		myPipeline = standardSDFRectPipeline;
		initBuffers();
	}

	private function get_pipeline(): PipelineCache {
		return myPipeline;
	}

	private function set_pipeline(pipe: PipelineCache): PipelineCache {
		myPipeline = pipe != null ? pipe : standardSDFRectPipeline;
		return myPipeline;
	}

	public function setProjection(projectionMatrix: FastMatrix4): Void {
		this.projectionMatrix = projectionMatrix;
	}

	private static function initShaders(): Void {
		if (structure == null) {
			structure = SDFPainter.createSDFRectVertexStructure();
		}
		if (standardSDFRectPipeline == null) {
			var pipeline = SDFPainter.createSDFRectPipeline(structure);
			pipeline.compile();
			standardSDFRectPipeline = new SimplePipelineCache(pipeline, false);
		}
	}

	function initBuffers(): Void {
		if (rectVertexBuffer == null) {
			rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
			rectVertices = rectVertexBuffer.lock();

			indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
			var indices = indexBuffer.lock();
			for (i in 0...bufferSize) {
				indices[i * 3 * 2 + 0] = i * 4 + 0;
				indices[i * 3 * 2 + 1] = i * 4 + 1;
				indices[i * 3 * 2 + 2] = i * 4 + 2;
				indices[i * 3 * 2 + 3] = i * 4 + 0;
				indices[i * 3 * 2 + 4] = i * 4 + 2;
				indices[i * 3 * 2 + 5] = i * 4 + 3;
			}
			indexBuffer.unlock();
		}
	}

	private inline function setRectVertices(
		bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 0, bottomleftx);
		rectVertices.set(baseIndex + 1, bottomlefty);
		rectVertices.set(baseIndex + 2, -5.0);

		rectVertices.set(baseIndex + 20, topleftx);
		rectVertices.set(baseIndex + 21, toplefty);
		rectVertices.set(baseIndex + 22, -5.0);

		rectVertices.set(baseIndex + 40, toprightx);
		rectVertices.set(baseIndex + 41, toprighty);
		rectVertices.set(baseIndex + 42, -5.0);

		rectVertices.set(baseIndex + 60, bottomrightx);
		rectVertices.set(baseIndex + 61, bottomrighty);
		rectVertices.set(baseIndex + 62, -5.0);
	}

	private inline function setRectTexCoords(left: FastFloat, top: FastFloat, right: FastFloat, bottom: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex +  3, left);
		rectVertices.set(baseIndex +  4, bottom);

		rectVertices.set(baseIndex + 23, left);
		rectVertices.set(baseIndex + 24, top);

		rectVertices.set(baseIndex + 43, right);
		rectVertices.set(baseIndex + 44, top);

		rectVertices.set(baseIndex + 63, right);
		rectVertices.set(baseIndex + 64, bottom);
	}

	private inline function setRectBox(u: FastFloat, v: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 5, u);
		rectVertices.set(baseIndex + 6, v);

		rectVertices.set(baseIndex + 25, u);
		rectVertices.set(baseIndex + 26, v);

		rectVertices.set(baseIndex + 45, u);
		rectVertices.set(baseIndex + 46, v);

		rectVertices.set(baseIndex + 65, u);
		rectVertices.set(baseIndex + 66, v);
	}

	private inline function setRectColor(blColor: Color, tlColor: Color, trColor: Color, brColor: Color, a: FastFloat, br: FastFloat, bg: FastFloat, bb: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		// Bottom Left
		rectVertices.set(baseIndex + 7, blColor.R);
		rectVertices.set(baseIndex + 8, blColor.G);
		rectVertices.set(baseIndex + 9, blColor.B);
		rectVertices.set(baseIndex + 10, a);
		rectVertices.set(baseIndex + 11, br);
		rectVertices.set(baseIndex + 12, bg);
		rectVertices.set(baseIndex + 13, bb);

		// Top Left
		rectVertices.set(baseIndex + 27, tlColor.R);
		rectVertices.set(baseIndex + 28, tlColor.G);
		rectVertices.set(baseIndex + 29, tlColor.B);
		rectVertices.set(baseIndex + 30, a);
		rectVertices.set(baseIndex + 31, br);
		rectVertices.set(baseIndex + 32, bg);
		rectVertices.set(baseIndex + 33, bb);

		// Top Right
		rectVertices.set(baseIndex + 47, trColor.R);
		rectVertices.set(baseIndex + 48, trColor.G);
		rectVertices.set(baseIndex + 49, trColor.B);
		rectVertices.set(baseIndex + 50, a);
		rectVertices.set(baseIndex + 51, br);
		rectVertices.set(baseIndex + 52, bg);
		rectVertices.set(baseIndex + 53, bb);

		// Bottom Right
		rectVertices.set(baseIndex + 67, brColor.R);
		rectVertices.set(baseIndex + 68, brColor.G);
		rectVertices.set(baseIndex + 69, brColor.B);
		rectVertices.set(baseIndex + 70, a);
		rectVertices.set(baseIndex + 71, br);
		rectVertices.set(baseIndex + 72, bg);
		rectVertices.set(baseIndex + 73, bb);
    }

    private inline function setCorner(c: CornerRadius): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 14, c.br);
		rectVertices.set(baseIndex + 15, c.tr);
		rectVertices.set(baseIndex + 16, c.bl);
		rectVertices.set(baseIndex + 17, c.tl);

		rectVertices.set(baseIndex + 34, c.br);
		rectVertices.set(baseIndex + 35, c.tr);
		rectVertices.set(baseIndex + 36, c.bl);
		rectVertices.set(baseIndex + 37, c.tl);

		rectVertices.set(baseIndex + 54, c.br);
		rectVertices.set(baseIndex + 55, c.tr);
		rectVertices.set(baseIndex + 56, c.bl);
		rectVertices.set(baseIndex + 57, c.tl);

		rectVertices.set(baseIndex + 74, c.br);
		rectVertices.set(baseIndex + 75, c.tr);
		rectVertices.set(baseIndex + 76, c.bl);
		rectVertices.set(baseIndex + 77, c.tl);
    }

    private inline function setBorderSmooth(b: FastFloat, s: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 18, b);
		rectVertices.set(baseIndex + 19, s);

		rectVertices.set(baseIndex + 38, b);
		rectVertices.set(baseIndex + 39, s);

		rectVertices.set(baseIndex + 58, b);
		rectVertices.set(baseIndex + 59, s);

		rectVertices.set(baseIndex + 78, b);
		rectVertices.set(baseIndex + 79, s);
	}

	private function drawBuffer(): Void {
		var pipeline = myPipeline.get(null, Depth24Stencil8);
		rectVertexBuffer.unlock(bufferIndex * 4);
		g.setPipeline(pipeline.pipeline);
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setMatrix(pipeline.projectionLocation, projectionMatrix);

		g.drawIndexedVertices(0, bufferIndex * 3 * 2);

		bufferIndex = 0;
		rectVertices = rectVertexBuffer.lock();
	}

	public inline function drawSDFRect(opacity: FastFloat, 
		bottomleftColor: Color, topleftColor: Color, toprightColor: Color, bottomrightColor: Color,
		bCol:Color, bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat,
		u: FastFloat, v: FastFloat, c: CornerRadius, b: FastFloat, s: FastFloat): Void {
		if (bufferIndex + 1 >= bufferSize) drawBuffer();
		
		setRectColor(bottomleftColor, topleftColor, toprightColor, bottomrightColor, opacity, bCol.R, bCol.G, bCol.B);
		setRectTexCoords(0, 0, u, v);
		setRectVertices(bottomleftx, bottomlefty, topleftx, toplefty, toprightx, toprighty, bottomrightx, bottomrighty);
		setRectBox(u / 2, v / 2);
		setCorner(c);
		setBorderSmooth(b, s);

		++bufferIndex;
	}

	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
	}
}


class SDFCirclePainter {
	var projectionMatrix: FastMatrix4;
	static var standardSDFCirclePipeline: PipelineCache = null;
	static var structure: VertexStructure = null;
	static inline var bufferSize: Int = 300;
	static inline var vertexSize: Int = 14;
	static var bufferIndex: Int;
	static var rectVertexBuffer: VertexBuffer;
	static var rectVertices: Float32Array;
	static var indexBuffer: IndexBuffer;
	var g: Graphics;
	var myPipeline: PipelineCache = null;
	public var pipeline(get, set): PipelineCache;

	public function new(g4: Graphics) {
		this.g = g4;
		bufferIndex = 0;
		initShaders();
		myPipeline = standardSDFCirclePipeline;
		initBuffers();
	}

	private function get_pipeline(): PipelineCache {
		return myPipeline;
	}

	private function set_pipeline(pipe: PipelineCache): PipelineCache {
		myPipeline = pipe != null ? pipe : standardSDFCirclePipeline;
		return myPipeline;
	}

	public function setProjection(projectionMatrix: FastMatrix4): Void {
		this.projectionMatrix = projectionMatrix;
	}

	private static function initShaders(): Void {
		if (structure == null) {
			structure = SDFPainter.createSDFCircleVertexStructure();
		}
		if (standardSDFCirclePipeline == null) {
			var pipeline = SDFPainter.createSDFCirclePipeline(structure);
			pipeline.compile();
			standardSDFCirclePipeline = new SimplePipelineCache(pipeline, false);
		}
	}

	function initBuffers(): Void {
		if (rectVertexBuffer == null) {
			rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
			rectVertices = rectVertexBuffer.lock();

			indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
			var indices = indexBuffer.lock();
			for (i in 0...bufferSize) {
				indices[i * 3 * 2 + 0] = i * 4 + 0;
				indices[i * 3 * 2 + 1] = i * 4 + 1;
				indices[i * 3 * 2 + 2] = i * 4 + 2;
				indices[i * 3 * 2 + 3] = i * 4 + 0;
				indices[i * 3 * 2 + 4] = i * 4 + 2;
				indices[i * 3 * 2 + 5] = i * 4 + 3;
			}
			indexBuffer.unlock();
		}
	}

	private inline function setRectVertices(
		bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 0, bottomleftx);
		rectVertices.set(baseIndex + 1, bottomlefty);
		rectVertices.set(baseIndex + 2, -5.0);

		rectVertices.set(baseIndex + 14, topleftx);
		rectVertices.set(baseIndex + 15, toplefty);
		rectVertices.set(baseIndex + 16, -5.0);

		rectVertices.set(baseIndex + 28, toprightx);
		rectVertices.set(baseIndex + 29, toprighty);
		rectVertices.set(baseIndex + 30, -5.0);

		rectVertices.set(baseIndex + 42, bottomrightx);
		rectVertices.set(baseIndex + 43, bottomrighty);
		rectVertices.set(baseIndex + 44, -5.0);
	}

	private inline function setRectTexCoords(left: FastFloat, top: FastFloat, right: FastFloat, bottom: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex +  3, left);
		rectVertices.set(baseIndex +  4, bottom);

		rectVertices.set(baseIndex + 17, left);
		rectVertices.set(baseIndex + 18, top);

		rectVertices.set(baseIndex + 31, right);
		rectVertices.set(baseIndex + 32, top);

		rectVertices.set(baseIndex + 45, right);
		rectVertices.set(baseIndex + 46, bottom);
	}

	private inline function setRectColor(r: FastFloat, g: FastFloat, b: FastFloat, a: FastFloat, br: FastFloat, bg: FastFloat, bb: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 5, r);
		rectVertices.set(baseIndex + 6, g);
		rectVertices.set(baseIndex + 7, b);
		rectVertices.set(baseIndex + 8, a);
		rectVertices.set(baseIndex + 9, br);
		rectVertices.set(baseIndex + 10, bg);
		rectVertices.set(baseIndex + 11, bb);

		rectVertices.set(baseIndex + 19, r);
		rectVertices.set(baseIndex + 20, g);
		rectVertices.set(baseIndex + 21, b);
		rectVertices.set(baseIndex + 22, a);
		rectVertices.set(baseIndex + 23, br);
		rectVertices.set(baseIndex + 24, bg);
		rectVertices.set(baseIndex + 25, bb);

		rectVertices.set(baseIndex + 33, r);
		rectVertices.set(baseIndex + 34, g);
		rectVertices.set(baseIndex + 35, b);
		rectVertices.set(baseIndex + 36, a);
		rectVertices.set(baseIndex + 37, br);
		rectVertices.set(baseIndex + 38, bg);
		rectVertices.set(baseIndex + 39, bb);

		rectVertices.set(baseIndex + 47, r);
		rectVertices.set(baseIndex + 48, g);
		rectVertices.set(baseIndex + 49, b);
		rectVertices.set(baseIndex + 50, a);
		rectVertices.set(baseIndex + 51, br);
		rectVertices.set(baseIndex + 52, bg);
		rectVertices.set(baseIndex + 53, bb);
    }

    private inline function setBorderSmooth(b: FastFloat, s: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 12, b);
		rectVertices.set(baseIndex + 13, s);

		rectVertices.set(baseIndex + 26, b);
		rectVertices.set(baseIndex + 27, s);

		rectVertices.set(baseIndex + 40, b);
		rectVertices.set(baseIndex + 41, s);

		rectVertices.set(baseIndex + 54, b);
		rectVertices.set(baseIndex + 55, s);
    }

	private function drawBuffer(): Void {
		var pipeline = myPipeline.get(null, Depth24Stencil8);
		rectVertexBuffer.unlock(bufferIndex * 4);
		g.setPipeline(pipeline.pipeline);
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setMatrix(pipeline.projectionLocation, projectionMatrix);

		g.drawIndexedVertices(0, bufferIndex * 3 * 2);

		bufferIndex = 0;
		rectVertices = rectVertexBuffer.lock();
	}

	public inline function drawSDFCircle(opacity: FastFloat, rCol:Color, bCol:Color,
		bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat, b: FastFloat, s: FastFloat): Void {
		if (bufferIndex + 1 >= bufferSize) drawBuffer();

		setRectColor(rCol.R, rCol.G, rCol.B, rCol.A * opacity, bCol.R, bCol.G, bCol.B);
		setRectTexCoords(0, 0, 1, 1);
		setRectVertices(bottomleftx, bottomlefty, topleftx, toplefty, toprightx, toprighty, bottomrightx, bottomrighty);
		setBorderSmooth(b, s);

		++bufferIndex;
	}

	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
	}
}


class SDFLinePainter {
	var projectionMatrix: FastMatrix4;
	static var standardSDFLinePipeline: PipelineCache = null;
	static var structure: VertexStructure = null;
	static inline var bufferSize: Int = 300;
	static inline var vertexSize: Int = 12;
	static var bufferIndex: Int;
	static var rectVertexBuffer: VertexBuffer;
	static var rectVertices: Float32Array;
	static var indexBuffer: IndexBuffer;
	var g: Graphics;
	var myPipeline: PipelineCache = null;
	public var pipeline(get, set): PipelineCache;

	public function new(g4: Graphics) {
		this.g = g4;
		bufferIndex = 0;
		initShaders();
		myPipeline = standardSDFLinePipeline;
		initBuffers();
	}

	private function get_pipeline(): PipelineCache {
		return myPipeline;
	}

	private function set_pipeline(pipe: PipelineCache): PipelineCache {
		myPipeline = pipe != null ? pipe : standardSDFLinePipeline;
		return myPipeline;
	}

	public function setProjection(projectionMatrix: FastMatrix4): Void {
		this.projectionMatrix = projectionMatrix;
	}

	private static function initShaders(): Void {
		if (structure == null) {
			structure = SDFPainter.createSDFLineVertexStructure();
		}
		if (standardSDFLinePipeline == null) {
			var pipeline = SDFPainter.createSDFLinePipeline(structure);
			pipeline.compile();
			standardSDFLinePipeline = new SimplePipelineCache(pipeline, false);
		}
	}

	function initBuffers(): Void {
		if (rectVertexBuffer == null) {
			rectVertexBuffer = new VertexBuffer(bufferSize * 4, structure, Usage.DynamicUsage);
			rectVertices = rectVertexBuffer.lock();

			indexBuffer = new IndexBuffer(bufferSize * 3 * 2, Usage.StaticUsage);
			var indices = indexBuffer.lock();
			for (i in 0...bufferSize) {
				indices[i * 3 * 2 + 0] = i * 4 + 0;
				indices[i * 3 * 2 + 1] = i * 4 + 1;
				indices[i * 3 * 2 + 2] = i * 4 + 2;
				indices[i * 3 * 2 + 3] = i * 4 + 0;
				indices[i * 3 * 2 + 4] = i * 4 + 2;
				indices[i * 3 * 2 + 5] = i * 4 + 3;
			}
			indexBuffer.unlock();
		}
	}

	private inline function setRectVertices(
		bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 0, bottomleftx);
		rectVertices.set(baseIndex + 1, bottomlefty);
		rectVertices.set(baseIndex + 2, -5.0);

		rectVertices.set(baseIndex + 12, topleftx);
		rectVertices.set(baseIndex + 13, toplefty);
		rectVertices.set(baseIndex + 14, -5.0);

		rectVertices.set(baseIndex + 24, toprightx);
		rectVertices.set(baseIndex + 25, toprighty);
		rectVertices.set(baseIndex + 26, -5.0);

		rectVertices.set(baseIndex + 36, bottomrightx);
		rectVertices.set(baseIndex + 37, bottomrighty);
		rectVertices.set(baseIndex + 38, -5.0);
	}

	private inline function setRectTexCoords(left: FastFloat, top: FastFloat, right: FastFloat, bottom: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex +  3, left);
		rectVertices.set(baseIndex +  4, bottom);

		rectVertices.set(baseIndex + 15, left);
		rectVertices.set(baseIndex + 16, top);

		rectVertices.set(baseIndex + 27, right);
		rectVertices.set(baseIndex + 28, top);

		rectVertices.set(baseIndex + 39, right);
		rectVertices.set(baseIndex + 40, bottom);
	}

	private inline function setRectColor(r: FastFloat, g: FastFloat, b: FastFloat, a: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 5, r);
		rectVertices.set(baseIndex + 6, g);
		rectVertices.set(baseIndex + 7, b);
		rectVertices.set(baseIndex + 8, a);

		rectVertices.set(baseIndex + 17, r);
		rectVertices.set(baseIndex + 18, g);
		rectVertices.set(baseIndex + 19, b);
		rectVertices.set(baseIndex + 20, a);

		rectVertices.set(baseIndex + 29, r);
		rectVertices.set(baseIndex + 30, g);
		rectVertices.set(baseIndex + 31, b);
		rectVertices.set(baseIndex + 32, a);

		rectVertices.set(baseIndex + 41, r);
		rectVertices.set(baseIndex + 42, g);
		rectVertices.set(baseIndex + 43, b);
		rectVertices.set(baseIndex + 44, a);
    }

    private inline function setDim(x: FastFloat, y: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 9, x);
		rectVertices.set(baseIndex + 10, y);

		rectVertices.set(baseIndex + 21, x);
		rectVertices.set(baseIndex + 22, y);

		rectVertices.set(baseIndex + 33, x);
		rectVertices.set(baseIndex + 34, y);

		rectVertices.set(baseIndex + 45, x);
		rectVertices.set(baseIndex + 46, y);
    }

    private inline function setSmooth(sm: FastFloat): Void {
		var baseIndex: Int = bufferIndex * vertexSize * 4;
		rectVertices.set(baseIndex + 11, sm);
		rectVertices.set(baseIndex + 23, sm);
		rectVertices.set(baseIndex + 35, sm);
		rectVertices.set(baseIndex + 47, sm);
    }

	private function drawBuffer(): Void {
		var pipeline = myPipeline.get(null, Depth24Stencil8);
		rectVertexBuffer.unlock(bufferIndex * 4);
		g.setPipeline(pipeline.pipeline);
		g.setVertexBuffer(rectVertexBuffer);
		g.setIndexBuffer(indexBuffer);
		g.setMatrix(pipeline.projectionLocation, projectionMatrix);

		g.drawIndexedVertices(0, bufferIndex * 3 * 2);

		bufferIndex = 0;
		rectVertices = rectVertexBuffer.lock();
	}

	public inline function drawSDFLine(opacity: FastFloat, color:Color,
		bottomleftx: FastFloat, bottomlefty: FastFloat,
		topleftx: FastFloat, toplefty: FastFloat,
		toprightx: FastFloat, toprighty: FastFloat,
		bottomrightx: FastFloat, bottomrighty: FastFloat,
		u: FastFloat, v: FastFloat, smth: FastFloat): Void {

		if (bufferIndex + 1 >= bufferSize) drawBuffer();

		setRectColor(color.R, color.G, color.B, color.A * opacity);
		setRectTexCoords(0, 0, u, v);
		setRectVertices(bottomleftx, bottomlefty, topleftx, toplefty, toprightx, toprighty, bottomrightx, bottomrighty);
		setDim(u / 2.0, v / 2.0);
		setSmooth(smth);

		++bufferIndex;
	}

	public function end(): Void {
		if (bufferIndex > 0) drawBuffer();
	}
}


class SDFPainter extends kha.graphics4.Graphics2 {
	private var sdfRectPainter: SDFRectPainter;
	private var sdfCirclePainter: SDFCirclePainter;
	private var sdfLinePainter: SDFLinePainter;

	public override function new(canvas: Canvas) {
		super(canvas);
	}

	public function sdfRect(x: FastFloat, y: FastFloat, width: FastFloat, height: FastFloat, 
			corner: CornerRadius, border: FastFloat, borderColor: Color, smooth: FastFloat,
			?bottomleftColor: Color, ?topleftColor: Color, 
			?toprightColor: Color, ?bottomrightColor: Color): Void {
		imagePainter.end();
		textPainter.end();
		coloredPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();

		if (bottomleftColor == null && topleftColor == null && 
				toprightColor == null && bottomrightColor == null) {
			bottomleftColor = topleftColor = toprightColor = bottomrightColor = color;
		}
		var p1 = transformation.multvec(new FastVector2(x, y + height));
		var p2 = transformation.multvec(new FastVector2(x, y));
		var p3 = transformation.multvec(new FastVector2(x + width, y));
		var p4 = transformation.multvec(new FastVector2(x + width, y + height));
		var w = p3.sub(p2).length;
		var h = p1.sub(p2).length;
		var u = w / Math.max(w, h);
		var v = h / Math.max(w, h);
		var f = (u >= v ? u / w : v / h) * Math.max(w / width, h / height);
		corner.br = corner.br != null ? corner.br : corner.tr;
		corner.tl = corner.tl != null ? corner.tl : corner.tr;
		corner.bl = corner.bl != null ? corner.bl : corner.tr;
		corner.tr *= f;
		corner.br *= f;
		corner.tl *= f;
		corner.bl *= f;
		sdfRectPainter.drawSDFRect(opacity, bottomleftColor, topleftColor, toprightColor, bottomrightColor, borderColor, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, u, v, corner, border * f, smooth * f);
	}

	public function sdfCircle(x: FastFloat, y: FastFloat, r: FastFloat, border: FastFloat, borderColor: Color, smooth: FastFloat): Void {
		imagePainter.end();
		textPainter.end();
		coloredPainter.end();
		sdfRectPainter.end();
		sdfLinePainter.end();

		var p1 = transformation.multvec(new FastVector2(x - r, y + r));
		var p2 = transformation.multvec(new FastVector2(x - r, y - r));
		var p3 = transformation.multvec(new FastVector2(x + r, y - r));
		var p4 = transformation.multvec(new FastVector2(x + r, y + r));
		var w = p3.sub(p2).length;
		var h = p1.sub(p2).length;
		var u = w / Math.max(w, h);
		var v = h / Math.max(w, h);
		var f = (u >= v ? u / w : v / h) * Math.max(w / (2 * r), h / (2 * r));
		sdfCirclePainter.drawSDFCircle(opacity, color, borderColor, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, border * f, smooth * f);
	}

	public function sdfLine(x1: FastFloat, y1: FastFloat, x2: FastFloat, y2: FastFloat, strength: FastFloat, smooth: FastFloat): Void {
		imagePainter.end();
		textPainter.end();
		coloredPainter.end();
		sdfCirclePainter.end();
		sdfRectPainter.end();

		var a = x1 <= x2 ? new FastVector2(x1, y1) : new FastVector2(x2, y2);
		var b = x1 <= x2 ? new FastVector2(x2, y2) : new FastVector2(x1, y1);
		var fw = b.sub(a).normalized();
		var bw = fw.mult(-1.0);
		var up = new FastVector2(fw.y, -fw.x);
		var down = up.mult(-1.0);
		var hs = strength / 2.0;
		fw = fw.mult(hs);
		bw = bw.mult(hs);
		up = up.mult(hs);
		down = down.mult(hs);

		var p1 = transformation.multvec(a.add(down).add(bw));
		var p2 = transformation.multvec(a.add(up).add(bw));
		var p3 = transformation.multvec(b.add(up).add(fw));
		var p4 = transformation.multvec(b.add(down).add(fw));
		var w = p3.sub(p2).length;
		var h = p1.sub(p2).length;
		var u = w / Math.max(w, h);
		var v = h / Math.max(w, h);
		var f = (u >= v ? u / w : v / h) * Math.max(w / a.sub(b).length, h / strength);

		sdfLinePainter.drawSDFLine(opacity, color, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y, p4.x, p4.y, u, v, smooth * f);
	}

	// Overrides
	public override function flush(): Void {
		super.flush();
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
	}

	private override function setProjection(): Void {
		super.setProjection();
		sdfRectPainter = new SDFRectPainter(g);
		sdfRectPainter.setProjection(projectionMatrix);
		sdfCirclePainter = new SDFCirclePainter(g);
		sdfCirclePainter.setProjection(projectionMatrix);
		sdfLinePainter = new SDFLinePainter(g);
		sdfLinePainter.setProjection(projectionMatrix);
	}

	public override function drawImage(img: kha.Image, x: FastFloat, y: FastFloat): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawImage(img, x, y);
	}

	public override function drawScaledSubImage(img: kha.Image, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawScaledSubImage(img, sx, sy, sw, sh, dx, dy, dw, dh);
	}

	public override function drawRect(x: Float, y: Float, width: Float, height: Float, strength: Float = 1.0): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawRect(x, y, width, height, strength);
	}

	public override function fillRect(x: Float, y: Float, width: Float, height: Float): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.fillRect(x, y, width, height);
	}

	public override function drawString(text: String, x: Float, y: Float): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawString(text, x, y);
	}

	public override function drawCharacters(text: Array<Int>, start: Int, length: Int, x: Float, y: Float): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawCharacters(text, start, length, x, y);
	}

	public override function drawLine(x1: Float, y1: Float, x2: Float, y2: Float, strength: Float = 1.0): Void {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.drawLine(x1, y1, x2, y2, strength);
	}

	public override function fillTriangle(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) {
		sdfRectPainter.end();
		sdfCirclePainter.end();
		sdfLinePainter.end();
		super.fillTriangle(x1, y1, x2, y2, x3, y3);
	}

	override private function setPipeline(pipeline: PipelineState): Void {
		if (pipeline == lastPipeline) {
			return;
		}
		lastPipeline = pipeline;
		flush();
		if (pipeline == null) {
			imagePainter.pipeline = null;
			coloredPainter.pipeline = null;
			textPainter.pipeline = null;
			sdfRectPainter.pipeline = null;
			sdfCirclePainter.pipeline = null;
			sdfLinePainter.pipeline = null;
		}
		else {
			var cache = pipelineCache[pipeline];
			if (cache == null) {
				cache = new SimplePipelineCache(pipeline, true);
				pipelineCache[pipeline] = cache;
			}
			imagePainter.pipeline = cache;
			coloredPainter.pipeline = cache;
			textPainter.pipeline = cache;
			sdfRectPainter.pipeline = cache;
			sdfCirclePainter.pipeline = cache;
			sdfLinePainter.pipeline = cache;
		}
	}

	public static function createSDFRectVertexStructure(): VertexStructure {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("tex", VertexData.Float2);
		structure.add("box", VertexData.Float2);
		structure.add("rCol", VertexData.Float4);
		structure.add("bCol", VertexData.Float3);
		structure.add("corner", VertexData.Float4);
		structure.add("border", VertexData.Float1);
		structure.add("smth", VertexData.Float1);
		return structure;
	}

	public static function createSDFRectPipeline(structure: VertexStructure): PipelineState {
		var shaderPipeline = new PipelineState();
		shaderPipeline.fragmentShader = Shaders.painter_sdf_rect_frag;
		shaderPipeline.vertexShader = Shaders.painter_sdf_rect_vert;
		shaderPipeline.inputLayout = [structure];
		shaderPipeline.blendSource = BlendingFactor.BlendOne;
		shaderPipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		shaderPipeline.alphaBlendSource = BlendingFactor.BlendOne;
		shaderPipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
		return shaderPipeline;
	}

	public static function createSDFCircleVertexStructure(): VertexStructure {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("tex", VertexData.Float2);
		structure.add("rCol", VertexData.Float4);
		structure.add("bCol", VertexData.Float3);
		structure.add("border", VertexData.Float1);
		structure.add("smth", VertexData.Float1);
		return structure;
	}

	public static function createSDFCirclePipeline(structure: VertexStructure): PipelineState {
		var shaderPipeline = new PipelineState();
		shaderPipeline.fragmentShader = Shaders.painter_sdf_circle_frag;
		shaderPipeline.vertexShader = Shaders.painter_sdf_circle_vert;
		shaderPipeline.inputLayout = [structure];
		shaderPipeline.blendSource = BlendingFactor.BlendOne;
		shaderPipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		shaderPipeline.alphaBlendSource = BlendingFactor.BlendOne;
		shaderPipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
		return shaderPipeline;
	}

	public static function createSDFLineVertexStructure(): VertexStructure {
		var structure = new VertexStructure();
		structure.add("pos", VertexData.Float3);
		structure.add("tex", VertexData.Float2);
		structure.add("color", VertexData.Float4);
		structure.add("dim", VertexData.Float2);
		structure.add("smth", VertexData.Float1);
		return structure;
	}

	public static function createSDFLinePipeline(structure: VertexStructure): PipelineState {
		var shaderPipeline = new PipelineState();
		shaderPipeline.fragmentShader = Shaders.painter_sdf_line_frag;
		shaderPipeline.vertexShader = Shaders.painter_sdf_line_vert;
		shaderPipeline.inputLayout = [structure];
		shaderPipeline.blendSource = BlendingFactor.BlendOne;
		shaderPipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
		shaderPipeline.alphaBlendSource = BlendingFactor.BlendOne;
		shaderPipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
		return shaderPipeline;
	}
}

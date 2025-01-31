@addField(inkImage)
native let useNineSliceScale: Bool;

@addField(inkImage)
native let nineSliceScale: inkMargin;

@addField(inkImage)
native let tileHAlign: inkEHorizontalAlign;

@addField(inkImage)
native let tileVAlign: inkEVerticalAlign;

@addMethod(inkImage)
public func UsesNineSliceScale() -> Bool {
    return this.useNineSliceScale;
}

@addMethod(inkImage)
public func SetNineSliceScale(enable: Bool) -> Void {
    this.useNineSliceScale = enable;
}

@addMethod(inkImage)
public func GetNineSliceGrid() -> inkMargin {
    return this.nineSliceScale;
}

@addMethod(inkImage)
public func SetNineSliceGrid(grid: inkMargin) -> Void {
    this.nineSliceScale = grid;
}

@addMethod(inkImage)
public func GetTileHAlign() -> inkEHorizontalAlign {
    return this.tileHAlign;
}

@addMethod(inkImage)
public func SetTileHAlign(tileHAlign: inkEHorizontalAlign) -> Void {
    this.tileHAlign = tileHAlign;
}

@addMethod(inkImage)
public func GetTileVAlign() -> inkEVerticalAlign {
    return this.tileVAlign;
}

@addMethod(inkImage)
public func SetTileVAlign(tileVAlign: inkEVerticalAlign) -> Void {
    this.tileVAlign = tileVAlign;
}

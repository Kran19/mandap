var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { IsString, IsNumber, IsOptional, IsArray, ValidateNested, IsBoolean, Equals, IsDefined, ArrayMaxSize, Validate, ValidatorConstraint } from 'class-validator';
import { Type } from 'class-transformer';
export var NodeType;
(function (NodeType) {
    NodeType["CORNER"] = "corner";
    NodeType["GENERATED_SUPPORT"] = "generatedSupport";
    NodeType["OPEN_END"] = "openEnd";
    NodeType["JUNCTION"] = "junction";
})(NodeType || (NodeType = {}));
class MandapNode {
    id;
    x;
    z;
    type;
    isLocked;
    width;
    depth;
    height;
    rotation;
    elevation;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapNode.prototype, "id", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapNode.prototype, "x", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapNode.prototype, "z", void 0);
__decorate([
    IsString(),
    IsOptional(),
    __metadata("design:type", String)
], MandapNode.prototype, "type", void 0);
__decorate([
    IsBoolean(),
    IsOptional(),
    __metadata("design:type", Boolean)
], MandapNode.prototype, "isLocked", void 0);
__decorate([
    IsNumber(),
    IsOptional(),
    __metadata("design:type", Number)
], MandapNode.prototype, "width", void 0);
__decorate([
    IsNumber(),
    IsOptional(),
    __metadata("design:type", Number)
], MandapNode.prototype, "depth", void 0);
__decorate([
    IsNumber(),
    IsOptional(),
    __metadata("design:type", Number)
], MandapNode.prototype, "height", void 0);
__decorate([
    IsNumber(),
    IsOptional(),
    __metadata("design:type", Number)
], MandapNode.prototype, "rotation", void 0);
__decorate([
    IsNumber(),
    IsOptional(),
    __metadata("design:type", Number)
], MandapNode.prototype, "elevation", void 0);
class MandapEdge {
    id;
    startNodeId;
    endNodeId;
    requestedLength;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapEdge.prototype, "id", void 0);
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapEdge.prototype, "startNodeId", void 0);
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapEdge.prototype, "endNodeId", void 0);
__decorate([
    IsOptional(),
    __metadata("design:type", Object)
], MandapEdge.prototype, "requestedLength", void 0);
class MandapZone {
    id;
    type;
    x1;
    y1;
    x2;
    y2;
}
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapZone.prototype, "id", void 0);
__decorate([
    IsString(),
    __metadata("design:type", String)
], MandapZone.prototype, "type", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapZone.prototype, "x1", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapZone.prototype, "y1", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapZone.prototype, "x2", void 0);
__decorate([
    IsNumber(),
    __metadata("design:type", Number)
], MandapZone.prototype, "y2", void 0);
export class MandapLayout {
    nodes;
    edges;
    zones;
}
__decorate([
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => MandapNode),
    ArrayMaxSize(1000),
    __metadata("design:type", Array)
], MandapLayout.prototype, "nodes", void 0);
__decorate([
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => MandapEdge),
    ArrayMaxSize(1000),
    __metadata("design:type", Array)
], MandapLayout.prototype, "edges", void 0);
__decorate([
    IsArray(),
    ValidateNested({ each: true }),
    Type(() => MandapZone),
    IsOptional(),
    ArrayMaxSize(1000),
    __metadata("design:type", Array)
], MandapLayout.prototype, "zones", void 0);
let LayoutSizeConstraint = class LayoutSizeConstraint {
    validate(layoutData, args) {
        if (!layoutData)
            return true;
        const size = Buffer.byteLength(JSON.stringify(layoutData));
        return size <= 5 * 1024 * 1024;
    }
    defaultMessage(args) {
        return 'Layout data exceeds the 5MB payload limit';
    }
};
LayoutSizeConstraint = __decorate([
    ValidatorConstraint({ name: 'layoutSize', async: false })
], LayoutSizeConstraint);
export { LayoutSizeConstraint };
export class LayoutDataEnvelope {
    schemaVersion;
    layout;
}
__decorate([
    IsNumber(),
    Equals(1),
    __metadata("design:type", Number)
], LayoutDataEnvelope.prototype, "schemaVersion", void 0);
__decorate([
    ValidateNested(),
    Type(() => MandapLayout),
    IsDefined(),
    __metadata("design:type", MandapLayout)
], LayoutDataEnvelope.prototype, "layout", void 0);
export class CreateProjectVersionDto {
    expectedCurrentVersionId;
    layoutData;
}
__decorate([
    IsString(),
    IsOptional(),
    __metadata("design:type", String)
], CreateProjectVersionDto.prototype, "expectedCurrentVersionId", void 0);
__decorate([
    IsDefined(),
    Validate(LayoutSizeConstraint),
    ValidateNested(),
    Type(() => LayoutDataEnvelope),
    __metadata("design:type", LayoutDataEnvelope)
], CreateProjectVersionDto.prototype, "layoutData", void 0);
//# sourceMappingURL=layout.validator.js.map
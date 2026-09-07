import { ValidationArguments, ValidatorConstraintInterface } from 'class-validator';
export declare enum NodeType {
    CORNER = "corner",
    GENERATED_SUPPORT = "generatedSupport",
    OPEN_END = "openEnd",
    JUNCTION = "junction"
}
declare class MandapNode {
    id: string;
    x: number;
    z: number;
    type?: string;
    isLocked?: boolean;
    width?: number;
    depth?: number;
    height?: number;
    rotation?: number;
    elevation?: number;
}
declare class MandapEdge {
    id: string;
    startNodeId: string;
    endNodeId: string;
    requestedLength?: any;
}
declare class MandapZone {
    id: string;
    type: string;
    x1: number;
    y1: number;
    x2: number;
    y2: number;
}
export declare class MandapLayout {
    nodes: MandapNode[];
    edges: MandapEdge[];
    zones?: MandapZone[];
}
export declare class LayoutSizeConstraint implements ValidatorConstraintInterface {
    validate(layoutData: any, args: ValidationArguments): boolean;
    defaultMessage(args: ValidationArguments): string;
}
export declare class LayoutDataEnvelope {
    schemaVersion: number;
    layout: MandapLayout;
}
export declare class CreateProjectVersionDto {
    expectedCurrentVersionId?: string;
    layoutData: LayoutDataEnvelope;
}
export {};

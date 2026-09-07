import { IsString, IsNumber, IsOptional, IsArray, ValidateNested, IsBoolean, Equals, Max, IsDefined, ArrayMaxSize, Validate, ValidationArguments, ValidatorConstraint, ValidatorConstraintInterface, Min } from 'class-validator';
import { Type } from 'class-transformer';

export enum NodeType {
  CORNER = 'corner',
  GENERATED_SUPPORT = 'generatedSupport',
  OPEN_END = 'openEnd',
  JUNCTION = 'junction',
}

class MandapNode {
  @IsString()
  id: string;

  @IsNumber()
  x: number;

  @IsNumber()
  z: number;

  @IsString()
  @IsOptional()
  type?: string;

  @IsBoolean()
  @IsOptional()
  isLocked?: boolean;

  @IsNumber()
  @IsOptional()
  width?: number;

  @IsNumber()
  @IsOptional()
  depth?: number;

  @IsNumber()
  @IsOptional()
  height?: number;

  @IsNumber()
  @IsOptional()
  rotation?: number;

  @IsNumber()
  @IsOptional()
  elevation?: number;
}

class MandapEdge {
  @IsString()
  id: string;

  @IsString()
  startNodeId: string;

  @IsString()
  endNodeId: string;

  @IsOptional()
  requestedLength?: any;
}

class MandapZone {
  @IsString()
  id: string;

  @IsString()
  type: string;

  @IsNumber()
  x1: number;

  @IsNumber()
  y1: number;

  @IsNumber()
  x2: number;

  @IsNumber()
  y2: number;
}

export class MandapLayout {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MandapNode)
  @ArrayMaxSize(1000)
  nodes: MandapNode[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MandapEdge)
  @ArrayMaxSize(1000)
  edges: MandapEdge[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => MandapZone)
  @IsOptional()
  @ArrayMaxSize(1000)
  zones?: MandapZone[];
}

@ValidatorConstraint({ name: 'layoutSize', async: false })
export class LayoutSizeConstraint implements ValidatorConstraintInterface {
  validate(layoutData: any, args: ValidationArguments) {
    if (!layoutData) return true;
    const size = Buffer.byteLength(JSON.stringify(layoutData));
    // 5 MB limit
    return size <= 5 * 1024 * 1024;
  }
  defaultMessage(args: ValidationArguments) {
    return 'Layout data exceeds the 5MB payload limit';
  }
}

export class LayoutDataEnvelope {
  @IsNumber()
  @Equals(1)
  schemaVersion: number;

  @ValidateNested()
  @Type(() => MandapLayout)
  @IsDefined()
  layout: MandapLayout;
}

export class CreateProjectVersionDto {
  @IsString()
  @IsOptional()
  expectedCurrentVersionId?: string;

  @IsDefined()
  @Validate(LayoutSizeConstraint)
  @ValidateNested()
  @Type(() => LayoutDataEnvelope)
  layoutData: LayoutDataEnvelope;
}



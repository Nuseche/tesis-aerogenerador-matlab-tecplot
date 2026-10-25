#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.4 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/seguimiento_ramas.dat"'
$!PlotType = XYLine
$!DeleteLineMaps
$!BasicColor CUSTOM1 { R = 20 G = 20 B = 20 }
$!BasicColor CUSTOM2 { R = 90 G = 90 B = 90 }
$!BasicColor CUSTOM3 { R = 45 G = 45 B = 45 }
$!BasicColor CUSTOM4 { R = 115 G = 115 B = 115 }
$!BasicColor CUSTOM5 { R = 150 G = 150 B = 150 }
$!BasicColor CUSTOM6 { R = 175 G = 175 B = 175 }
$!BasicColor CUSTOM7 { R = 30 G = 30 B = 30 }
$!BasicColor CUSTOM8 { R = 200 G = 200 B = 200 }
$!PrintSetup Palette = Color
$!CreateLineMap
$!LineMap [1] Name = 'Rama 1' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [2] Name = 'Rama 2' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [3] Name = 'Rama 3' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [4] Name = 'Rama 4' Assign { Zone = 4 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM4 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM4 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Del } }
$!CreateLineMap
$!LineMap [5] Name = 'Rama 5' Assign { Zone = 5 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM5 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM5 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Grad } }
$!CreateLineMap
$!LineMap [6] Name = 'Rama 6' Assign { Zone = 6 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM6 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM6 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = RTri } }
$!CreateLineMap
$!LineMap [7] Name = 'Rama 7' Assign { Zone = 7 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM7 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = LTri } }
$!CreateLineMap
$!LineMap [8] Name = 'Rama 8' Assign { Zone = 8 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [9] Name = 'Rama 9' Assign { Zone = 9 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [10] Name = 'Rama 10' Assign { Zone = 10 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [11] Name = 'Rama 11' Assign { Zone = 11 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [12] Name = 'Rama 12' Assign { Zone = 12 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM4 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM4 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Del } }
$!ActiveLineMaps = [1-12]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 70 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -0.96 RangeMax = 12.96 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'Velocidad [rpm]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 0.8228647950526894 RangeMax = 1.013121126292393 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'MAC efectivo [-]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = Yes TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/seguimiento_ramas.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/seguimiento_ramas.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/seguimiento_ramas.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/seguimiento_ramas.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/seguimiento_ramas.png'
$!Export ExportRegion = CurrentFrame

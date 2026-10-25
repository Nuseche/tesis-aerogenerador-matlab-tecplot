#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 5.6 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_gondola.dat"'
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
$!LineMap [1] Name = '' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [2] Name = '' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [3] Name = '' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [4] Name = '' Assign { Zone = 4 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [5] Name = '' Assign { Zone = 5 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [6] Name = '' Assign { Zone = 6 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [7] Name = '' Assign { Zone = 7 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [8] Name = '' Assign { Zone = 8 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [9] Name = '' Assign { Zone = 9 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [10] Name = 'Eje / conexion N-H' Assign { Zone = 10 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = No Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!ActiveLineMaps = [1-10]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 94 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -10 RangeMax = 16 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'X [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 129.4851851851852 RangeMax = 149.5148148148148 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'Z [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = No TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!AttachText AnchorPos { X = 44.932692 Y = 38.254808 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '20'
$!AttachText AnchorPos { X = 35.622054 Y = 63.723077 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '129'
$!AttachText AnchorPos { X = 43.898198 Y = 41.097596 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '131'
$!AttachText AnchorPos { X = 42.863672 Y = 43.901442 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '132'
$!AttachText AnchorPos { X = 41.829177 Y = 46.744231 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '133'
$!AttachText AnchorPos { X = 40.794527 Y = 49.587019 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '134'
$!AttachText AnchorPos { X = 39.760219 Y = 52.390865 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '135'
$!AttachText AnchorPos { X = 38.7256 Y = 55.233654 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '136'
$!AttachText AnchorPos { X = 37.690981 Y = 58.076442 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '137'
$!AttachText AnchorPos { X = 36.656673 Y = 60.880288 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 8 IsBold = No } Color = CUSTOM7 Text = '138'
$!AttachText AnchorPos { X = 73.75 Y = 73.692308 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 10 IsBold = No } Color = CUSTOM2 Text = '130: cubo'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/detalle_gondola.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_gondola.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/detalle_gondola.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_gondola.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/detalle_gondola.png'
$!Export ExportRegion = CurrentFrame

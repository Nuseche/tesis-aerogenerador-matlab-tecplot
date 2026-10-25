#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.4 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/local_signos.dat"'
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
$!LineMap [1] Name = 'Masa/inercia de palas' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [2] Name = '' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = No Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [3] Name = 'Rigidez de palas' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [4] Name = '' Assign { Zone = 4 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = No Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [5] Name = 'Amortiguamiento' Assign { Zone = 5 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM3 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [6] Name = 'Masa/inercia del cubo' Assign { Zone = 6 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM4 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM4 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Del } }
$!CreateLineMap
$!LineMap [7] Name = 'Masa/inercia de gondola' Assign { Zone = 7 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM5 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM5 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Grad } }
$!CreateLineMap
$!LineMap [8] Name = 'Velocidad' Assign { Zone = 8 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM6 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM6 FillColor = CUSTOM6 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = RTri } }
$!CreateLineMap
$!LineMap [9] Name = '' Assign { Zone = 9 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Never } Lines { Show = No Color = CUSTOM6 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM6 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = RTri } }
$!CreateLineMap
$!LineMap [10] Name = 'Masa/inercia de torre' Assign { Zone = 10 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM7 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM7 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = LTri } }
$!CreateLineMap
$!LineMap [11] Name = 'Rigidez de torre' Assign { Zone = 11 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = No Color = CUSTOM8 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM8 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!ActiveLineMaps = [1-11]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 58 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 0.7 RangeMax = 4.7 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'Indice de grupo' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -0.49 RangeMax = 0.6 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'Sensibilidad normalizada [-]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = Yes TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/local_signos.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/local_signos.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/local_signos.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/local_signos.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/local_signos.png'
$!Export ExportRegion = CurrentFrame

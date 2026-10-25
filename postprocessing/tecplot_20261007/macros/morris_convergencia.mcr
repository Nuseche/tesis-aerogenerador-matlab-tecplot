#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.4 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/morris_convergencia.dat"'
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
$!LineMap [1] Name = '6+7 Masa/inercia' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = CUSTOM1 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [2] Name = '6+7 Rigidez' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = CUSTOM3 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [3] Name = '6+7 Velocidad' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = CUSTOM2 FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [4] Name = '10+11 Masa/inercia' Assign { Zone = 4 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [5] Name = '10+11 Rigidez' Assign { Zone = 5 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!CreateLineMap
$!LineMap [6] Name = '10+11 Velocidad' Assign { Zone = 6 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = DASHED PatternLength = 2 } Symbols { Show = Yes Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!ActiveLineMaps = [1-6]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 58 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 7.6 RangeMax = 42.4 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 'Trayectorias' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = 0.0334830322653201 RangeMax = 0.0798416534809515 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = '<greek>m</greek>* [-]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = Yes TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/morris_convergencia.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/morris_convergencia.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/morris_convergencia.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/morris_convergencia.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/morris_convergencia.png'
$!Export ExportRegion = CurrentFrame

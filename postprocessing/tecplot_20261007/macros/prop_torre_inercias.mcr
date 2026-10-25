#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.4 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/prop_torre_inercias.dat"'
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
$!LineMap [1] Name = 'J<sub>x</sub>' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = No Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Circle } }
$!CreateLineMap
$!LineMap [2] Name = 'J<sub>y</sub>' Assign { Zone = 2 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM2 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = No Color = CUSTOM2 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Square } }
$!CreateLineMap
$!LineMap [3] Name = 'J<sub>z</sub>' Assign { Zone = 3 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM3 LineThickness = 0.3 LinePattern = SOLID PatternLength = 2 } Symbols { Show = No Color = CUSTOM3 FillColor = WHITE FillMode = UseSpecificColor Size = 0.85 SymbolShape { IsASCII = No GeomShape = Diamond } }
$!ActiveLineMaps = [1-3]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 70 Y1 = 16 Y2 = 94 }
$!XYLineAxis GridArea { DrawBorder = No }
$!XYLineAxis XDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -10.8 RangeMax = 145.8 CoordScale = Linear Title { TitleMode = UseText Offset = 6 Text = 's [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes AxisLine { Show = Yes } RangeMin = -2634.3658 RangeMax = 292683.2308 CoordScale = Linear Title { TitleMode = UseText Offset = 9 Text = 'kg m' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.06 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = Yes TextShape { SizeUnits = POINT Height = 10 IsBold = No } XYPos { X = 99 Y = 87 } }
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/prop_torre_inercias.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/prop_torre_inercias.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/prop_torre_inercias.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/prop_torre_inercias.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/prop_torre_inercias.png'
$!Export ExportRegion = CurrentFrame

#!MC 1410
$!NewLayout
$!FrameLayout Width = 7 Height = 4.4 ShowBorder = No
$!ReadDataSet '"/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/chart_probe.dat"'
$!PlotType = XYLine
$!DeleteLineMaps
$!BasicColor CUSTOM1 { R = 0 G = 114 B = 178 }
$!BasicColor CUSTOM2 { R = 213 G = 94 B = 0 }
$!BasicColor CUSTOM3 { R = 0 G = 158 B = 115 }
$!BasicColor CUSTOM4 { R = 204 G = 121 B = 167 }
$!BasicColor CUSTOM5 { R = 86 G = 180 B = 233 }
$!BasicColor CUSTOM6 { R = 160 G = 110 B = 0 }
$!BasicColor CUSTOM7 { R = 75 G = 75 B = 75 }
$!BasicColor CUSTOM8 { R = 145 G = 145 B = 145 }
$!CreateLineMap
$!LineMap [1] Name = 'Data' Assign { Zone = 1 XAxisVar = 1 YAxisVar = 2 ShowInLegend = Always } Lines { Show = Yes Color = CUSTOM1 LineThickness = 0.35 LinePattern = SOLID } Symbols { Show = Yes Color = CUSTOM1 FillColor = WHITE FillMode = UseSpecificColor Size = 1.1 }
$!ActiveLineMaps = [1-1]
$!XYLineAxis ViewportPosition { X1 = 13 X2 = 94 Y1 = 17 Y2 = 88 }
$!XYLineAxis XDetail 1 { ShowAxis = Yes RangeMin = 0 RangeMax = 3 CoordScale = Linear Title { Text = 'x [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.08 } }
$!XYLineAxis YDetail 1 { ShowAxis = Yes RangeMin = 0 RangeMax = 5 CoordScale = Linear Title { Text = 'y [m]' TextShape { SizeUnits = POINT Height = 11 IsBold = No } } TickLabel { TextShape { SizeUnits = POINT Height = 10 IsBold = No } } GridLines { Show = Yes Color = CUSTOM8 LineThickness = 0.08 } }
$!LinePlotLayers ShowSymbols = Yes
$!GlobalLinePlot Legend { Show = Yes TextShape { SizeUnits = POINT Height = 9 IsBold = No } XYPos { X = 94 Y = 87 } }
$!AttachText AnchorPos { X = 50 Y = 96 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 12 } Color = BLACK Text = 'Stored data export test'
$!AttachText AnchorPos { X = 40 Y = 59.6 } Anchor = CENTER TextShape { FontFamily = 'Helvetica' SizeUnits = POINT Height = 14 } Color = CUSTOM7 Text = 'Tecplot'
$!WriteDataSet '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/data/chart_probe.plt' Binary = Yes IncludeText = Yes IncludeGeom = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/chart_probe.lay' UseRelativePaths = Yes
$!SaveLayout '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/layouts/chart_probe.lpk' IncludeData = Yes IncludePreview = Yes
$!ExportSetup ExportFormat = EPS
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/chart_probe.eps'
$!Export ExportRegion = CurrentFrame
$!ExportSetup ExportFormat = PNG
$!ExportSetup ImageWidth = 2100
$!ExportSetup ExportFName = '/Users/nuseche/Desktop/Tesis_codigos/postprocessing/tecplot_20261007/figures/chart_probe.png'
$!Export ExportRegion = CurrentFrame

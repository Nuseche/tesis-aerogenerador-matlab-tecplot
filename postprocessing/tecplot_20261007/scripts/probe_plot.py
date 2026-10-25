from common import *
f=Figure('chart_probe','Stored data export test',kind='result',xlabel='x [m]',ylabel='y [m]',bounds=[0,3,0,5])
f.line([[0,0],[1,1],[2,4]],'Data',symbols=True)
f.label(1,3,'Tecplot',14)
write_figure(f)
run_macro(HERE/'macros/chart_probe.mcr')
print('done')

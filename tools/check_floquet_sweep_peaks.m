function check_floquet_sweep_peaks(levels)
if nargin<1,levels=[0.5 1 2 5];end
root=fileparts(fileparts(mfilename('fullpath')));
data=fullfile(root,'runs','periodic_loads_20261118'); out=fullfile(root,'runs','stability_20261119');
for z=levels
    peakFile=fullfile(data,sprintf('damping_summary_%d.csv',round(z*10)));
    t=readtable(peakFile);
    speeds=unique([3.394,3.4445,3.49,t.periodicPeakRpm,t.averagePeakRpm,t.maxErrorRpm]);
    for rpm=speeds
        if ~isfile(fullfile(out,sprintf('arnoldi_266_%g_%g_128.mat',rpm,z)))
            check_floquet_leading(266,rpm,z,128);
        end
    end
end
end

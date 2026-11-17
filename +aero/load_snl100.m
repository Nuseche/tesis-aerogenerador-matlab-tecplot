function data=load_snl100(folder)
%LOAD_SNL100 Sandia external geometry and separately attributed section polars.
if nargin<1,folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','aerodynamics','snl100_00');end
data.geometry=readtable(fullfile(folder,'geometry.csv'),'TextType','string');
data.provenance=jsondecode(fileread(fullfile(folder,'provenance.json')));
% Thickness interpolation is an explicit section-model approximation, not UVLM.
data.thickness=[.18 .21 .25 .30 .35 .405 1];
ids=["NACA64_A17" "DU21_A17" "DU25_A17" "DU30_A17" "DU35_A17" "DU40_A17" "Cylinder1"];
for k=1:numel(ids)
    p=readtable(fullfile(folder,'polars',ids(k)+".csv"));
    assert(all(diff(p.alpha_deg)>0)&&all(p.cd>=0),'Invalid polar table.');
    data.lookup{k}=griddedInterpolant(p.alpha_deg,[p.cl p.cd p.cm],'linear','none');
end
% Fractional thickness at the 34 published stations (modified sections included).
data.geometry.thickness=[1 1 .9925 .985 .9775 .97 .931 .925 .84 .76 .68 .60 .51 .47 .435 .405 .38 .36 .34 .30 .26 .23 .21 .19 .185 .18 .18 .18 .18 .18 .18 .18 .18 .18].';
end

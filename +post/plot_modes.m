function figures = plot_modes(modelData, modalResults, folder, cfg)
%PLOT_MODES Export selected full-coordinate modal shapes.

if nargin < 4, cfg = struct(); end
[shapes, frequencies] = localFindShapes(modalResults);
figures = gobjects(0);
if isempty(shapes), return; end
nPlot = min(6, size(shapes,2));
if isfield(cfg,'output') && isfield(cfg.output,'modesToPlot')
    nPlot = min(cfg.output.modesToPlot, size(shapes,2));
end
xyz = modelData.mesh.nodes.xyz;
elements = modelData.mesh.elements;
nNodes = size(xyz,1);
if size(shapes,1) < 6*nNodes, return; end
for modeIndex = 1:nPlot
    phi = real(shapes(:,modeIndex));
    u = reshape(phi(1:6*nNodes), 6, nNodes).'; u = u(:,1:3);
    span = max(xyz,[],1)-min(xyz,[],1);
    scale = 0.05*max(span)/max(vecnorm(u,2,2),eps);
    deformed = xyz + scale*u;
    fig = figure('Visible','off','Color','w'); ax = axes(fig);
    hold(ax,'on'); grid(ax,'on'); box(ax,'on'); axis(ax,'equal');
    for e = 1:numel(elements.nodeI)
        ij = [elements.nodeI(e), elements.nodeJ(e)];
        plot3(ax, xyz(ij,1),xyz(ij,2),xyz(ij,3),'-','Color',[.75 .75 .75]);
        plot3(ax, deformed(ij,1),deformed(ij,2),deformed(ij,3),'-b','LineWidth',1.2);
    end
    if modeIndex <= numel(frequencies)
        title(ax,sprintf('Mode %d, %.4g Hz',modeIndex,frequencies(modeIndex)));
    else
        title(ax,sprintf('Mode %d',modeIndex));
    end
    xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'z (m)'); view(ax,135,20);
    exportgraphics(fig, fullfile(folder,sprintf('mode_%02d.png',modeIndex)), 'Resolution', 180);
    figures(end+1) = fig; %#ok<AGROW>
end
end

function [shapes, frequencies] = localFindShapes(s)
shapes=[]; frequencies=[];
if ~isstruct(s), return; end
names = {'fullModes','modeShapesFull','modesFull','modeShapes','modes','eigenvectors'};
for i=1:numel(names)
    if isfield(s,names{i}) && isnumeric(s.(names{i})) && ~isempty(s.(names{i}))
        shapes=s.(names{i});
        fNames={'frequencyHz','frequenciesHz','dampedFrequencyHz'};
        for j=1:numel(fNames), if isfield(s,fNames{j}), frequencies=s.(fNames{j}); break; end, end
        return
    end
end
fields=fieldnames(s);
for i=1:numel(fields)
    if isstruct(s.(fields{i}))
        [shapes,frequencies]=localFindShapes(s.(fields{i}));
        if ~isempty(shapes), return; end
    end
end
end

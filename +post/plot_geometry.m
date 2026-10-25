function fig = plot_geometry(modelData, fileName)
%PLOT_GEOMETRY Plot the validated finite-element center lines by component.

xyz = modelData.mesh.nodes.xyz;
elements = modelData.mesh.elements;
nodeI = elements.nodeI(:); nodeJ = elements.nodeJ(:);
types = strings(numel(nodeI),1);
if isfield(elements, 'type'), types = string(elements.type(:)); end
uniqueTypes = unique(types, 'stable');

fig = figure('Visible','off','Color','w','Name','Validated geometry');
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on'); axis(ax,'equal');
palette = lines(max(numel(uniqueTypes),1));
for i = 1:max(numel(uniqueTypes),1)
    if isempty(uniqueTypes), mask = true(size(nodeI)); label = "elements";
    else, mask = types == uniqueTypes(i); label = uniqueTypes(i); end
    idx = find(mask);
    x = [xyz(nodeI(idx),1), xyz(nodeJ(idx),1), nan(numel(idx),1)].';
    y = [xyz(nodeI(idx),2), xyz(nodeJ(idx),2), nan(numel(idx),1)].';
    z = [xyz(nodeI(idx),3), xyz(nodeJ(idx),3), nan(numel(idx),1)].';
    plot3(ax, x(:), y(:), z(:), '-', 'LineWidth', 1.2, ...
        'Color', palette(i,:), 'DisplayName', char(label));
end
xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); zlabel(ax,'z (m)');
title(ax,'Validated wind-turbine geometry'); view(ax,135,20);
legend(ax,'Location','best');
if nargin >= 2 && strlength(string(fileName)) > 0
    exportgraphics(fig, fileName, 'Resolution', 180);
end
end

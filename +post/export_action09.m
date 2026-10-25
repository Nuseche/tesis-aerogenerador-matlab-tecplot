function artifacts=export_action09(run,cfg,modelData,action09)
%EXPORT_ACTION09 Write compact, physically labelled Action-09 evidence.
% The full response and 133-by-12-by-Nt element-force tensors remain in the
% MAT artifact; CSV files contain only time series selected by the case and
% scalar envelopes suitable for independent review.

artifacts=struct();
artifacts.validation=write(action09,'checkTable', ...
    fullfile(run.folder,'action09_validation.csv'));
artifacts.groundMotion=write(action09,'groundMotionTable', ...
    fullfile(run.folder,'action09_ground_motion.csv'));
artifacts.timeConvergence=write(action09,'timeConvergenceTable', ...
    fullfile(run.folder,'action09_time_convergence.csv'));
artifacts.sdofBenchmark=write(action09,'sdofBenchmarkTable', ...
    fullfile(run.folder,'action09_sdof_benchmark.csv'));
artifacts.responseExtrema=write(action09,'responseExtremaTable', ...
    fullfile(run.folder,'action09_response_extrema.csv'));
artifacts.reactions=write(action09,'reactionsTable', ...
    fullfile(run.folder,'action09_reactions.csv'));
artifacts.elementForces=write(action09,'elementForcesTable', ...
    fullfile(run.folder,'action09_element_forces.csv'));
artifacts.timeHistory=table();artifacts.figures=gobjects(0);
if isfield(action09,'responses')&&isfield(action09.responses,'rotating')
    artifacts.timeHistory=writePhysicalHistory(run,cfg,modelData, ...
        action09.responses.rotating);
    if isfield(action09,'responseExtremaTable')
        writetable(action09.responseExtremaTable, ...
            fullfile(run.folder,'time_extrema.csv'));
    end
    makeFigures=isfield(cfg,'output')&&isfield(cfg.output,'makeFigures')&& ...
        logical(cfg.output.makeFigures);
    if makeFigures
        artifacts.figures=plotPhysicalResponse(run,cfg,modelData, ...
            action09.responses.rotating);
    end
end
end

function tableValue=write(source,field,fileName)
tableValue=table();
if isfield(source,field)&&istable(source.(field))
    tableValue=source.(field);
    writetable(tableValue,fileName);
end
end

function tableValue=writePhysicalHistory(run,cfg,modelData,response)
t=response.t(:);tableValue=table(t,'VariableNames',{'time_s'});
nodes=double(cfg.action09.responseNodes(:));labels={'ux','uy','uz'};
for nodeIndex=1:numel(nodes)
    modelRow=find(double(modelData.mesh.nodes.id)==nodes(nodeIndex),1);
    for component=1:3
        dof=double(modelData.dofs.node(modelRow,component));
        relativeName=sprintf('relative_%s_node%d_m',labels{component},nodes(nodeIndex));
        accelerationName=sprintf('absolute_acceleration_%s_node%d_mps2', ...
            labels{component},nodes(nodeIndex));
        tableValue.(relativeName)=response.qFull(dof,:).';
        tableValue.(accelerationName)=response.absoluteAccelerationFull(dof,:).';
    end
end
writetable(tableValue,fullfile(run.folder,'time_history.csv'));
end

function figureHandle=plotPhysicalResponse(run,cfg,modelData,response)
nodes=double(cfg.action09.responseNodes(:));nodes=nodes(nodes~=1);
figureHandle=figure('Visible','off','Color','w', ...
    'Position',[100 100 1200 800]);
layout=tiledlayout(figureHandle,2,1,'TileSpacing','loose','Padding','loose');
axisResponse=nexttile(layout);hold(axisResponse,'on');
set(axisResponse,'Color','w','XColor','k','YColor','k');
for index=1:numel(nodes)
    row=find(double(modelData.mesh.nodes.id)==nodes(index),1);
    dof=double(modelData.dofs.node(row,2));
    plot(axisResponse,response.t,response.qFull(dof,:), ...
        'LineWidth',1,'DisplayName',sprintf('node %d, u_y',nodes(index)));
end
grid(axisResponse,'on');box(axisResponse,'on');ylabel(axisResponse,'Relative u_y (m)');
responseLegend=legend(axisResponse,'Location','northwest');
set(responseLegend,'Color','w','TextColor','k','EdgeColor',[.3 .3 .3]);
title(axisResponse,sprintf('Action 09 response at %.3g RPM',response.speedRPM), ...
    'Color','k');
axisGround=nexttile(layout);hold(axisGround,'on');
set(axisGround,'Color','w','XColor','k','YColor','k');
for component=1:size(response.accelerogram.acceleration,2)
    plot(axisGround,response.t,response.accelerogram.acceleration(:,component), ...
        'LineWidth',1,'DisplayName',sprintf('component %d',component));
end
grid(axisGround,'on');box(axisGround,'on');xlabel(axisGround,'Time (s)');
ylabel(axisGround,'Ground acceleration (m/s^2)');
groundLegend=legend(axisGround,'Location','northwest');
set(groundLegend,'Color','w','TextColor','k','EdgeColor',[.3 .3 .3]);
exportgraphics(figureHandle,fullfile(run.figuresFolder,'response.png'), ...
    'Resolution',180);
end

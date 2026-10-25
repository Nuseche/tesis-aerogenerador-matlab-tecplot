function artifacts = export_all(run, cfg, modelData, results)
%EXPORT_ALL Write tables and figures without reassembling the model.

artifacts = struct('modalSummary',table(),'timeSummary',table(), ...
    'action02',struct(),'action03',struct(),'action04',struct(), ...
    'action05',struct(),'action06',struct(),'figures',gobjects(0));
artifacts.action07=struct();
artifacts.action08=struct();
artifacts.action09=struct();
artifacts.action10=struct();
if isfield(results,'modal') && ~isempty(results.modal)
    artifacts.modalSummary = post.export_modal_summary(run,results.modal);
end
hasAction09=isfield(results,'action09')&&~isempty(results.action09);
if isfield(results,'time') && ~isempty(results.time)&&~hasAction09
    artifacts.timeSummary = post.export_time_history(run,results.time,cfg);
end
if isfield(results,'validation') && isfield(results.validation,'checks')
    validationTable=struct2table(results.validation.checks);
    writetable(validationTable,fullfile(run.folder,'validation_summary.csv'));
end
if isfield(results,'action02') && ~isempty(results.action02)
    artifacts.action02 = post.export_action02( ...
        run,cfg,modelData,results.action02);
    if isfield(artifacts.action02,'figures')
        artifacts.figures = [artifacts.figures artifacts.action02.figures];
    end
end
if isfield(results,'action03') && ~isempty(results.action03)
    artifacts.action03 = post.export_action03(run,results.action03);
end
if isfield(results,'action04') && ~isempty(results.action04)
    artifacts.action04 = post.export_action04(run,results.action04);
end
if isfield(results,'action05') && ~isempty(results.action05)
    artifacts.action05 = post.export_action05(run,results.action05);
end
if isfield(results,'action06') && ~isempty(results.action06)
    artifacts.action06 = post.export_action06(run,results.action06);
end
if isfield(results,'action07') && ~isempty(results.action07)
    artifacts.action07 = post.export_action07(run,results.action07);
end
if isfield(results,'action08') && ~isempty(results.action08)
    artifacts.action08 = post.export_action08(run,results.action08);
end
if isfield(results,'action09') && ~isempty(results.action09)
    artifacts.action09 = post.export_action09( ...
        run,cfg,modelData,results.action09);
    artifacts.timeSummary=artifacts.action09.responseExtrema;
    if isfield(artifacts.action09,'figures')
        artifacts.figures=[artifacts.figures artifacts.action09.figures];
    end
end
if isfield(results,'action10') && ~isempty(results.action10)
    artifacts.action10=post.export_action10(run,results.action10);
end

makeFigures=true;
if isfield(cfg,'output') && isfield(cfg.output,'makeFigures')
    makeFigures=logical(cfg.output.makeFigures);
end
if ~makeFigures, return; end
artifacts.figures(end+1)=post.plot_geometry(modelData,fullfile(run.figuresFolder,'geometry.png'));
if isfield(results,'modal') && ~isempty(results.modal)
    artifacts.figures=[artifacts.figures post.plot_modes(modelData,results.modal,run.figuresFolder,cfg)];
    campbellFigure=post.plot_campbell(results.modal, ...
        fullfile(run.figuresFolder,'campbell.png'));
    if ~isempty(campbellFigure), artifacts.figures(end+1)=campbellFigure; end
end
if isfield(results,'time') && ~isempty(results.time)&&~hasAction09
    responseFigure=post.plot_response(results.time,fullfile(run.figuresFolder,'response.png'),cfg);
    if ~isempty(responseFigure), artifacts.figures(end+1)=responseFigure; end
end
close(artifacts.figures(isgraphics(artifacts.figures)));
end

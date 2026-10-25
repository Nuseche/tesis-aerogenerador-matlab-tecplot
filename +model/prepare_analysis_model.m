function analysisModel = prepare_analysis_model(modelData, reducedOps)
%PREPARE_ANALYSIS_MODEL Add full/reduced maps used by MBC and base motion.

analysisModel = modelData;
Tanalysis = reducedOps.Tc;
analysisModel.Tc = Tanalysis;
analysisModel.fullFixed = modelData.dofs.fixed;
analysisModel.nDof = size(Tanalysis,2);
analysisModel.dofMap = modelData.dofs.node;

bladeNodes = [22:56; 58:92; 94:128].';
fullMap = zeros(numel(bladeNodes(:,1))*6,3);
analysisMap = zeros(size(fullMap));
row = 0;
for station = 1:size(bladeNodes,1)
    for component = 1:6
        row = row + 1;
        for blade = 1:3
            nodeId = bladeNodes(station,blade);
            nodeRow = find(modelData.mesh.nodes.id == nodeId,1);
            fullDof = modelData.dofs.node(nodeRow,component);
            fullMap(row,blade) = fullDof;
            [~,column,value] = find(Tanalysis(fullDof,:));
            if numel(column) ~= 1 || abs(value-1) > 1e-12
                error('model:prepare_analysis_model:NonIndependentBladeDof', ...
                    'Blade node %d component %d is not an independent analysis DOF.', ...
                    nodeId,component);
            end
            analysisMap(row,blade) = column;
        end
    end
end
analysisModel.bladeDofMapFull = fullMap;
analysisModel.bladeDofMap = analysisMap;
analysisModel.mbcMap = analysisMap;
frameData=struct('map',analysisMap,'nDof',size(Tanalysis,2), ...
    'referenceR',modelData.bladeDofMap.frameR, ...
    'rotorAxis',modelData.rotorAxis.direction(:), ...
    'frameConvention',modelData.bladeDofMap.frameConvention, ...
    'station',(1:size(bladeNodes,1)).', ...
    'nodeIds',bladeNodes,'coordinateState', ...
    "homologous local blade frames before harmonic MBC");
analysisModel.mbc = struct('bladeNodeMap',bladeNodes, ...
    'fullDofMap',fullMap,'analysisDofMap',analysisMap, ...
    'frameData',frameData,'note', ...
    "Roots are excluded because exact hub/root MPCs make them collective master motion.", ...
    'transformationOrder',"global=H(psi)*T_MBC(psi)*multiblade");
end

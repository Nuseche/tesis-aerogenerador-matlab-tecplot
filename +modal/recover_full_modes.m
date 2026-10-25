function modalResults = recover_full_modes(modalResults, Tanalysis)
%RECOVER_FULL_MODES Add full-coordinate shapes to modal solution structures.

if ~isstruct(modalResults), return; end
if isfield(modalResults,'modes') && isnumeric(modalResults.modes)
    modalResults.modesReduced = modalResults.modes;
    modalResults.modesFull = Tanalysis*modalResults.modes;
    modalResults.fullModes = modalResults.modesFull;
end
if isfield(modalResults,'solutions') && iscell(modalResults.solutions)
    for index = 1:numel(modalResults.solutions)
        modalResults.solutions{index} = modal.recover_full_modes( ...
            modalResults.solutions{index},Tanalysis);
    end
end
end

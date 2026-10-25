function reduced = reduce_system(Tc,M,Ke,model,cfg,varargin)
%REDUCE_SYSTEM Congruence reduction of operators and loads.
%   q_full=Tc*q_reduced. Matrices use Tc'*A*Tc and vectors Tc'*f.

    if nargin<5,cfg=struct();end %#ok<NASGU>
    Tc=sparse(Tc);M=sparse(M);Ke=sparse(Ke);
    if size(Tc,1)~=size(M,1)||size(M,1)~=size(M,2)||~isequal(size(M),size(Ke))
        error("rigid:reduce_system:DimensionMismatch","Tc, M and Ke dimensions are inconsistent.");
    end
    reduced=struct();
    reduced.Tc=Tc;
    reduced.M=Tc.'*M*Tc;
    reduced.Ke=Tc.'*Ke*Tc;
    reduced.K=reduced.Ke;
    reduced.full=struct("M",M,"Ke",Ke);
    reduced.M=(reduced.M+reduced.M.')/2;
    reduced.Ke=(reduced.Ke+reduced.Ke.')/2;
    reduced.K=reduced.Ke;

    fixedFull=getFixedDofs(model);
    fixedReduced=zeros(numel(fixedFull),1);
    for fixedIndex=1:numel(fixedFull)
        [~,columns,values]=find(Tc(fixedFull(fixedIndex),:));
        if numel(columns)~=1 || ~isfinite(values) || values==0
            error('rigid:reduce_system:DependentSPCNotSupported', ...
                ['An SPC on full DOF %d becomes a coupled equation after Tc. ' ...
                 'Compose a dedicated boundary-condition null-space transform ' ...
                 'instead of fixing every participating reduced DOF.'], ...
                fixedFull(fixedIndex));
        end
        fixedReduced(fixedIndex)=columns;
    end
    reduced.fixed=unique(fixedReduced);
    reduced.free=setdiff((1:size(Tc,2)).',reduced.fixed,'stable');
    reduced.fullFixed=fixedFull;
    reduced.recover=@(qReduced) Tc*qReduced;
    reduced.reduceLoad=@(fFull) Tc.'*fFull;

    names=["C","G","Kg","KOmega","Kaero"];
    for k=1:min(numel(varargin),numel(names))
        A=varargin{k};
        if ~isempty(A),reduced.(names(k))=Tc.'*sparse(A)*Tc;end
    end
end

function fixed=getFixedDofs(model)
    fixed=[];
    if isfield(model,"dofs")&&isfield(model.dofs,"fixed")
        fixed=double(model.dofs.fixed(:));
    elseif isfield(model,"boundaryConditions")
        bc=model.boundaryConditions;
        if isfield(bc,"fixedDofIndices"),fixed=double(bc.fixedDofIndices(:));
        elseif isfield(bc,"fixedNodeIds")
            ids=double(model.mesh.nodes.id(:));map=getMap(model,numel(ids));
            components=1:6;
            if isfield(bc,"fixedDofs")&&~isempty(bc.fixedDofs),components=double(bc.fixedDofs(:)).';end
            for id=double(bc.fixedNodeIds(:)).'
                row=find(ids==id,1);
                if isempty(row),error("rigid:reduce_system:UnknownFixedNode","Fixed node %g does not exist.",id);end
                fixed=[fixed;map(row,components).']; %#ok<AGROW>
            end
        end
    end
    fixed=unique(fixed);
end

function map=getMap(model,n)
    if isfield(model,"dofs")&&isfield(model.dofs,"node"),map=double(model.dofs.node);
    else,map=reshape(1:6*n,6,n).';end
end

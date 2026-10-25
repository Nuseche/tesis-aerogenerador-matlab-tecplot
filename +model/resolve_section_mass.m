function sections = resolve_section_mass(sections,cfg)
%RESOLVE_SECTION_MASS Apply only documented sectional-mass rules.
%   The Version 0 blade table provides AXIALD, TORDEN, INERT2 and INERT3.
%   TORDEN is zero at every station.  This function deliberately refuses to
%   manufacture a longitudinal inertia from EA or GJ.  The only supported
%   completion is the explicitly configured perpendicular-axis relation
%   Jx=Jy+Jz, based on the source labels INERT2/INERT3.

arguments
    sections (:,1) struct
    cfg (1,1) struct
end

rule = "";
if isfield(cfg,'sections') && isfield(cfg.sections,'blade') && ...
        isfield(cfg.sections.blade,'torsionalInertiaRule')
    rule = lower(string(cfg.sections.blade.torsionalInertiaRule));
end

for k = 1:numel(sections)
    if ~isfield(sections(k),'type')
        continue
    end
    if lower(string(sections(k).type)) == "tower"
        Jy = double(sections(k).Jy);
        Jz = double(sections(k).Jz);
        sections(k).Jx = Jy+Jz;
        sections(k).torsionalInertiaRule = "perpendicular_axis_tubular";
        sections(k).torsionalInertiaStatus = "resolved_from_geometric_Iy_plus_Iz";
        continue
    end
    if lower(string(sections(k).type)) ~= "blade",continue,end
    switch rule
        case "perpendicular_axis"
            Jy = double(sections(k).Jy);
            Jz = double(sections(k).Jz);
            if ~isscalar(Jy) || ~isscalar(Jz) || ...
                    any(~isfinite([Jy Jz])) || any([Jy Jz] <= 0)
                error('model:resolve_section_mass:InvalidTransverseInertia', ...
                    'Blade section %g has invalid INERT2/INERT3 mass moments.', ...
                    double(sections(k).id));
            end
            sections(k).Jx = Jy + Jz;
            sections(k).torsionalInertiaRule = "perpendicular_axis";
            sections(k).torsionalInertiaStatus = ...
                "resolved_explicitly_from_INERT2_plus_INERT3";
        otherwise
            error('model:resolve_section_mass:UnresolvedBladeTorsion', ...
                ['Blade torsional mass inertia is unresolved because legacy ' ...
                 'TORDEN=0. Set cfg.sections.blade.torsionalInertiaRule ' ...
                 'explicitly to "perpendicular_axis" after accepting the ' ...
                 'documented INERT2/INERT3 interpretation.']);
    end
end
end

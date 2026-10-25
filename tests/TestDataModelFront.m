classdef TestDataModelFront < matlab.unittest.TestCase
    % Regression tests for the traceable Version 0 data/model front.

    properties (SetAccess = private)
        ProjectRoot
        Configuration
        Data
        Model
    end

    methods (TestClassSetup)
        function loadVerifiedModel(testCase)
            testCase.ProjectRoot = fileparts(fileparts(mfilename('fullpath')));
            addpath(testCase.ProjectRoot);
            testCase.Configuration = io.load_configuration();
            testCase.Data = io.load_model_data(testCase.Configuration);
            testCase.Model = model.build_model(testCase.Data, testCase.Configuration);
        end
    end

    methods (Test)
        function legacyMirrorMatchesAndIsReadOnly(testCase)
            command = sprintf("cd '%s' && shasum -a 256 -c legacy/MANIFEST.sha256", ...
                testCase.ProjectRoot);
            [status, output] = system(command);
            testCase.verifyEqual(status, 0, output);
            [status, output] = system(sprintf( ...
                "diff -rq '%s' '%s'", ...
                fullfile(testCase.ProjectRoot, 'Codigos_sergio'), ...
                fullfile(testCase.ProjectRoot, 'legacy', 'Codigos_sergio')));
            testCase.verifyEqual(status, 0, output);

            files = dir(fullfile(testCase.ProjectRoot, 'legacy', ...
                'Codigos_sergio', '**', '*'));
            files = files(~[files.isdir]);
            for k = 1:numel(files)
                [ok, attributes] = fileattrib(fullfile(files(k).folder, files(k).name));
                testCase.assertTrue(ok);
                testCase.verifyFalse(attributes.UserWrite, files(k).name);
            end
        end

        function artifactsRetainRawInventory(testCase)
            geometry = testCase.Data.geometry;
            testCase.verifySize(geometry.coordinates, [138, 3]);
            testCase.verifySize(geometry.connectivity, [137, 4]);
            testCase.verifySize(geometry.coorP1aux, [36, 3]);
            testCase.verifySize(geometry.coorP2aux, [36, 3]);
            testCase.verifySize(geometry.coorP3aux, [36, 3]);
            testCase.verifyEqual(nnz(geometry.connectivity(:,2) == 3), 4);
            testCase.verifyEqual(nnz(geometry.connectivity(:,2) == 4), 9);
            testCase.verifyNumElements(testCase.Data.sections, 55);
        end

        function flexibleMeshClassificationIsExact(testCase)
            mesh = testCase.Model.mesh;
            testCase.verifyNumElements(mesh.nodes.id, 138);
            testCase.verifyNumElements(mesh.elements.id, 133);
            testCase.verifyEqual(nnz(mesh.elements.type == "tower"), 19);
            testCase.verifyEqual(nnz(mesh.elements.type == "blade"), 105);
            testCase.verifyEqual(nnz(mesh.elements.type == "transition"), 9);
            testCase.verifyEqual(nnz(mesh.elements.legacyType == 3), 0);
            testCase.verifyEqual(mesh.elements.legacyId(mesh.elements.legacyType == 4), ...
                (125:133).');
            testCase.verifyEqual(testCase.Model.meta.removedLegacyType3Ids, ...
                (134:137).');
        end

        function eachBladeUsesItsOwnAuxiliaryArray(testCase)
            mesh = testCase.Model.mesh;
            raw = testCase.Data.geometry;
            expected = {raw.coorP1aux, raw.coorP2aux, raw.coorP3aux};
            for blade = 1:3
                rows = find(mesh.elements.blade == blade);
                testCase.verifyEqual(mesh.elements.auxPoint(rows,:), expected{blade}(1:35,:), ...
                    'AbsTol', 0);
            end
            firstFrames = zeros(3,3,3);
            for blade = 1:3
                frameIndex = find(testCase.Model.referenceFrames.blade == blade, 1);
                firstFrames(:,:,blade) = testCase.Model.referenceFrames.R(:,:,frameIndex);
            end
            testCase.verifyGreaterThan(norm(firstFrames(:,:,1)-firstFrames(:,:,2),'fro'), 1e-3);
            testCase.verifyGreaterThan(norm(firstFrames(:,:,1)-firstFrames(:,:,3),'fro'), 1e-3);
            testCase.verifyGreaterThan(norm(firstFrames(:,:,2)-firstFrames(:,:,3),'fro'), 1e-3);
        end

        function sectionsAreGeneralizedPositiveAndTraceable(testCase)
            sections = testCase.Model.sections;
            fields = {'EA','GAy','GAz','GJ','EIy','EIz','m','Jx','Jy','Jz'};
            for k = 1:numel(fields)
                values = [sections.(fields{k})];
                testCase.verifyTrue(all(isfinite(values) & values > 0), fields{k});
            end
            testCase.verifyEqual([sections(1:20).id], 1:20);
            testCase.verifyEqual([sections(21:55).id], 21:55);
            testCase.verifyEqual(string({sections(1:20).type}), ...
                repmat("tower",1,20));
            testCase.verifyEqual(string({sections(21:55).type}), ...
                repmat("blade",1,35));
            rawBlade = testCase.Data.sections(21:55);
            testCase.verifyTrue(all(isnan([rawBlade.Jx])));
            rawColumns = vertcat(rawBlade.rawMassColumns);
            testCase.verifyEqual(rawColumns(:,2),zeros(35,1),'AbsTol',0);
            testCase.verifyEqual(string({sections(21:55).torsionalInertiaRule}), ...
                repmat("perpendicular_axis",1,35));
            testCase.verifyEqual([sections(21:55).Jx], ...
                [sections(21:55).Jy]+[sections(21:55).Jz], ...
                'RelTol',eps);
        end

        function dofMapUsesDocumentedOrder(testCase)
            dofs = testCase.Model.dofs;
            testCase.verifyEqual(dofs.order, ...
                ["ux","uy","uz","rx","ry","rz"]);
            testCase.verifyEqual(dofs.number, 828);
            testCase.verifySize(dofs.node, [138, 6]);
            testCase.verifySize(dofs.element, [133, 12]);
            testCase.verifyEqual(dofs.node(1,:), 1:6);
            testCase.verifyEqual(dofs.fixed, (1:6).');
            testCase.verifyEqual(dofs.element(1,:), [1:6, 7:12]);
            bladeMap = testCase.Model.bladeDofMap;
            testCase.verifySize(bladeMap.nodeIds, [35,3]);
            testCase.verifySize(bladeMap.full, [35,6,3]);
            testCase.verifySize(bladeMap.map, [210,3]);
            testCase.verifyEqual(bladeMap.nodeIds(:,1), (22:56).');
            testCase.verifyEqual(bladeMap.nodeIds(:,2), (58:92).');
            testCase.verifyEqual(bladeMap.nodeIds(:,3), (94:128).');
            testCase.verifyEqual(squeeze(bladeMap.full(1,:,1)), ...
                dofs.node(dofs.nodeIds == 22,:));
            testCase.verifyEqual(bladeMap.map(1:6,1), ...
                dofs.node(dofs.nodeIds == 22,:).');
        end

        function validModelProducesSummary(testCase)
            report = model.validate_model(testCase.Model, testCase.Configuration);
            testCase.verifyTrue(report.passed);
            testCase.verifyEqual(report.summary.nodeCount, 138);
            testCase.verifyEqual(report.summary.flexibleElementCount, 133);
            testCase.verifyGreaterThan(report.summary.approximateTotalMassKg, 0);
            testCase.verifyGreaterThan(report.geometry.minimumLengthM, 0);
        end

        function invalidConnectivityStopsBeforeAnalysis(testCase)
            corrupted = testCase.Model;
            corrupted.mesh.elements.nodeJ(1) = 999999;
            testCase.verifyError(@() model.validate_model( ...
                corrupted, testCase.Configuration), ...
                'model:validate_model:ValidationFailed');
        end

        function collinearAuxiliaryPointIsRejected(testCase)
            corrupted = testCase.Model;
            row = find(corrupted.mesh.elements.blade == 1, 1);
            nodeId = corrupted.mesh.elements.nodeI(row);
            nodeRow = find(corrupted.mesh.nodes.id == nodeId, 1);
            corrupted.mesh.elements.auxPoint(row,:) = ...
                corrupted.mesh.nodes.xyz(nodeRow,:);
            testCase.verifyError(@() model.validate_model( ...
                corrupted, testCase.Configuration), ...
                'model:validate_model:ValidationFailed');
        end

        function rigidBodyDefinitionsPreserveVerifiedValues(testCase)
            bodies = testCase.Model.rigidBodies;
            testCase.verifyEqual(bodies.masters, [129;130]);
            testCase.verifyEqual([bodies.bodies.mass], [1.1845e6, 1.96e5]);
            testCase.verifyEqual(bodies.constraints.masterNode, 130);
            testCase.verifyEqual(bodies.constraints.slaveNodes, [21;57;93]);
            testCase.verifyEqual(bodies.removedLegacyConnectorIds, (134:137).');
            R = bodies.bodies(1).orientationBodyToGlobal;
            testCase.verifyEqual(R.'*R, eye(3), 'AbsTol', 5e-15);
            testCase.verifyEqual(det(R), 1, 'AbsTol', 5e-15);
            testCase.verifyEqual(bodies.bodies(1).orientationAnglesInput, ...
                [90,-5,-90]);
            testCase.verifyEqual(bodies.bodies(1).orientationAngleUnit,"deg");
            testCase.verifyEqual(bodies.bodies(1).orientationAnglesRad, ...
                deg2rad([90,-5,-90]),'AbsTol',0);
            testCase.verifyEqual(bodies.bodies(1).dataVersion, ...
                "legacy_rigid_bodies_v0");
        end

        function benchmarkHasFullPrecisionAndMetadata(testCase)
            reference = testCase.Data.reference;
            csv = readmatrix(fullfile(testCase.ProjectRoot, 'data', ...
                'reference', 'legacy_fixed_base_frequencies_v0.csv'), ...
                'NumHeaderLines', 1);
            testCase.verifyEqual(reference.frequencyHz, csv(:,2), 'AbsTol', 0);
            testCase.verifyEqual(reference.count, 20);
            testCase.verifyEqual(reference.matlabRelease, "R2026a");
            testCase.verifyEqual(reference.baseType, "fixed");
            testCase.verifyEqual(reference.frequencyHz(1), ...
                0.19173102440399947, 'AbsTol', 1e-16);
            testCase.verifyEqual(reference.frequencyHz(end), ...
                2.9069650763640511, 'AbsTol', 1e-15);
        end

        function loadingDoesNotDependOnCurrentFolder(testCase)
            originalFolder = pwd;
            restoreFolder = onCleanup(@() cd(originalFolder)); %#ok<NASGU>
            cd(tempdir);
            cfg = io.load_configuration();
            data = io.load_model_data(cfg);
            built = model.build_model(data, cfg);
            testCase.verifyEqual(cfg.paths.projectRoot, string(testCase.ProjectRoot));
            testCase.verifyEqual(built.summary.nodeCount, 138);
            testCase.verifyEqual(built.summary.flexibleElementCount, 133);
        end

        function structOverrideMergesWithoutLosingDefaults(testCase)
            override = struct('rotor', struct('speedRPM', 12.5), ...
                'modes', struct('number', 12));
            cfg = io.load_configuration(override);
            testCase.verifyEqual(cfg.rotor.speedRPM, 12.5);
            testCase.verifyEqual(cfg.modes.number, 12);
            testCase.verifyEqual(cfg.units.system, "SI");
            testCase.verifyEqual(cfg.mass.formulation, "consistent");
        end
    end
end

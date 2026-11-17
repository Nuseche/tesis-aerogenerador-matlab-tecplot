function result=rotor_load_orders(s,folder)
%ROTOR_LOAD_ORDERS Resolve blade and hub load orders on the prescribed rigid rotor.
% Uniform flow is a control; power-law shear is an explicit illustrative input.
data=aero.load_snl100();sec=aero.prepare_sections(s.model,s.cfg,data);cfg=s.cfg;
axis=s.model.rotorAxis.direction;origin=s.model.rotorAxis.point;
U=1;omega=.7547;rows={};histories={};Nmax=384;
original=s.model;geometryDifference=0;
for geometryCase=["inherited" "cyclic_control"]
    s.model=original;
    if geometryCase=="cyclic_control"
        for b=2:3
            Q=aero.rotation(axis*(b-1)*2*pi/3);target=(21:56)+(b-1)*36;
            xyz=origin.'+(original.mesh.nodes.xyz(21:56,:)-origin.')*Q.';
            geometryDifference=max(geometryDifference,max(vecnorm(xyz-original.mesh.nodes.xyz(target,:),2,2)));
            s.model.mesh.nodes.xyz(target,:)=xyz;
            first=find(original.mesh.elements.blade==1);other=find(original.mesh.elements.blade==b);
            s.model.mesh.elements.auxPoint(other,:)=origin.'+(original.mesh.elements.auxPoint(first,:)-origin.')*Q.';
        end
    end
    sec=aero.prepare_sections(s.model,s.cfg,data);
for shear=[0 .2]
    for N=[96 192 384]
        values=zeros(N,5);cfg.aerodynamics.windVelocity=@(~,xyz) U*(xyz(:,3)/origin(3)).^shear*axis.';
        for j=1:N
            psi=(j-1)*2*pi/N;motion=struct('azimuth',psi,'omega',omega,'alpha',0);
            [~,r]=aero.section_loads(sec,data,zeros(s.ndof,1),zeros(s.ndof,1),0,motion,cfg);
            Q=aero.rotation(axis*psi);F=sec.weight.*r.forcePerLength;
            moment=sec.weight.*(cross(sec.position-origin.',r.forcePerLength,2)+r.momentPerLength);
            for b=1:3,values(j,b)=sum(F(sec.blade==b,:)*axis);end
            values(j,4)=sum(F*axis);torque=Q*sum(moment,1).';values(j,5)=torque(2);
        end
        coefficients=fft(values)/N;
        for order=1:9
            amps=2*abs(coefficients(order+1,:));rows(end+1,:)=[{geometryCase,shear,N,order,order*omega/(2*pi)},num2cell(amps)]; %#ok<AGROW>
        end
        if N==Nmax,histories{end+1}=struct('geometry',geometryCase,'shear',shear,'azimuth',(0:N-1)'*2*pi/N,'loads',values);end %#ok<AGROW>
    end
end
end
result=cell2table(rows,'VariableNames',{'geometry','shear_exponent','angular_samples','order','frequency_hz', ...
    'blade1_thrust_N','blade2_thrust_N','blade3_thrust_N','hub_thrust_N','hub_pitch_moment_Nm'});
writetable(result,fullfile(folder,'rigid_rotor_load_orders.csv'));
save(fullfile(folder,'rigid_rotor_load_histories.mat'),'histories','U','omega','geometryDifference');
end

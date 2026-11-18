"""Extract traceable structural-paper tables without running or fitting models.

Writes only output/structural_paper (or --output). All plot rows are original
numerical rows or explicitly documented subsets; no curve smoothing, alignment,
calibration or undocumented mixture of campaigns is performed.
"""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import subprocess
import numpy as np
from audit_nonlinear_reference import read_history

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--nonlinear-source', type=Path, required=True)
    p.add_argument('--archive', type=Path, help='Previous manuscript data directory, for archival hash crosschecks')
    p.add_argument('--output', type=Path, default=ROOT/'output/structural_paper')
    a = p.parse_args()
    a.output.mkdir(parents=True, exist_ok=True)
    ledger = {'code_commit_at_extraction': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
              'policy': 'Extraction only, no new model simulations. Historical campaigns retain their original conditions.',
              'sources': [], 'outputs': [], 'checks': {}}
    registered = set()
    def source(path, campaign):
        path = Path(path)
        if str(path) not in registered:
            registered.add(str(path))
            ledger['sources'].append({'path':str(path), 'campaign':campaign, 'sha256':sha(path), 'bytes':path.stat().st_size})
        return path
    def rows(path, campaign):
        return list(csv.DictReader(source(path,campaign).open()))
    def write(name, data, note, fields=None):
        target = a.output/(name+'.csv')
        fields = fields or list(data[0])
        with target.open('w',newline='') as stream:
            w=csv.DictWriter(stream,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(data)
        # Paste these table bodies directly inside main.tex with row sep=\\.
        table = ' '.join(fields)+'\\\\\n'
        for row in data:
            table += ' '.join(str(row[k]) for k in fields)+'\\\\\n'
        (a.output/(name+'.pgfdata')).write_text(table)
        ledger['outputs'].append({'name':name, 'rows':len(data),'columns':fields,'operation':note,'csv_sha256':sha(target)})
    old=ROOT/'runs/run_20260914_mecom_comparison'
    mesh=ROOT/'runs/run_20260914_mecom_mesh_refinement'
    rotor=ROOT/'runs/rotor_orders_20261117'
    nl=ROOT/'output/nonlinear_reference'
    source(old/'comparison_summary.json','stationary_20260914')
    oldmeta=json.loads((old/'comparison_summary.json').read_text())
    # Copy only scientifically relevant benchmark metadata, not huge raw arrays.
    (a.output/'stationary_conditions.json').write_text(json.dumps({k:oldmeta[k] for k in ['metadata','beamParameters','globalParameters']},indent=2)+'\n')
    beam=rows(old/'cantilever_comparison.csv','stationary_20260914')
    write('beam_convergence', [r for r in beam if r['slenderness']=='10' and r['mode']=='4'],
          'Original fourth-bending-mode frequency errors; each theory uses its own reference, L/h=10.', ['elements','theory','frequencyErrorPercent'])
    for theory in ['Timoshenko','EulerBernoulli']:
        subset=[r for r in beam if r['slenderness']=='10' and r['mode']=='4' and r['theory']==theory]
        if subset:write('beam_'+theory,subset,'Same selected original rows.', ['elements','frequencyErrorPercent'])
    write('beam_theory_difference',rows(old/'cantilever_references.csv','stationary_20260914'),'Original analytical EB and 512-element Timoshenko references.')
    write('mesh_convergence',rows(mesh/'mesh_summary.csv','stationary_20260914'),'Original piecewise-parent subdivision; errors relative to subdivision 8.')
    write('shear_rigid_mac',rows(old/'global_shear_rigid_mac.csv','stationary_20260914'),'Original mass-weighted MAC matching with rotary inertia retained in both models.')
    write('campbell',rows(rotor/'campbell.csv','periodic_structure_20261117'),'All sampled points, sorted roots; no persistent mode labels.')
    coarse=rows(rotor/'hub_receptance.csv','periodic_structure_20261117')
    fine=rows(rotor/'peak_neighborhoods.csv','periodic_structure_20261117')
    for order in [1,3,6]:
        selected=[r for r in coarse if int(r['order'])==order]
        for r in selected:r['phase_deg']=r['hub_phase_deg']
        selected += [r for r in fine if int(r['order'])==order]
        selected.sort(key=lambda r:float(r['rpm']))
        write('receptance_'+str(order)+'P',selected,'Union of coarse sweep and direct refined-peak neighborhoods, sorted by RPM. Original ordinates.',
              ['rpm','hub_axial_m_per_N','nacelle_axial_m_per_N','tower_top_axial_m_per_N','phase_deg'])
    for name in ['resolved_peaks','periodic_convergence','periodic_complex_convergence','floquet_convergence','damping_sensitivity','angular_convergence','rigid_rotor_load_orders']:
        write(name,rows(rotor/(name+'.csv'),'periodic_structure_20261117'),'Original table, unchanged numerical values.')
    costs=rows(old/'global_costs.csv','stationary_20260914')
    errors=rows(old/'global_response_errors.csv','stationary_20260914')
    write('rom_costs',costs,'Original wall-time measurements, median of 3 after one warmup; output recovery excluded.')
    out=[]
    for c in costs:
        if c['model']=='MHT_full':continue
        d={'modes':c['dofs']}
        for channel in ['nacelle_ux_m','blade1_tip_ux_m','nacelle_ax_absolute_mps2','base_My_Nm']:
            e=next(r for r in errors if r['model']==c['model'] and r['output']==channel)
            d[channel]=e['historyErrorPercent']
        out.append(d)
    write('rom_errors',out,'Original relative history L2 errors, percent; no aggregation across units.')
    histories=rows(old/'global_histories.csv','stationary_20260914')
    fields=['timeS','MHT_full_nacelle_ux_m','MHT_full_blade1_tip_ux_m','MHT_full_blade2_tip_ux_m','MHT_full_blade3_tip_ux_m','MHT_full_base_My_Nm']
    write('stationary_response_full',histories,'All original history rows.',fields)
    # Subset preserving endpoints and every local extremum, plus each eighth row.
    y=np.array([[float(r[k]) for k in fields[1:]] for r in histories]);idx=set(range(0,len(histories),8));idx.add(len(histories)-1)
    for k in range(y.shape[1]):idx.update((np.where(np.diff(y[:,k])[:-1]*np.diff(y[:,k])[1:]<=0)[0]+1).tolist())
    chosen=sorted(idx)
    maxerr=[]
    tt=np.array([float(r['timeS']) for r in histories])
    for k in range(y.shape[1]):
        maxerr.append(float(np.max(np.abs(y[:,k]-np.interp(tt,tt[chosen],y[chosen,k])))/max(np.max(abs(y[:,k])),np.finfo(float).tiny)))
    write('stationary_response_plot',[histories[i] for i in chosen],f'Original subset: every eighth row, endpoints, all channel extrema. Maximum normalized linear-interpolation differences {maxerr}.',fields)
    morris=ROOT/'runs/sensitivity/morris_20261006'
    ms=rows(morris/'morris_estimators.csv','frozen_gravity_morris_20261006')
    source(morris/'campaign.json','frozen_gravity_morris_20261006')
    source(morris/'source_hashes.csv','frozen_gravity_morris_20261006')
    mfinal=[r for r in ms if r['trajectories']=='40' and r['response']=='frequency']
    write('morris_frequency_all',mfinal,'Includes rejected means and dispersions with original acceptance flags.')
    accepted=[r for r in mfinal if r['acceptedMean']=='1']
    write('morris_frequency_accepted',accepted,'Only accepted mean frequency effects. Rejected values are omitted, never replaced by zero.')
    for par in ['blade_density','blade_stiffness','rotor_speed']:
        data=[]
        for r in mfinal:
            if r['parameter']==par:
                d={'group_index':['1+2','3','4+5','6+7','8+9','10+11','12'].index(r['group'])+1,
                   'mu':r['mu'] if r['acceptedMean']=='1' else 'nan'};data.append(d)
        write('morris_'+par,data,'Signed accepted mean; NaN marks unresolved/invalid, not zero.')
    # Nonlinear audit summaries retain their own loading/damping convention.
    write('nonlinear_case_summary',rows(nl/'case_summary.csv','external_nonlinear_20261118'),'Original binary-audit summary; no linear-model comparison implied.')
    write('nonlinear_support_peaks',rows(nl/'support_spectral_peaks.csv','external_nonlinear_20261118'),'Response spectral maxima ranked by amplitude, not natural modes.')
    audit=json.loads(source(nl/'audit.json','external_nonlinear_20261118').read_text())
    spec=np.load(source(nl/'support_spectra.npz','external_nonlinear_20261118'))
    freq=spec['frequency_hz'];mask=(freq>=.1)&(freq<=.5)
    spectral=[]
    for i in np.flatnonzero(mask):
        spectral.append({'frequency_hz':float(freq[i]),'case00_tower_x_m':float(spec['case00_tower_top_amplitude_m'][i,0]),
                         'case07_tower_x_m':float(spec['case07_tower_top_amplitude_m'][i,0])})
    write('nonlinear_spectra',spectral,'All original DFT bins in 0.1--0.5 Hz. Mean removed; rectangular 25.01--1099.99 s window, 0.01 s grid; not FRF.')
    for case in ['00','07']:
        folder=a.nonlinear_source/f'12_NG_NA_NS_R_{case}_DASHPOT';tt=[];yy=[]
        known={r['name']:r['sha256'] for r in next(v for v in audit if v['case']==case)['files']}
        for stage in range(1,6):
            path=source(folder/f'snl.@{stage}.p11','external_nonlinear_20261118')
            assert sha(path)==known[path.name],f'Nonlinear binary changed: {path}'
            ids,t,u=read_history(path);tt.append(t);yy.append(u[:,list(ids).index(400019),0])
        t=np.concatenate(tt);y=np.concatenate(yy);m=(t>=15)&(t<=80);t=t[m];y=y[m]
        original=[{'time_s':float(ti),'tower_top_x_m':float(yi)} for ti,yi in zip(t,y)]
        write('nonlinear_history_'+case+'_full',original,'All binary tower-top global-X displacement samples from 15--80 s; node 400019.')
        selected=set(range(0,len(t),10));selected.update([0,len(t)-1]);selected.update((np.where(np.diff(y)[:-1]*np.diff(y)[1:]<=0)[0]+1).tolist());selected=sorted(selected)
        err=float(np.max(abs(y-np.interp(t,t[selected],y[selected])))/np.max(abs(y)))
        write('nonlinear_history_'+case, [original[i] for i in selected], f'Original subset every tenth row plus endpoints and all extrema. Max interpolation deviation/reference max = {err:.8g}.')
    # Old manuscript copies can verify source files without being a hidden data dependency.
    if a.archive:
        provenance=json.loads(source(a.archive/'provenance.json','archival_copy_provenance').read_text())
        comparisons=[]
        for entry in provenance['files']:
            src=Path(entry['source'])
            if str(src) in registered and entry.get('operation')=='byte-identical copy':
                ok=sha(src)==entry['sha256'];comparisons.append({'source':str(src),'matches_archive_hash':ok})
                if not ok:raise ValueError(f'Archival mismatch: {src}')
        ledger['checks']['archive_hashes']=comparisons
    ledger['checks']['nonlinear_selected_binary_hashes']='all 10 match existing audit'
    (a.output/'provenance.json').write_text(json.dumps(ledger,indent=2)+'\n')
    print(json.dumps({'output':str(a.output),'sources':len(ledger['sources']),'tables':len(ledger['outputs']),'checks':ledger['checks']},indent=2))

if __name__=='__main__':
    main()

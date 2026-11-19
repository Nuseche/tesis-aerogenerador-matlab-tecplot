"""Recover local nacelle couples as global vectors during the archived pulse."""
import argparse
from pathlib import Path
import numpy as np
from scipy.spatial.transform import Rotation
from audit_nonlinear_reference import read_history

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source",type=Path,help="Directory of SIMPACT case 00")
    args=parser.parse_args()
    times, moments = [], []
    for stage in (3,4):
        ids,t,v=read_history(args.source/f"snl.@{stage}.p11")
        rotation=Rotation.from_euler("ZXZ",v[:,list(ids).index(2),3:])
        times.extend(t)
        moments.extend(rotation.apply([1.,1.,1.]))
    tmid=20+(np.arange(100)+.5)*.01
    values=np.asarray(moments)
    torque=np.column_stack([np.interp(tmid,times,column) for column in values.T])
    out=Path(__file__).resolve().parents[1]/"runs/case00_decay"
    out.mkdir(parents=True,exist_ok=True)
    np.savetxt(out/"replay_moment_inputs.csv",np.column_stack((tmid,torque)),delimiter=",",
               header="timeMidpoint_s,Mx_over_1e7,My_over_1e7,Mz_over_1e7",comments="")

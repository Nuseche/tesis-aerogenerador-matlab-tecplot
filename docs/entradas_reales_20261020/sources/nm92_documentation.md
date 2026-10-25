## Background Information
- CLASSIFICATION: flat(flat landscape), coastal(water and land)
- COUNTRY : DK
- ALTITUDE : 0 [m]
- POSITION : [57˚ 2' 20.5'' N 10˚ 4'32.6'' E](https://geohack.toolforge.org/geohack.php?pagename=NM92&params=57_2_20.4_N_10_4_32.6_E_)	
(Note: Geohack often includes national high resolution maps, otherwise try Google Earth)
## Short summary
This dataset consists of raw time series from a mast, turbine power and load measurements (25 Hz) together with 10-minute statistics of these measurements. The 70m mast and the turbine is located east of Aalborg next to Klarup, Denmark. The period includes more than 570 hours of mast and turbine measurements recorded during the period Nov05 - Jan06.
## Map
![A map of Denmark ](./ts_wt/nm92/msmap.png)
**Figure 1:** Location of the NM92 in Denmark.
## Photos
![](./ts_wt/nm92/map_02.jpg) **Photo 01:** Combined map and photo of the area.

![](./ts_wt/nm92/photo_01.jpg) **Photo 02:** Photo of the turbine and mast.
## Drawings
![](./ts_wt/nm92/layout.gif) **Drawing 01:** Layout of the measurement setup.

## Reports
1. [Cup anemometer](./ts_wt/nm92/Riso_P2546A_cup_anemometer.pdf)

2. [Wind vane](./ts_wt/nm92/Vector_W200P.pdf)

3. [Barometer](./ts_wt/nm92/Vaisala_barometers_PTB.pdf)

4. [Power transducer](./ts_wt/nm92/DeifTAS331DG_power_transducer.pdf)

## MASTS
1 70 [m] (-207,0,0)

## WIND TURBINE (reference position)
1 NEG-Micon NM92/2750 kW 2750 [kW] (0,0,0)

## Project description
Aalborg University (AAU) expressed their needs for providing students with an opportunity to conduct tests and experiments on a real wind turbine. For such a project, a data acquisition system represents an essential tool for observing the nature of the wind and the behavior of the wind turbine. AAU assigned Risoe National Laboratory to deliver a suitable data acquisition system on a NEG-Micon NM92/2750 kW wind turbine, which should facilitate monitoring, data management of sensor records and specific needs expressed from the wind turbine manufacturer (formerly NEG-Micon, now Vestas). The intended plans were to conduct tests on the experimental facility for a period of 2-3 years; the first year under management by NEG-Micon, and the following years to run the test facility for research activities under supervision from AAU in two consecutive years. Currently the Wind Turbine is owned by ELSAM, which is part of DONG Energy DK.

## Measurement system
The measurement system is a standard Risø DAQ system recording simultaneously signals from bot 70 m measurement mast (cups, vanes, sonics, pressure and temperatures) together with intensively instrumented wind turbine sensors (el. power, SG's in blades, main shaft and tower and operational signals from the wind turbine).

1. [List of mast signals](./ts_wt/nm92/mast_ts_signals.csv)

2. [List of turbine signals](./ts_wt/nm92/wt_ts_signals.csv)

3. [List of additional signals](./ts_wt/nm92/add_signals.csv) Note: The statistics for these signals are only included in the header of the packed ASCII file.
## Nominal values

![](./ts_wt/nm92/nom_speed.png)
**Figure n1:** Nominal wind speed

![A map of Denmark](./ts_wt/nm92/nom_dir.png)
**Figure n3:** Nominal wind direction

## Distributions
NA

## ACKNOWLEDMENTS		
- ACKNOWLEDMENTS	:	Aalborg University and Research Center Risoe
- INSTITUTION       :	Wind Energy Structures and Technology, Aalborg
- ADDRESS 	        :   Sohngaardsholmsvej 57, 9000  Aalborg
- TEL/FAX 	        :   +45 9635 8581 / +54 9814 8243
- CONTACTS          :  John D. Sørensen / Uwe S. Paulsen
- COLLABS 	        :  AAU, Risoe & DTU
- PERIOD 	        :  2005-11-19 - 2006-01-20
- Naming_authority  : 'DTU Data'
- DOI               : 'https://doi.org/10.11583/DTU.16743739'

## PUBLICATIONS	    : 
1. NA

## Public data
Run statistics stored as NetCDF format:
1. nm92_all.nc (NetCDF)
2. nm92_concurrent.nc (NetCDF)

Raw time series (ascii), each with a duration of 600 sec, sampled with 8 Hz:<br> 
3. nm92.zip 



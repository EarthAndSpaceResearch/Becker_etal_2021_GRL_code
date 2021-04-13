# Becker_etal_2021_GRL_code

<b>Code for Ice-Front and Rampart-Moat Detection and Quantification in ICESat-2 Laser Altimetry</b>

Becker, M. K., Howard, S. L., Fricker, H. A., Padman, L., Mosbeux, C., & Siegfried, M. R. (2021).  Buoyancy‐driven flexure at the front of Ross Ice Shelf, Antarctica, observed with ICESat‐2 laser altimetry.  <i>Geophysical Research Letters</i>, 48, e2020GL091207. https://doi.org/10.1029/2020GL091207


The Becker_etal_2021_GRL_code provides step-by-step tools to download a region of the ICESat-2 ATL06 Land Ice Height along-track product (Smith et al., 2019) using Python, build a user-friendly structure in MATLAB, clean up outliers, and then look for large along-track jumps in the height (satisfying specified criteria) to identify the ice shelf front.  The code is currently tested on the Ross Ice Shelf (Figure 1a), where ICESat-2 tracks are usually close to orthogonal to the ice front, and height criteria for distinguishing between open water (including with sea ice cover) and the ice shelf surface are easily established. The method is designed around stepping along the track from open water to the ice shelf.

Once the ice front is detected, the code looks for rampart-moat features (Figure 1b,c) and quantifies them according to the height of the rampart relative to the moat (dhRM), and the along-track distance from the ice front to the lowest portion of the moat (dxRM).  
  
  
For more information, see the methods section of Becker et al. (2021) and Readme.pdf.


<image src="fig1_readme.jpg">


Figure 1. (a) Map showing the distribution of ICESat-2 reference ground tracks (RGTs) near the Ross Ice Shelf (RIS) front (ascending in red and descending in blue) overlaid on a December 2, 2018, Moderate Resolution Imaging Spectroradiometer (MODIS) image downloaded from NASA Worldview. The Depoorter et al. (2013) ice-shelf mask is shown with a black line. Gray lines on the ice shelf show modern ice streamlines derived from Rignot et al. (2017) velocity fields, with the streamline delineating the boundary between ice originating from the West and East Antarctic ice sheets (WAIS and EAIS, respectively) in black. Inset map (created using Antarctic Mapping Tools data; Greene et al., 2017) features the Mouginot et al. (2017) WAIS–EAIS boundary. (b) Schematic of ice-shelf bench (hatched area), R-M structure, and the conditions under which the bench forms. Three relevant R-M parameters, relative height (dhRM), relative along-track distance (dxRM), and near-front thickness (H), are indicated. (c) Height above instantaneous sea surface for Cycle 7 ICESat-2 ATL03 signal (light blue dots) and background (gray dots) photons, andATL06 segments (dark blue dots) for gt3r (strong beam) for RGT 0487, which is labeled in (a). ATL06-derived rampart and moat locations are marked as red crosses. 


<hr>

<h2>The scripts in this package are:</h2>

<b>Step_01_download_ross_front_atl06_data.ipynb:</b>

This Python notebook uses the icepyx library (Scheick et al., 2019; https://github.com/icesat2py/icepyx) to download spatially and temporally subsetted ATL06 granules from the National Snow and Ice Data Center. Running this notebook should result in the download of these granules in the location provided by the user for the (currently commented-out) variable 'path'.
This script implements the ATL06-specific methods described in Subsection 2.2 of Becker et al. (2021).

<i>Requirements:</i> 	
<ul>
<li>	Icepyx library	(https://github.com/icesat2py/icepyx)
<li>	Earthdata login 	(https://urs.earthdata.nasa.gov/)
</ul>
<b>Step_02_build_structure_from_h5_files.m:</b>

This MATLAB script builds and saves a MATLAB structure with all relevant information from the HDF5 files downloaded in Step 01, and plots the approximate ice-shelf front location for each ground track profile over the mask from Depoorter et al. (2013). The user should specify the locations of (1) the HDF5 files with the (currently commented-out) variable 'data_dir,' which should match the path specified at the end of the Step 01 Jupyter Notebook, and (2) the location of the	Depoorter_et_al_2013_mask.mat file containing the Depoorter et al. (2013) mask data.

This script implements part of Step (i) described in Subsection 2.3 of Becker et al. (2021).

<i>Requirements:</i>  
<ul>
<li>ll2ps.m:   This script calls the Antarctic Mapping Tools 'll2ps' function (Greene et al., 2017), which can be downloaded from https://www.mathworks.com/matlabcentral/fileexchange/47638-antarctic-mapping-tools
<li>	Depoorter_et_al_2013_mask.mat:  MATLAB version of the Depoorter et al. (2013) mask, included in this download.
</ul>

<b>Step_03_detect_front.m:</b>

This script cleans up the structure from Step 02; applies various filters, flags, and geophysical corrections; and removes outliers. Then, for each ground track profile, it searches for the ice-shelf front moving from the ocean to the ice shelf; if the front is found, the script gathers various data on the front crossing.
This script implements part of Step (i) and Steps (ii)-(iv) described in Subsection 2.3 of Becker et al. (2021), which also describes choices for cleaning up data, specifically assessed for the Ross Ice Shelf.    

<b>Step_04_detect_rm_features.m:</b>
This script searches each ground track profile in which the ice front was detected for a rampart-moat (R-M) structure. If an R-M structure is found, it gathers various data on the structure that can be used to compute dhRM and dxRM.
This script implements Step (v) described in Subsection 2.3 of Becker et al. (2021).



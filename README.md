# Becker_etal_2021_GRL_code

<b>Code for Ice-Front and Rampart-Moat Detection and Quantification in ICESat-2 Laser Altimetry</b>

Becker, M. K., Howard, S. L., Fricker, H. A., Padman, L., Mosbeux, C., & Siegfried, M. R. (2021).  Buoyancy‐driven flexure at the front of Ross Ice Shelf, Antarctica, observed with ICESat‐2 laser altimetry.  <i>Geophysical Research Letters</i>, 48, e2020GL091207. https://doi.org/10.1029/2020GL091207


The Becker_etal_2021_GRL_code provides step-by-step tools to download a region of the ICESat-2 ATL06 Land Ice Height along-track product (Smith et al., 2019) using Python, build a user-friendly structure in MATLAB, clean up outliers, and then look for large along-track jumps in the height (satisfying specified criteria) to identify the ice shelf front.  The code is currently tested on the Ross Ice Shelf (Figure 1a), where ICESat-2 tracks are usually close to orthogonal to the ice front, and height criteria for distinguishing between open water (including with sea ice cover) and the ice shelf surface are easily established. The method is designed around stepping along the track from open water to the ice shelf.

Once the ice front is detected, the code looks for rampart-moat features (Figure 1b,c) and quantifies them according to the height of the rampart relative to the moat (dhRM), and the along-track distance from the ice front to the lowest portion of the moat (dxRM).  

For more information, see the methods section of Becker et al. (2021) and Readme.pdf.

<image src="fig1_readme.jpg">

Figure 1. (a) Map showing the distribution of ICESat-2 reference ground tracks (RGTs) near the Ross Ice Shelf (RIS) front (ascending in red and descending in blue) overlaid on a December 2, 2018, Moderate Resolution Imaging Spectroradiometer (MODIS) image downloaded from NASA Worldview. The Depoorter et al. (2013) ice-shelf mask is shown with a black line. Gray lines on the ice shelf show modern ice streamlines derived from Rignot et al. (2017) velocity fields, with the streamline delineating the boundary between ice originating from the West and East Antarctic ice sheets (WAIS and EAIS, respectively) in black. Inset map (created using Antarctic Mapping Tools data; Greene et al., 2017) features the Mouginot et al. (2017) WAIS–EAIS boundary. (b) Schematic of ice-shelf bench (hatched area), R-M structure, and the conditions under which the bench forms. Three relevant R-M parameters, relative height (dhRM), relative along-track distance (dxRM), and near-front thickness (H), are indicated. (c) Height above instantaneous sea surface for Cycle 7 ICESat-2 ATL03 signal (light blue dots) and background (gray dots) photons, andATL06 segments (dark blue dots) for gt3r (strong beam) for RGT 0487, which is labeled in (a). ATL06-derived rampart and moat locations are marked as red crosses. 

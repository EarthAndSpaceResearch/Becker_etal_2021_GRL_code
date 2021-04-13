# Becker_etal_2021_GRL_code

<b>Code for Ice-Front and Rampart-Moat Detection and Quantification in ICESat-2 Laser Altimetry</b>

Becker, M. K., Howard, S. L., Fricker, H. A., Padman, L., Mosbeux, C., & Siegfried, M. R. (2021).  Buoyancy‐driven flexure at the front of Ross Ice Shelf, Antarctica, observed with ICESat‐2 laser altimetry.  <i>Geophysical Research Letters</i>, 48, e2020GL091207. https://doi.org/10.1029/2020GL091207


The Becker_etal_2021_GRL_code provides step-by-step tools to download a region of the ICESat-2 ATL06 Land Ice Height along-track product (Smith et al., 2019) using Python, build a user-friendly structure in MATLAB, clean up outliers, and then look for large along-track jumps in the height (satisfying specified criteria) to identify the ice shelf front.  The code is currently tested on the Ross Ice Shelf, where ICESat-2 tracks are usually close to orthogonal to the ice front, and height criteria for distinguishing between open water (including with sea ice cover) and the ice shelf surface are easily established. The method is designed around stepping along the track from open water to the ice shelf.

Once the ice front is detected, the code looks for rampart-moat features and quantifies them according to the height of the rampart relative to the moat (dhRM), and the along-track distance from the ice front to the lowest portion of the moat (dxRM).  

For more information, see the methods section of Becker et al. (2021) and Readme.pdf.


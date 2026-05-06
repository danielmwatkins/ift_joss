---
title: 'IceFloeTracker.jl: A Julia package for tracking sea ice floes from optical remote sensing imagery'
tags:
  - Julia
  - remote sensing
  - sea ice
  - climate science
authors:
  - name: Daniel M. Watkins
    orcid:
    affiliation: 1
  - name: Carlos Paniagua
    orcid: 0000-0001-5011-7854
    affiliation: 2
  - name: John Holland
    orcid:
    affiliation: 2
  - name: Timothy Divoll
    orcid: 0000-0002-2586-6842
    affiliation: 2
  - name: Minki Kim
    orcid:
    affiliation: 1
  - name: Ellen Buckley
    orcid: 0000-0001-7415-5054
    affiliation: 3
  - name: Jennifer K. Hutchings
    orcid:
    affiliation: 4
  - name: Maria I. Restrepo
    orcid:
    affiliation: 2
  - name: Monica Martinez Wilhelmus
    orcid:
    affiliation: 1
affiliations:
  - name: Center for Fluid Mechanics, School of Engineering, Brown University, Providence, RI, USA
    index: 1
  - name: Center for Computing and Visualization, Brown University, Providence, RI, USA
    index: 2
  - name: Department of Earth Science and Environmental Change, University of Illinois Urbana-Champagne, Urbana, IL, USA
    index: 3
  - name: College of Earth, Ocean, and Atmospheric Science, Oregon State University, Corvallis, OR, 97331
    index: 4
date: 4 April 2025
bibliography: paper.bib
---
# Summary
IceFloeTracker.jl provides tools and workflows to derive measurements of sea ice floe shapes and motion from optical satellite imagery. 

# Statement of need
Sea ice motion is a key parameter for the Arctic climate system. The drift of sea ice affects air-ocean interaction, marine ecology, and safety for marine navigation. Sea ice drift is typically measured in situ using buoys and moorings. In situ measurements are sparse, particularly in the fast-moving marginal ice zone. Remote sensing provides a larger-scale view of the sea ice state. Ice motion can be derived from pairwise comparison of remote sensing images through feature or area matching algorithms, typically using cross-correlation techniques. Strong deformation and rotation in the highly dynamic marginal ice zone limit the applicability of standard remote sensing algorithms for this region. Complications with remote sensing of melting sea ice during summer add uncertainty.

The Ice Floe Tracker (IFT) algorithm takes a different approach. A key difference between the marginal ice zone and pack ice is that individual sea ice floes can often be discerned in optical imagery. By detecting individual floes, characterizing them, and linking identical floes across image pairs, not only is it possible to track sea ice motion, but also to observe floe shapes and track the rotation of sea ice. The algorithm was initially developed and tested in MATLAB [@lopez-acosta2019]. IceFloeTracker.jl is a full re-implementation of the original IFT algorithm using open-source Julia and Python libraries. The package is modular, enabling users to calibrate the algorithm to individual use cases, and takes advantage of Julia's efficient parallelization abilities. The package includes a full suite of tests and a set of Jupyter notebooks demonstrating the core functionality.

# Examples
## Image preprocessing
IFT operates on optical satellite imagery. The main functions are designed with "true color" and "false color" imagery in mind, and have thus far primarily been tested on imagery from the Moderate Resolution Imaging Spectroradiometer (MODIS) from the NASA Aqua and Terra satellites. The preprocessing routines mask land and cloud features, and aim to adjust and sharpen the remainder of the images to amplify the contrast along the edges of sea ice floes.

## Segmentation
The IFT segmentation functions include functions for semantic segmentation (pixel-by-pixel assignment into predefined categories) and object-based segmentation (groupings of pixels into distinct objects). The semantic segmentation steps use kk-means to group pixels into water and ice regions. A combination of watershed functions, morphological operations, and further applications of kk-means are used to identify candidate ice floes. 

## Tracking floes
Ice floe tracking is carried out by comparing the shapes produced in the segmentation step. Shapes with similar area are rotated until the difference in surface area is minimized, and then the edge shapes are compared using a Ѱ-s curve. If thresholds for correlation and area differences are met, then the floe with the best correlation and smallest area differences are considered matches and the objects are assigned the same label. In the end, trajectories for individual floes are recorded in a dataframe.

# Acknowledgments
% NASA imagery
% Funding agencies

# References
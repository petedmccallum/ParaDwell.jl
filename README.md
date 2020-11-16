# ParaDwell.jl

## Installation

### Via Julia REPL

Within the Julia package manger (key `]` into REPL, to provide `(@vX.X) pkg>` prompt):

```julia
add ParaDwell
```

### Recommended setup

Create two new empty directories: one for all ParaDwell projects, and a separate directory for basemap data. The project directory will contain subdirectories for each of your projects, along with some config files in the root (auto generated when you run ParaDwell for the first time). Over time this could require 1-10GB, depending on workload. For the basemap directory, a single country should not exceed 30MB.

### Data for basemap

ParaDwell currently supports use of the free DIVA-GIS data resource for lightweight national-scale basemaps. These can be downloaded here for your chosen territory:

- https://www.diva-gis.org/gdata (select "Administration areas" from the "Subject" dropdown menu)

### Usage

From the Julia REPL

```julia
using ParaDwell
```

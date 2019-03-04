# Basic-Variant-Filter: Perform basic somatic variant filtration using a filtration string.

## Introduction

Somatic variant manual review usually starts with some basic filtration to weed out obviously incorrect calls made by variant caller(s).  This process is usually done with ad-hoc bash scripts, using awk and/or sed, but leads to great variation.  This script, implemented in [Haskell](https://www.haskell.org/), provides a standardized method for basic filtration on somatic variant data using a filtration string.

## Prerequisites

**bvf.hs** assumes you have a the [GHC](https://www.haskell.org/ghc/) compiler and packages installed that it imports.  The easiest way to do this is to download the [Haskell Platform](https://www.haskell.org/platform/).<br/><br/>

## Installing required packages

To install the peripheral packages **bvf.hs** requires, you can call the following command assuming you have [cabal](https://www.haskell.org/cabal/), a package manager and build system for Haskell, installed on your system (it comes with the [Haskell Platform](https://www.haskell.org/platform/)).<br/><br/>
`$ cabal install [packagename]`<br/><br/>

**Required packages**
 - Text.PrettyPrint.Boxes
 - System.Process
 - Data.List.Split 
 - System.Temporary

## Input

A rerequisite for getting useful output from this script is to have the correct input file structure.  This script (at this point in time) assumes that the header of the file is the first line of the file, and that all headers in the file are the same.<br/><br/>
For example:<br/><br/>
```
TUMOR.AD NORMAL.AD TUMOR.AF
23,32 43,45 3.2
TUMOR.AD NORMAL.AD TUMOR.AF
53,23 12,13 2.1
32,13 32,34 5.1
TUMOR.AD NORMAL.AD TUMOR.AF
34,53 42,23 4.4
```

## Usage

**bvf.hs** is easy to use.<br/><br/>
You can call it using the **runghc** command provided by the GHC compiler as such:<br/><br/>
`$ runghc bvf.hs inputfile.tsv`<br/><br/>
For maximum performance, please compile and run the source code as follows:<br/><br/>
`$ ghc -O2 -o BVF bvf.hs`<br/><br/>
`$ ./BVF inputfile.tsv`<br/><br/>

## Filtration String

The default behavior of running **bvf.hs** on a input .tsv file is to cat it back to the user.<br/>

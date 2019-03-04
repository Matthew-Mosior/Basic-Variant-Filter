# Basic-Variant-Filter: Perform basic somatic variant filtration using a filtration string.

## Introduction

Somatic variant manual review usually starts with some basic filtration to weed out obviously incorrect calls made by variant caller(s), low read depth, and so on.  This process is usually done with ad-hoc bash scripts, using awk and/or sed, but leads to great variation.  This script, implemented in [Haskell](https://www.haskell.org/), provides a standardized method for basic filtration on somatic variant data using a filtration string.

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
TUMOR.AD NORMAL.AD TUMOR.AF MUTATION
23,32 43,45 3.2 missense
TUMOR.AD NORMAL.AD TUMOR.AF MUTATION
53,23 12,13 2.1 noncoding
32,13 32,34 5.1 missense
TUMOR.AD NORMAL.AD TUMOR.AF MUTATION
34,53 42,23 4.4 missense
```

## Usage

**bvf.hs** is easy to use.<br/><br/>
You can call it using the **runghc** command provided by the GHC compiler as such:<br/><br/>
`$ runghc bvf.hs inputfile.tsv`<br/><br/>
For maximum performance, please compile and run the source code as follows:<br/><br/>
`$ ghc -O2 -o BVF bvf.hs`<br/><br/>
`$ ./BVF inputfile.tsv`<br/><br/>

## Arguments

**bvf.hs** has few different command line arguments:<br/>
```
Usage: bvf [-vV?ioF] [file]
  -v          --verbose              Output on stderr.
  -V, -?      --version              Show version number.
  -o OUTFILE  --outputfile=OUTFILE   The output file.
  -F FIELDS   --filterfields=FIELDS  The fields to filter on.
  -S          --stripheader          Strip the headers in the file.
              --help                 Print this help message.
```
The `-V` option, the `version` option, will show the version of `bvf` in use.<br/>
The `-o` option, the `outputfile` option, is used to output the operation (or lack thereof) on the input .tsv file into a output file, whose name is specified by the user, for example `filteredinput.tsv`.<br/>
The `-F` option, the `filterfields` option, which is where the user specifies the **filtration string** that will be used by **bvf** to filter the input .tsv file.<br/>
The `-S` option, the `stripheader` option, tells **bvf** to strip all lines in the input .tsv file that are header lines (any line that matches the first line of the input .tsv file).<br/>
Finally, the `--help` option outputs the `help` message seen above.

## Filtration String

The default behavior of running **bvf.hs** on a input .tsv file is to `cat` it back to the user.<br/><br/>
This behavior is desirable because the user can quickly see differences in filtration schemes by then piping into `wc -l`, or any other unix tool for that matter.<br/>  
This also allows the user to apply filtration schemes only to specific rows of the input .tsv file based on the value of any given column.<br/><br/>
The **filtration string** describes the filtration that will occur on the input file.  It is a simple, standardized, string based command line argument with the following structure:<br/><br/>
`;COLUMNOFFILTRATION:STRUCTURE~OPERATION~COMPARISON;`<br/><br/>
The **filtration string** can be as many different filtrations as you would like:<br/><br/>
`;TUMOR.AD:x,y~+~>=40;TUMOR.AF:x:~|~>=3.0;`<br/><br/>
Please see the [wiki](https://github.com/Matthew-Mosior/Basic-Variant-Filter/wiki) for more in-depth usage examples and explanation.

## Docker 

A docker-based solution (Dockerfile) is availible in the corresponding [repository](https://github.com/Matthew-Mosior/Basic-Variant-Filter---Docker).  Currently, this Dockerfile assumes that you run docker interactively.

## Credits

Documentation was added March 2019.<br/>
Author : [Matthew Mosior](https://github.com/Matthew-Mosior)

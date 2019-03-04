# Basic-Variant-Filter: Perform basic somatic variant filtration using a filtration string.

## Introduction

Somatic variant manual review usually starts with some basic filtration to weed out obviously incorrect calls made by variant caller(s).  This process is usually done with ad-hoc bash scripts, using awk and/or sed, but leads to great variation.  This script, implemented in [Haskell](https://www.haskell.org/), provides a standardized method for basic filtration on somatic variant data using a filtration string.

## Prerequisites

**bvf.hs

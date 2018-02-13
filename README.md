
<!-- README.md is generated from README.Rmd. Please edit that file -->
hierarchical
============

`hierarchical` provides tools for manipulations, transformations and analysis of hierarchical data

Example of decomposition of financial ratios
--------------------------------------------

### Simulate random data

``` r
library(data.table)
library(data.tree)

# load example data
data("Angell", package = "car")
DT <- as.data.table(Angell, keep.rownames = TRUE)[sample(1:.N, 20)]
setnames(DT, "rn", "name")

# simulate financial data
DT <- rbindlist(list("2016" = DT, "2007" = DT), idcol = "year")
DT[, cost   := 1000*rgamma(.N, 30, 30)]
DT[, income := 1000*rgamma(.N, 31, 31)]

# compute first differences
setkey(DT, region, name, year)
DT[, cost_diff   := c(NA, diff(cost)),   by = .(region, name)]
DT[, income_diff := c(NA, diff(income)), by = .(region, name)]
DT[, cost_to_income := cost / income]
```

### Convertion of data.table into a data.tree

``` r
library(hierarchical)

tree <- dt2tree_ratio(DT, 
                      tree_name       = "Total", 
                      numerator_name  = "cost", 
                      denomiator_name = "income", 
                      dim_names       = c("region", "name"))
```

### Decomposition of ratios

``` r
tree$Do(decomp_ratios_root_full, 
        root_denominator_curr = tree$denominator_curr,
        root_denominator_lag  = tree$denominator_lag, 
        multipl = 1)
```

### Output

You can print "ratio\_effect", "weight\_effect" and "residual\_effect" using `data.tree` methods:

``` r
print(tree, "ratio_curr", "ratio_effect", "weight_effect")
#>                  levelName ratio_curr  ratio_effect weight_effect
#> 1  Total                    0.9909652  0.0159918260  0.0000000000
#> 2   ¦--E                    0.9672721  0.0200041739 -0.0145076320
#> 3   ¦   ¦--Baltimore        0.8817845  0.0127566398 -0.0036459986
#> 4   ¦   ¦--Buffalo          0.9487093  0.0039434231 -0.0035053955
#> 5   ¦   °--Worcester        1.0638253  0.0034724126 -0.0075098651
#> 6   ¦--MW                   1.1059466  0.0233242015 -0.0008611487
#> 7   ¦   ¦--Cleveland        1.1256950 -0.0052169306 -0.0058803028
#> 8   ¦   ¦--Dayton           0.9219183  0.0035846708  0.0025039691
#> 9   ¦   ¦--Detroit          1.3077124  0.0132455873  0.0017105690
#> 10  ¦   ¦--Grand_Rapids     1.2305227  0.0063665724 -0.0010022376
#> 11  ¦   °--Wichita          1.0366086  0.0057391812  0.0001055988
#> 12  ¦--S                    0.8857506 -0.0155845514  0.0213519641
#> 13  ¦   ¦--Birmingham       1.0128867 -0.0058704028 -0.0021249986
#> 14  ¦   ¦--Dallas           0.5832286 -0.0045679788  0.0126770780
#> 15  ¦   ¦--Fort_Worth       0.8127265 -0.0038547604  0.0139416478
#> 16  ¦   ¦--Jacksonville     0.8853529 -0.0047438980 -0.0035327664
#> 17  ¦   ¦--Louisville       1.0454229  0.0085921156 -0.0031745044
#> 18  ¦   ¦--Miami            1.0308872  0.0089663563 -0.0046741948
#> 19  ¦   ¦--Richmond         0.7770999 -0.0002884438  0.0022290064
#> 20  ¦   °--Tulsa            1.0435675 -0.0053582808  0.0012642425
#> 21  °--W                    1.1091122 -0.0090102934 -0.0060352140
#> 22      ¦--Denver           1.3820933 -0.0002737985 -0.0070688355
#> 23      ¦--Portland_Oregon  0.8325422 -0.0061296895  0.0010959100
#> 24      ¦--San_Diego        1.1718319 -0.0013285572  0.0041425700
#> 25      °--Seattle          1.1296734  0.0003118413 -0.0053117305
```

...or print it using `ggplot2`

``` r
library(ggplot2)
# debug(plot_tree_ratio)
plot_tree_ratio(tree)  +
  ggtitle("Decompositon of consolidated cost-to-income ratio") +
  xlab("Entitity") + 
  theme(legend.text = element_text(size = 7))
#> Warning: Removed 6 rows containing missing values (position_stack).
```

<img src="man/figures/README-decomp plot-1.png" width="80%" />

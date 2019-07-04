
<!-- README.md is generated from README.Rmd. Please edit that file -->

# hierarchical

`hierarchical` provides tools for manipulations, transformations and
analysis of hierarchical data

## Example of decomposition of financial ratios

### Simulate random data

``` r
library(data.table)
library(data.tree)

# load example data
data("Angell", package = "carData")
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

You can print “ratio\_effect”, “weight\_effect” and “residual\_effect”
using `data.tree` methods:

``` r
print(tree, "ratio_curr", "ratio_effect", "weight_effect")
#>                  levelName ratio_curr  ratio_effect weight_effect
#> 1  Total                    1.0242344  0.0187478977  0.0000000000
#> 2   ¦--E                    1.0982822  0.0207443777 -0.0096163751
#> 3   ¦   ¦--Bridgeport       1.1408110  0.0044723195 -0.0082824887
#> 4   ¦   ¦--Erie             0.9413373  0.0198442010 -0.0023120753
#> 5   ¦   ¦--Rochester        1.0772549 -0.0008298147  0.0032020078
#> 6   ¦   ¦--Syracuse         1.2070468 -0.0185743241  0.0174150891
#> 7   ¦   °--Trenton          1.1667929  0.0152941628 -0.0093834525
#> 8   ¦--MW                   0.8845153 -0.0162494611  0.0212309458
#> 9   ¦   ¦--Akron            0.7667057 -0.0001555765  0.0016008515
#> 10  ¦   ¦--Des_Moines       0.8747353 -0.0095667203  0.0048993319
#> 11  ¦   ¦--Flint            1.0057868 -0.0072397696  0.0013945103
#> 12  ¦   ¦--Grand_Rapids     0.8745463 -0.0022124451  0.0106129128
#> 13  ¦   °--Wichita          0.9165926  0.0030851838  0.0026016799
#> 14  ¦--S                    1.1207650  0.0256686538 -0.0086960330
#> 15  ¦   ¦--Atlanta          1.3833759 -0.0071593085  0.0074456291
#> 16  ¦   ¦--Chattanooga      1.1541022  0.0041381951 -0.0063128754
#> 17  ¦   ¦--Jacksonville     1.4078405  0.0207652405 -0.0057685404
#> 18  ¦   ¦--Louisville       0.9915777  0.0045227707 -0.0048828542
#> 19  ¦   ¦--Miami            0.7532886  0.0029089340 -0.0013051727
#> 20  ¦   °--Nashville        1.3178237 -0.0013358667  0.0085001737
#> 21  °--W                    0.9861394 -0.0069512687 -0.0045349363
#> 22      ¦--Denver           0.7459502 -0.0010118923  0.0016424472
#> 23      ¦--Portland_Oregon  1.0993614 -0.0065480976 -0.0026359979
#> 24      ¦--Seattle          1.1212477  0.0011355494 -0.0041835407
#> 25      °--Tacoma           0.9794753  0.0007455685 -0.0005798143
```

…or print it using `ggplot2`

``` r
library(ggplot2)
plot_tree_ratio(tree)  +
  ggtitle("Decompositon of consolidated cost-to-income ratio") +
  xlab("Entitity") + 
  theme(legend.text = element_text(size = 7))
#> Warning: Removed 6 rows containing missing values (position_stack).
```

<img src="man/figures/README-decomp plot-1.png" width="70%" />

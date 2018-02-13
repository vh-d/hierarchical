
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
#>                levelName ratio_curr  ratio_effect weight_effect
#> 1  Total                  1.0491914  2.510644e-02  0.000000e+00
#> 2   ¦--E                  0.9376751 -2.109860e-02  1.276377e-03
#> 3   ¦   ¦--Baltimore      1.2280288 -1.116270e-02  5.068415e-03
#> 4   ¦   ¦--Bridgeport     1.0120745 -6.726540e-03  5.739426e-03
#> 5   ¦   ¦--Buffalo        0.7856001 -8.364793e-04 -1.348576e-04
#> 6   ¦   ¦--Reading        0.6608205 -3.952830e-03  1.138159e-03
#> 7   ¦   ¦--Trenton        1.2694401 -2.260667e-03 -3.531746e-04
#> 8   ¦   °--Worcester      0.7781986  1.648550e-03 -6.255720e-03
#> 9   ¦--MW                 1.1528290  1.537990e-02  7.313476e-03
#> 10  ¦   ¦--Akron          1.1657580  1.895483e-02 -3.563513e-03
#> 11  ¦   ¦--Cleveland      1.4371577 -2.142559e-03  4.821251e-03
#> 12  ¦   ¦--Columbus       1.2153698 -9.246840e-03  7.124880e-03
#> 13  ¦   ¦--Detroit        1.1062127 -1.494626e-03  3.263955e-03
#> 14  ¦   ¦--Flint          0.9006267  4.407644e-03 -1.008243e-03
#> 15  ¦   °--South_Bend     1.0864841  3.616705e-03  1.181168e-03
#> 16  ¦--S                  1.0586209  3.301518e-02 -3.875463e-03
#> 17  ¦   ¦--Atlanta        0.9070976 -4.353478e-03  8.585333e-04
#> 18  ¦   ¦--Birmingham     1.5113376  1.837947e-02 -3.827558e-03
#> 19  ¦   ¦--Fort_Worth     0.8701881 -7.956143e-03  1.552392e-02
#> 20  ¦   ¦--Nashville      0.8479875  1.038453e-02 -5.351984e-03
#> 21  ¦   ¦--Oklahoma_City  1.3007378  3.444404e-03  1.311768e-05
#> 22  ¦   °--Richmond       1.1172262  1.648455e-02 -7.204849e-03
#> 23  °--W                  1.0763214 -2.595235e-03 -4.247708e-03
#> 24      ¦--Spokane        1.1647245  2.463426e-05 -5.145969e-03
#> 25      °--Tacoma         1.0052164 -2.188395e-03  6.008718e-04
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

<img src="man/figures/README-decomp plot-1.png" width="70%" />

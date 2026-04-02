# snapshot: Skellam distribution shape (equal lambdas)

    Code
      out
    Output
         gd     prob
      1  -8 0.000018
      2  -7 0.000114
      3  -6 0.000632
      4  -5 0.003029
      5  -4 0.012283
      6  -3 0.040823
      7  -2 0.106489
      8  -1 0.204652
      9   0 0.263914
      10  1 0.204652
      11  2 0.106489
      12  3 0.040823
      13  4 0.012283
      14  5 0.003029
      15  6 0.000632
      16  7 0.000114
      17  8 0.000018

# snapshot: Skellam distribution shape (home-skewed)

    Code
      out
    Output
         gd     prob
      1  -8 0.000001
      2  -7 0.000008
      3  -6 0.000062
      4  -5 0.000431
      5  -4 0.002519
      6  -3 0.012059
      7  -2 0.045237
      8  -1 0.124644
      9   0 0.228967
      10  1 0.249289
      11  2 0.180946
      12  3 0.096475
      13  4 0.040310
      14  5 0.013794
      15  6 0.003988
      16  7 0.000997
      17  8 0.000220

# snapshot: predict_match canonical scenario

    Code
      snap
    Output
             metric  value
      1          mu 1.1500
      2 lambda_home 1.9250
      3 lambda_away 0.7750
      4      prob_h 0.6451
      5      prob_d 0.2117
      6      prob_a 0.1432

# snapshot: predict_match with form signal

    Code
      snap
    Output
             metric  value
      1          mu 0.9000
      2 lambda_home 1.7500
      3 lambda_away 0.8500
      4      prob_h 0.5871
      5      prob_d 0.2333
      6      prob_a 0.1796

# snapshot: predict_match GD distribution

    Code
      gd
    Output
      # A tibble: 17 x 2
            gd    prob
         <int>   <dbl>
       1    -8 0      
       2    -7 0.00003
       3    -6 0.00021
       4    -5 0.0012 
       5    -4 0.00577
       6    -3 0.0227 
       7    -2 0.0704 
       8    -1 0.161  
       9     0 0.249  
      10     1 0.234  
      11     2 0.149  
      12     3 0.0700 
      13     4 0.0258 
      14     5 0.00783
      15     6 0.00201
      16     7 0.00044
      17     8 0.00009

# snapshot: staking across edge range

    Code
      out
    Output
          edge stake
      1  -0.05     0
      2  -0.04     0
      3  -0.03     0
      4  -0.02     0
      5  -0.01     0
      6   0.00     0
      7   0.01     0
      8   0.02     0
      9   0.03     0
      10  0.04     0
      11  0.05     1
      12  0.06     1
      13  0.07     1
      14  0.08     1
      15  0.09     1
      16  0.10     2
      17  0.11     2
      18  0.12     2
      19  0.13     2
      20  0.14     2
      21  0.15     2
      22  0.16     2
      23  0.17     2
      24  0.18     2
      25  0.19     2
      26  0.20     2

# snapshot: grid structure

    Code
      grid
    Output
      # A tibble: 27 x 6
         window half_life tau_min     K  beta tau_double
          <int>     <dbl>   <dbl> <int> <dbl>      <dbl>
       1      6         1    0.05     4   0.3       0.1 
       2      6         1    0.07     4   0.3       0.14
       3      6         1    0.1      4   0.3       0.2 
       4      6         2    0.05     4   0.3       0.1 
       5      6         2    0.07     4   0.3       0.14
       6      6         2    0.1      4   0.3       0.2 
       7      6         3    0.05     4   0.3       0.1 
       8      6         3    0.07     4   0.3       0.14
       9      6         3    0.1      4   0.3       0.2 
      10      8         1    0.05     4   0.3       0.1 
      # i 17 more rows


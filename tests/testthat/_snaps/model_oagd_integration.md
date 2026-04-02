# snapshot: oagd_fit_window strengths for E0 2425 matchday 10

    Code
      snap
    Output
      # A tibble: 20 x 4
         team           alpha_home alpha_away  alpha
         <chr>               <dbl>      <dbl>  <dbl>
       1 Liverpool           0.58      -0.598  0.589
       2 Tottenham           0.964     -0.027  0.495
       3 Man City            0.376     -0.425  0.4  
       4 Chelsea             0.067     -0.687  0.377
       5 Arsenal             0.486     -0.258  0.372
       6 Nott'm Forest       0.092     -0.441  0.266
       7 Brighton            0.058     -0.26   0.159
       8 Bournemouth         0.372      0.182  0.095
       9 Aston Villa        -0.06      -0.185  0.063
      10 Newcastle           0.143      0.14   0.001
      11 Fulham              0.025      0.072 -0.024
      12 Brentford           0.321      0.391 -0.035
      13 Man United         -0.431     -0.092 -0.17 
      14 West Ham           -0.227      0.158 -0.193
      15 Leicester          -0.297      0.153 -0.225
      16 Crystal Palace     -0.273      0.228 -0.251
      17 Everton            -0.453      0.298 -0.376
      18 Ipswich            -0.491      0.529 -0.51 
      19 Southampton        -0.563      0.464 -0.513
      20 Wolves             -0.686      0.357 -0.521

# snapshot: full pipeline E0 2425 predictions sample

    Code
      snap
    Output
      # A tibble: 10 x 6
         home_team      away_team     gd_home pred_h pred_d pred_a
         <chr>          <chr>           <dbl>  <dbl>  <dbl>  <dbl>
       1 Aston Villa    Leicester           1  0.474  0.251  0.275
       2 Brighton       Arsenal             0  0.153  0.216  0.63 
       3 Chelsea        Bournemouth         0  0.211  0.237  0.552
       4 Crystal Palace Chelsea             0  0.407  0.257  0.336
       5 Fulham         Ipswich             0  0.381  0.258  0.361
       6 Liverpool      Man United          0  0.737  0.177  0.086
       7 Man City       West Ham            3  0.441  0.255  0.304
       8 Southampton    Brentford          -5  0.338  0.257  0.404
       9 Tottenham      Newcastle          -1  0.216  0.239  0.545
      10 Wolves         Nott'm Forest      -3  0.302  0.255  0.443

# snapshot: backtest summary E0 2425

    Code
      snap
    Output
      # A tibble: 3 x 8
        outcome_bet n_bets n_wins total_staked total_pnl roi_pct sharpe max_drawdown
        <chr>        <dbl>  <dbl>        <dbl>     <dbl>   <dbl>  <dbl>        <dbl>
      1 A              139     43          238      13.7     5.7   0.03        -21  
      2 D               51      8           57     -10.8   -19    -0.1         -13.3
      3 H               84     24          134     -25.2   -18.8  -0.12        -25.2


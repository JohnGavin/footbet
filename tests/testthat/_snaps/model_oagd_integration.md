# snapshot: oagd_fit_window strengths for E0 2425 matchday 10

    Code
      snap
    Output
      # A tibble: 20 x 3
         team           attack defence
         <chr>           <dbl>   <dbl>
       1 Brentford       0.157   0.005
       2 Tottenham       0.157  -0.005
       3 Arsenal         0.096  -0.001
       4 Man City        0.096  -0.001
       5 Brighton        0.033   0.001
       6 Fulham          0.033   0.001
       7 Liverpool       0.033  -0.008
       8 Bournemouth     0.011  -0.005
       9 Chelsea         0.011   0.001
      10 West Ham        0.011   0.007
      11 Aston Villa    -0.011  -0.001
      12 Wolves         -0.011   0.015
      13 Nott'm Forest  -0.034  -0.008
      14 Everton        -0.056   0.003
      15 Leicester      -0.056   0.001
      16 Newcastle      -0.056  -0.008
      17 Ipswich        -0.079   0.003
      18 Man United     -0.079   0.003
      19 Southampton    -0.079   0.003
      20 Crystal Palace -0.103  -0.003

# snapshot: full pipeline E0 2425 predictions sample

    Code
      snap
    Output
      # A tibble: 10 x 6
         home_team      away_team     gd_home pred_h pred_d pred_a
         <chr>          <chr>           <dbl>  <dbl>  <dbl>  <dbl>
       1 Aston Villa    Leicester           1  0.467  0.313  0.22 
       2 Brighton       Arsenal             0  0.146  0.162  0.692
       3 Chelsea        Bournemouth         0  0.199  0.22   0.581
       4 Crystal Palace Chelsea             0  0.457  0.259  0.283
       5 Fulham         Ipswich             0  0.464  0.238  0.298
       6 Liverpool      Man United          0  0.923  0.052  0.025
       7 Man City       West Ham            3  0.553  0.242  0.205
       8 Southampton    Brentford          -5  0.319  0.309  0.372
       9 Tottenham      Newcastle          -1  0.129  0.125  0.746
      10 Wolves         Nott'm Forest      -3  0.352  0.203  0.446

# snapshot: backtest summary E0 2425

    Code
      snap
    Output
      # A tibble: 2 x 8
        outcome_bet n_bets n_wins total_staked total_pnl roi_pct sharpe max_drawdown
        <chr>        <dbl>  <dbl>        <dbl>     <dbl>   <dbl>  <dbl>        <dbl>
      1 A              145     43          246     -5.84    -2.4  -0.01        -32.6
      2 H               91     26          150    -30.9    -20.6  -0.13        -30.9


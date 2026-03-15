# compute_elo: error on NULL input

    Code
      compute_elo(NULL)
    Condition
      Error in `if (nrow(matches_df) == 0L) ...`:
      ! argument is of length zero

# compute_elo: error on missing matches_df

    Code
      compute_elo()
    Condition
      Error in `compute_elo()`:
      ! `matches_df` is absent but must be supplied.

# devig_odds: error on NULL input

    Code
      devig_odds(NULL)
    Condition
      Error in `if (nrow(odds_df) == 0L) ...`:
      ! argument is of length zero

# log_predictions_batch: error on missing columns

    Code
      log_predictions_batch(con, bad_df)
    Condition
      Error in `log_predictions_batch()`:
      ! Missing required columns: "match_id", "model_name", "prob_h", "prob_d", and "prob_a"

# kelly_fraction: snapshot of edge case output

    Code
      cat("prob=0.6, odds=2.0:", kelly_fraction(0.6, 2), "\n")
    Output
      prob=0.6, odds=2.0: 0.05 
    Code
      cat("prob=0.3, odds=2.0:", kelly_fraction(0.3, 2), "\n")
    Output
      prob=0.3, odds=2.0: 0 
    Code
      cat("prob=0.5, odds=2.0:", kelly_fraction(0.5, 2), "\n")
    Output
      prob=0.5, odds=2.0: 0 

# pipeline mermaid diagram structure is stable

    Code
      generate_data_pipeline_mermaid(here::here())
    Output
      flowchart LR
          subgraph Data["Data Acquisition"]
              FD[football-data.co.uk] --> Parse[parse_fd_csv]
              FD --> Odds[parse_fd_odds]
              FB[FBref/Understat] --> XG[fetch_fbref_matches]
          end
          subgraph Features["Feature Engineering"]
              Parse --> Roll[rolling_goals]
              XG --> Roll
              Roll --> Elo[compute_elo]
          end
          subgraph Models["Prediction Models"]
              Elo --> GLM[Poisson GLM]
              Elo --> DC[Dixon-Coles]
              GLM --> Eval[Walk-Forward CV]
              DC --> Eval
          end
          subgraph Betting["Accumulators & Bankroll"]
              Eval --> Value[find_value_bets]
              Odds --> Devig[devig_odds]
              Devig --> Value
              Value --> Kelly[kelly_fraction]
          end

# CV walkforward mermaid diagram structure is stable

    Code
      generate_cv_walkforward_mermaid(here::here())
    Output
      flowchart TB
          subgraph Fold1[Fold 1]
              T1[Train: Months 1-24] --> V1[Test: Month 25]
          end
          subgraph Fold2[Fold 2]
              T2[Train: Months 1-25] --> V2[Test: Month 26]
          end
          subgraph FoldN[Fold N]
              TN[Train: Months 1 to N-1] --> VN[Test: Month N]
          end
          V1 -.-> T2
          V2 -.-> |...| TN
          V1 --> Agg((Aggregate Metrics))
          V2 --> Agg
          VN --> Agg

# Kelly decision mermaid diagram structure is stable

    Code
      generate_kelly_decision_mermaid(here::here())
    Output
      flowchart TD
          Input[Model Prob + Odds] --> Edge[Calculate Edge]
          Edge --> Check{{Edge > 3%?}}
          Check -->|No| NoBet[No Bet]
          Check -->|Yes| Kelly[Calculate Kelly f*]
          Kelly --> Frac[Apply 0.25 Kelly]
          Frac --> Max{{Stake > 3%?}}
          Max -->|Yes| Cap[Cap at 3%]
          Max -->|No| DD
          Cap --> DD{{Drawdown > 20%?}}
          DD -->|Yes| Halve[Halve Stake]
          DD -->|No| Final[Final Stake]
          Halve --> Final


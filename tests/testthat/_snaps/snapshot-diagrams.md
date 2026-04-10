# generate_data_pipeline_mermaid() output is stable

    Code
      cat(diagram)
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

# generate_cv_walkforward_mermaid() output is stable

    Code
      cat(diagram)
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

# generate_kelly_decision_mermaid() output is stable

    Code
      cat(diagram)
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

# wrap_mermaid_html() structure is stable

    Code
      cat(html)
    Output
      <div class="mermaid">
      %%{init: {'theme': 'dark', 'themeVariables': {'background': '#000000','primaryColor': '#999999','primaryTextColor': '#000000','primaryBorderColor': '#CC0000','lineColor': '#CC0000','secondaryColor': '#333333','tertiaryColor': '#333333'}}}%%
      flowchart LR
          A --> B
      linkStyle default stroke:#CC0000,stroke-width:3px
      </div>

# wrap_mermaid_html() with caption includes caption

    Code
      cat(html)
    Output
      <div class="mermaid">
      %%{init: {'theme': 'dark', 'themeVariables': {'background': '#000000','primaryColor': '#999999','primaryTextColor': '#000000','primaryBorderColor': '#CC0000','lineColor': '#CC0000','secondaryColor': '#333333','tertiaryColor': '#333333'}}}%%
      flowchart LR
          A --> B
      linkStyle default stroke:#CC0000,stroke-width:3px
      </div>
      <p style="text-align:left;font-size:0.9em;color:#cccccc;margin-top:0.5em;user-select:text;-webkit-user-select:text;">Test caption.</p>

# wrap_mermaid_fenced() structure is stable

    Code
      cat(fenced)
    Output
      ```mermaid
      flowchart LR
          A --> B
      ```


import pandas as pd
import os

DATA_PATH = os.path.join(
    os.path.dirname(__file__),
    "data",
    "crop_price_state.csv"
)

price_df = pd.read_csv(DATA_PATH)

def calculate_profit(state, crop, predicted_yield):
    """
    predicted_yield: tonnes per hectare
    """

    row = price_df[
        (price_df["state"].str.lower() == state.lower()) &
        (price_df["crop"].str.lower() == crop.lower())
    ]

    if row.empty:
        return None

    price = float(row.iloc[0]["avg_price_per_tonne"])
    cost = float(row.iloc[0]["avg_cost_per_ha"])

    revenue = predicted_yield * price
    profit = revenue - cost

    return {
        "price_per_tonne": price,
        "cost": cost,
        "revenue": round(revenue, 2),
        "profit": round(profit, 2)
    }

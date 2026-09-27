"""
Light Python layer for Retail SQL Case Study.
Loads CSVs, prints KPIs, saves a few charts (SQL remains the core).
"""
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

BASE = Path(__file__).parent.parent
DATA = BASE / "data"
CHARTS = Path(__file__).parent / "charts"
CHARTS.mkdir(exist_ok=True)

sns.set_theme(style="whitegrid")
plt.rcParams["figure.figsize"] = (10, 5)

stores = pd.read_csv(DATA / "stores.csv")
products = pd.read_csv(DATA / "products.csv")
orders = pd.read_csv(DATA / "orders.csv", parse_dates=["OrderDate"])
items = pd.read_csv(DATA / "order_items.csv")
payments = pd.read_csv(DATA / "payments.csv")

completed = orders[orders["OrderStatus"] == "Completed"]
rev = items.merge(completed[["OrderID"]], on="OrderID").merge(
    products[["ProductID", "Category"]], on="ProductID"
)
store_rev = items.merge(completed[["OrderID", "StoreID"]], on="OrderID").merge(stores, on="StoreID")

print("=" * 50)
print("RETAIL SQL CASE STUDY – KPI SNAPSHOT")
print("=" * 50)
print(f"Completed orders : {len(completed):,}")
print(f"Total revenue    : {rev['LineTotal'].sum():,.2f}")
print(f"Customers (active): {completed['CustomerID'].nunique():,}")
print(f"Stores           : {stores['StoreID'].nunique()}")
print(f"Products         : {len(products)}")

fig, ax = plt.subplots()
rev.groupby("Category")["LineTotal"].sum().sort_values().plot(kind="barh", color="#2b6cb0", ax=ax)
ax.set_title("Revenue by Category")
plt.tight_layout()
plt.savefig(CHARTS / "01_revenue_by_category.png", dpi=140)
plt.close()

fig, ax = plt.subplots()
store_rev.groupby("StoreName")["LineTotal"].sum().sort_values().plot(kind="barh", color="#38a169", ax=ax)
ax.set_title("Revenue by Store")
plt.tight_layout()
plt.savefig(CHARTS / "02_revenue_by_store.png", dpi=140)
plt.close()

m = items.merge(completed[["OrderID", "OrderDate"]], on="OrderID")
m["YearMonth"] = m["OrderDate"].dt.to_period("M").astype(str)
fig, ax = plt.subplots(figsize=(12, 4))
m.groupby("YearMonth")["LineTotal"].sum().plot(ax=ax, marker="o", color="#2b6cb0")
ax.set_title("Monthly Revenue Trend")
ax.tick_params(axis="x", rotation=45)
plt.tight_layout()
plt.savefig(CHARTS / "03_monthly_revenue.png", dpi=140)
plt.close()

fig, ax = plt.subplots()
payments["PaymentMethod"].value_counts().plot.pie(autopct="%1.1f%%", ax=ax, startangle=90)
ax.set_ylabel("")
ax.set_title("Payment Method Mix")
plt.tight_layout()
plt.savefig(CHARTS / "04_payment_mix.png", dpi=140)
plt.close()

fig, ax = plt.subplots()
orders["OrderStatus"].value_counts().plot(kind="bar", color="#e53e3e", ax=ax)
ax.set_title("Orders by Status")
ax.tick_params(axis="x", rotation=0)
plt.tight_layout()
plt.savefig(CHARTS / "05_orders_by_status.png", dpi=140)
plt.close()

print(f"Charts saved to {CHARTS}")

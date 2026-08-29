# E-commerce SQL Analysis

## What I was trying to find out
What does the customer/order/product data actually say about revenue, top products, and who the loyal customers are — and can I trust the data enough to say any of it with confidence.

## The setup
Four related CSVs loaded into MySQL: customers (1,000), products (30), orders (5,000), and order line items (12,548, before I found a problem with them — more below). Standard e-commerce shape: a customer places orders, each order has line items, each line item points to a product.

## Two things went wrong, and I think that's the actually interesting part

**The first load looked successful and wasn't.** `LOAD DATA` for the customers table came back with `Query OK, 0 rows affected` — technically not an error, easy to miss if you're not watching for it. Turned out the CSV used plain `\n` line endings, not the `\r\n` I'd assumed, so MySQL read the whole file as a single line and skipped it. Once I checked the raw bytes instead of trusting how the file *looked* in the terminal, the fix was a one-word change to the load statement.

**Then a bigger one: 40% of the order line items pointed to products that don't exist.** I'd put a foreign key on the order_items table, and when I loaded the file, only 7,462 of 12,548 rows made it in — the rest referenced product IDs (31–50) that simply aren't in the 30-row product table. Instead of quietly accepting the 7,462 that worked, I loaded the full file into a second table with no constraint, isolated the 5,086 problem rows, and kept them as evidence rather than deleting them. That way "40% of order data references a product catalog that's missing 20 products" is a number I can actually point to, not something I noticed and let disappear.

## What the clean data says
Total revenue across the 7,462 valid line items: **R195,059,063.31**.

The "top product" answer depends on how you ask it, which is itself worth knowing: by revenue, a USB-C Hub comes out on top — but only because it's priced at R13,528, more than the Smartphone and 4x the Laptop, which isn't realistic pricing. By units sold, a Stapler wins, and it doesn't even crack the top 10 by revenue. I reported both rather than picking whichever one sounded better.

Regional revenue was fairly even (R22M–R27M per region), and the eight regional totals summed exactly to the R195M grand total — a good sign nothing was double-counted in the joins. No Northern Cape customers exist in this dataset at all, which is just a fact about the data, not a bug.

Top spenders and repeat buyers were largely the same people — Mpho Mokoena, Nomsa Pillay, Sipho Ndlovu, and a few others showed up on both lists, which tells a coherent story: the top revenue customers are loyal repeat buyers, not one-off big spenders.

## What I'd do next
Treat "units sold" as the more trustworthy product ranking until the pricing data gets fixed. And flag the product catalog gap to whoever owns that export — a 40% mismatch rate isn't a rounding error, it's a real pipeline issue.

## Files
- `queries.sql` — every query from this project, in order, commented
- Full write-up of the diagnosis process is in the commit history / above

## Tools
MySQL — multi-table joins, GROUP BY with COUNT(DISTINCT), HAVING vs WHERE, RANK() window function, foreign keys used as a data validation check rather than just schema decoration

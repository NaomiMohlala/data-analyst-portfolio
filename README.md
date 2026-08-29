# Hi, I'm Naomi 👋

This is my data analyst portfolio — four projects, two tools (Excel and SQL), one habit that runs through all of them: I don't just report the numbers, I check them.

Every dashboard here is built on live formulas, not pasted values. Every SQL project is fully re-runnable. And in three of the four projects, I found something wrong with the data along the way — a silent load failure, a missing product catalog, an unrealistic price — and I wrote up what I found instead of quietly fixing it and moving on. I think that's the part that actually matters when you're deciding who to hire.

## The projects

**[Retail Sales Performance](./01-Retail-Sales-Performance)** — Furniture turned out to be the real revenue driver, not Electronics like I expected. The more interesting find: Gauteng, despite being the biggest region, had the lowest profit of the four. Worth someone actually looking into.

**[Customer Churn & Retention](./02-Customer-Churn-Retention)** — Monthly contract customers churn at almost double the rate of annual ones. That's the whole story in one number, and it means retention spend has an obvious place to go first.

**[HR Workforce Analysis](./03-HR-Workforce-Analysis)** — Customer Service has both the highest turnover *and* high absenteeism, which is a worse combination than either problem alone. Sales, meanwhile, has terrible absenteeism but average turnover — a different problem needing a different fix.

**[E-commerce SQL Analysis](./04-Ecommerce-SQL-Analysis)** — This one's MySQL, not Excel. I loaded four related tables and hit a wall almost immediately: a "successful" load that quietly inserted zero rows. Traced it to a line-ending mismatch. Then found that 40% of order line items pointed to products that didn't exist in the product table. Both are documented in the README with how I diagnosed them, not just the fix.

## How I work

I build the analysis layer on formulas that recalculate, not numbers I typed in once. When something in the data looks off, I check it before I trust it. And I try to end every project with an actual recommendation, not just a chart.

## Tools
Excel (SUMIF, COUNTIFS, AVERAGEIFS, PivotTables, slicers) · MySQL (joins, window functions, HAVING, foreign keys)

## Get in touch
[GitHub](https://github.com/NaomiMohlala)

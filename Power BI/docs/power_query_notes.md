# Power Query build notes

## Orders
1. Convert all order timestamp columns to Date/Time.
2. Duplicate `order_purchase_timestamp`, convert duplicate to Date, rename to `purchase_date`.
3. Merge Customers on `customer_id`; expand `customer_unique_id`.
4. Add `delivery_days`:
   `if [order_delivered_customer_date] = null then null else Duration.Days([order_delivered_customer_date] - [order_purchase_timestamp])`
5. Add `late_delivery_flag`:
   `if [order_delivered_customer_date] = null or [order_estimated_delivery_date] = null then null else [order_delivered_customer_date] > [order_estimated_delivery_date]`

## Customer cohorts
1. Reference Orders after `customer_unique_id` is present.
2. Group by `customer_unique_id`.
3. Aggregate minimum `purchase_date` -> `first_purchase_date`.
4. Merge this helper query back into Orders.
5. Add:
   - `cohort_month = Date.StartOfMonth([first_purchase_date])`
   - `order_month = Date.StartOfMonth([purchase_date])`
   - `cohort_index = (Date.Year([order_month])-Date.Year([cohort_month]))*12 + Date.Month([order_month])-Date.Month([cohort_month])`

## Products
- Rename `product_name_lenght` -> `product_name_length`
- Rename `product_description_lenght` -> `product_description_length`
- Merge category translation on `product_category_name`
- Expand `product_category_name_english`
- Replace null English category with `Unknown`
- Do not invent missing product dimensions; preserve nulls.

## Order Items
- `price`, `freight_value` -> Decimal Number
- `order_item_id` -> Whole Number
- `shipping_limit_date` -> Date/Time

## Payments
- `payment_value` -> Decimal Number
- `payment_installments`, `payment_sequential` -> Whole Number

## Reviews
- `review_score` -> Whole Number
- creation / answer fields -> Date/Time
- optional: `has_comment = [review_comment_message] <> null`

## Geography
Use `olist_geolocation_zip_summary.csv` instead of the raw 1M-row geolocation table.
Merge to Customers using `customer_zip_code_prefix`.
Merge to Sellers using `seller_zip_code_prefix`.

## Modelling warning
Do not merge Payments or Reviews into Order Items.
Multiple rows per order would multiply GMV/freight if you later aggregate.

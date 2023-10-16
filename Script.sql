/*******************************************************
 * 작년 대비 동원 매출 비교, 작년 동월 대비 차이/비율/매출 성장 비율 추출
 step 1: 상품 카테고리 별 원ㄹ별 매출액 추출
 step 2: step 1의 집합에서 12개월 이=이전 매출 데이터를 가져와서 현재 월과 매출 비교.
********************************************************/
with temp_01 as (
	select date_trunc('month', order_date)::date	as month_day
		 , sum(amount) 								as sum_amount
	  from nw.orders		a
	  join nw.order_items	b
	    on a.order_id		= b.order_id
	 group by date_trunc('month', order_date)::date 
)
, temp_02 as (
	select month_day
		 , sum_amount		as curr_amount
		 , lag(month_day, 12)	over (order by month_day)	as prev_month_1year
		 , lag(sum_amount, 12)	over (order by month_day)	as prev_amount_1year
	  from temp_01
)
select *
	 , curr_amount - prev_amount_1year			as diff_amount
	 , 100.0 * curr_amount / prev_amount_1year	as prev_pct
	 , 100.0 * (curr_amount - prev_amount_1year) / prev_amount_1year	as prev_growth_pct
 from temp_02
 where prev_amount_1year is not null;
 
/*******************************************************
 * 카테고리 별 기준 월 대비 매출 비율 추이(aka 매출 팬 차트)
 step 1: 상품 카테고리 별 월별 매출액 추출
 step 2: step 1의 집합에서 기준 월이 되는 첫월의 매출액을 동일 카테고리에 모두 복제한 뒤 매출 비율을 계산
********************************************************/
with temp_01 as (
	select d.category_name
		 , to_char(date_trunc('month', order_date), 'yyyymm')	as month_day
		 , sum(amount)		as sum_amount
	  from nw.orders		a
	  join nw.order_items	b
	    on a.order_id		= b.order_id
	  join nw.products 		c
	    on b.product_id		= c.product_id
	  join nw.categories	d
	    on c.category_id	= d.category_id
	 group by d.category_name, to_char(date_trunc('month', order_date), 'yyyymm')
)
, temp_02 as (
	select *
		 , first_value(sum_amount) over (partition by category_name order by month_day)	as base_month
		 , round(100.0 *  sum_amount / first_value(sum_amount) over (partition by category_name order by month_day), 2) as base_ratio
	  from temp_01
)
select * from temp_02;

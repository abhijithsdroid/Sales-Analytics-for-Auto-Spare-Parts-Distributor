select * from sales_order_lines sol

select * from part_vehicle_compatibility pvc

select * from vehicle_model_years vmy

select * from vehicle_models vm

select * from vehicle_makes vm

select
	vmk.make_name,
	vm.model_name,
	sum(sol.line_total) as revenue
from
	sales_order_lines sol
join sales_orders so on
	so. order_id = sol.order_id
	and so.order_status = 'Delivered'
join part_vehicle_compatibility pvc on
	pvc.part_id = sol.part_id
join vehicle_model_years vmy on
	vmy.model_year_id = pvc.model_year_id
join vehicle_models vm on
	vm.model_id = vmy.model_id
join vehicle_makes vmk on
	vmk.make_id = vm.make_id
group by
	vmk. make_name ,
	vm.model_name
order by
	revenue desc
limit 25
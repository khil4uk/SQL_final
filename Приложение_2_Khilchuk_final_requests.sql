1) � ����� ������� ������ ������ ���������?

select city, count(*) -- ���������� ���������� ��������� � �������� �������
from airports
group by city -- ���������� ����������� �� �������� ������
having count(*) > 1 -- ������ ������� ������ ��� ������, ���������� ������� ���� ������ 1

2) � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

-- ��� ������� ������ ������ ������������� ������������ � ���������� ������� ��������� union
select departure_airport_name as "airport" -- ���������� ��� ��������� �� ������� � �������������
from flights_v -- ���������� ������������ �� ��������� �������������
where aircraft_code = (select aircraft_code --������� ������� � ���������� �� ��������� ���� �������� � ������������ ���������� ��������
						from aircrafts a 
						order by "range" desc -- ������������� �� ��������� �������� � ������� ��������
						limit 1) -- ��� ����� ������ �� �������������� ������ �������
union -- ������������ ������ �� ������� � ����������� �������� ������
select arrival_airport_name -- ���������� ��� ��������� �� ������� � ����������
from flights_v -- ���������� ������������ �� ��������� �������������
where aircraft_code = (select aircraft_code --������� ������� � ���������� �� ��������� ���� �������� � ������������ ���������� ��������
						from aircrafts a 
						order by "range" desc -- ������������� �� ��������� �������� � ������� ��������
						limit 1) -- ��� ����� ������ �� �������������� ������ �������

3) ������� 10 ������ � ������������ �������� �������� ������

select flight_id, flight_no, actual_departure - scheduled_departure as "delay time" -- ���������� ����� � id �����, � ����� ����� ��������
from flights f 
where actual_departure is not null -- ������� �� ������� �������� null, �� ���� ��������� ������ ����������� �����
order by actual_departure - scheduled_departure desc -- ��������� �� ������� �������� �� �������� � ��������
limit 10 -- �������������� ������� �������

4) ���� �� �����, �� ������� �� ���� �������� ���������� ������?

select t.book_ref -- ���������� ������ ������������ �� ������� tickets, ������� ������ ������ �������� �� ������ boarding_no 
from tickets t
left join boarding_passes bp on t.ticket_no = bp.ticket_no -- ������������ ������� � ����������� �������� ����� left join ��� ����������� ��������� ������ �� ������� tickets c �������� ���������� �� ������� boarding_passes 
where boarding_no is null -- ������ ������� �� ����� ������� �������� �� ������ boarding_passes 

5) ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.
 
-- ��� ������� ���������� cte-�������
with cte_seats_all as(
				select aircraft_code,count(seat_no) as seats_all -- ������ �� ����� ���������� ���� � ��������
				from seats 
				group by aircraft_code), -- ���������� ����������� �� ������ ��������
cte_seats_with_people as ( 
				select flight_id, count(seat_no) as seats_people -- ������ �� ���������� ������� ����������� ���� � ��������
				from boarding_passes
				group by flight_id) -- ���������� ����������� �� �����
select f.flight_id, f.departure_airport, f.actual_departure, ca.seats_all as "���������� ����", cp.seats_people as "���� ������" , ca.seats_all - cp.seats_people as "��������� �����",
	round((ca.seats_all - cp.seats_people)/ca.seats_all::numeric, 2)*100 as "% ��������� ����", -- ��� ������ �������������� �������� � �������� ���������� ������� ������� ��������� ���� � �������� ��� �����
	sum(cp.seats_people) over (partition by f.departure_airport, actual_departure::date order by f.actual_departure) as "������������� ���� ����������" -- � ������� ������� ������� ������������� ���� ����������, ��������� ������ �� ��������� ����������� � ���� ������, ��������� �� ������� ������
from flights f 
join cte_seats_all ca on f.aircraft_code = ca.aircraft_code -- ������������ cte-������ � ����� ����������� ���� � �������� �� ��� ����
join cte_seats_with_people cp on f.flight_id = cp.flight_id -- ������������ cte-������ � ����������� ����, ������� �����������, �� id �����

6) ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

-- ������ ���������� ����������� ��������� ����� ��������� � ���������� ���������� ���� ���������
select f.aircraft_code, a.model, 
round(round(count(flight_id), 2)*100/(select round(count(flight_id), 2) from flights), 1) as "���������� �����������" -- �������� round �� ����� ��������� ��� ��������� ������ ����������
from flights f 
join aircrafts a on f.aircraft_code = a.aircraft_code -- �������� ������� aircrafts ��� ����������� �������� ������ �������� � �������� �������
group by f.aircraft_code, a.model -- ��������� ����������� �� ������ � ���� ��������

7) ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?

-- �������� cte �������, ������������ ������ ����������� � �������, � ����� ����������� � ������������ ��������� ������� �������� ��� ������-������ � ������-������
with cte_business as ( -- ������-�����
				select f.flight_id, f.arrival_city, tf.fare_conditions, 
				min(tf.amount) as min_business -- ��� ������ ���������� ������� ������� ����������� ��������� ������ ������-������
				from flights_v f -- ���������� ��������� �� ��������� �������������
				join ticket_flights tf on f.flight_id = tf.flight_id 
				where tf.fare_conditions = 'Business'
				group by f.flight_id, f.arrival_city, tf.fare_conditions),
	cte_economy as ( -- ������-�����
				select f.flight_id, f.arrival_city, tf.fare_conditions, 
				max(tf.amount) as max_economy -- ��� ������ ���������� ������� ������� ������������ ��������� ������ ������-������
				from flights_v f -- ���������� ��������� �� ��������� �������������
				join ticket_flights tf on f.flight_id = tf.flight_id 
				where tf.fare_conditions = 'Economy'
				group by f.flight_id, f.arrival_city, tf.fare_conditions)
select distinct cb.arrival_city -- -- � �������� ������� ���������� � ��������� cte �� ��������, ��� ��������� ����� ������������� � ������ �������� (flight_id )
from cte_business cb, cte_economy ce
where ce.flight_id = cb.flight_id and ce.max_economy > cb.min_business
-- �� ���������� � �������� ���� ������ �������� ����, ��� ����� ������� (� ������� ����� ��������� ������ - ������� �������, ��� ������-������� � ������ ��������) ���.

8) ����� ������ �������� ��� ������ ������?
-- ������� ������. �������� ������������� �� ���� ��������� ��� �������, ��������� ��������� ������������ � from ��������� ����������� ������� airports. 
create view all_flights as
	select a.city as departure_city , a2.city as arrival_city
	from airports a, airports a2 
	where a.city != a2.city -- ������ �������, ��� ������ �� ����� ���� �����������, ��������� ����� ������ �� ����������

-- ������ ������. ����� �������� ������ ���� ������� ������ � �������, ������� ���������� � ������� ������ �� ����������� ������ �����. 
create view  direct_flights as 
	select distinct flight_no, departure_city, arrival_city 
	from flights_v

select departure_city, arrival_city 
from all_flights 
except -- ����������� �� ������� �� ���� ��������� ��������� ��� ��, ��� ���������� � ������� ������.
select departure_city, arrival_city
from direct_flights
order by 1
-- �������� ������� �� ������� ����������� � ��������, ����� �������� ����������� ������ �����

9) ��������� ���������� ����� �����������, ���������� ������� �������, �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� �����.

-- ��� ������� ������ ������������� cte-���������
with cte_flights as( -- ������� cte ������ � ����������� � ������ �� �������� � ����������� ����� ������� ����������� � ��������
		select f.flight_id, f.departure_airport_name, f.arrival_airport_name,
		round((acos(sind(a1.latitude) * sind(a2.latitude) + cosd(a1.latitude) * cosd(a2.latitude) * cosd(a1.longitude - a2.longitude)) * 6371)::numeric) as distance -- ��� ������ ������� �� �������� ������� ������� ���������� ����� �������
		from flights_v f, airports a1, airports a2 
		where f.departure_airport = a1.airport_code and f.arrival_airport = a2.airport_code), -- ������� ��� ����������� ���������� ���� ������
	cte_aircrafts as ( -- ������� cte ������ � ����������� � ��������� �������� ���������
		select a3.aircraft_code, a3.range, f.flight_id
		from airports a 
		join flights f on a.airport_code = f.arrival_airport    
		join aircrafts a3 on a3.aircraft_code = f.aircraft_code)
select distinct cf.departure_airport_name, cf.arrival_airport_name, cf.distance as "���������� ��������", ca.range as "��������� ������ ��������", 
case when -- � �������� ��������� �������� �������� �� ����������� �������� �� ������� ����� ������������
		(ca.range < cf.distance) then '������� ����������'
		else '������� ��������'
		end as "����������� ��������"
from cte_flights cf
join cte_aircrafts ca on ca.flight_id = cf.flight_id -- ���������� ������� �� cte �������� �� flight_id
order by cf.departure_airport_name
-- �� ���������� ����������, ��� �� ���� ��������� �������� ������ ����������� �������
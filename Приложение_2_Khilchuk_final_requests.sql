1) В каких городах больше одного аэропорта?

select city, count(*) -- возвращаем количество элементов и названия городов
from airports
group by city -- производим группировку по названию города
having count(*) > 1 -- задаем условие поиска для группы, аэропортов доложно быть больше 1

2) В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

-- для решения данной задачи воспользуемся подзапросами и сцепляющей таблицы операцией union
select departure_airport_name as "airport" -- возвращаем код аэропорта из столбца с отправлениями
from flights_v -- используем существующее по умолчанию представление
where aircraft_code = (select aircraft_code --создаем условие в подзапросе на получение кода самолета с максимальной дальностью перелета
						from aircrafts a 
						order by "range" desc -- упорядочиваем по дальности перелета в порядке убывания
						limit 1) -- нам нужен первый из упорядоченного списка самолет
union -- присоединяем данные из столбца с аэропортами прибытия рейсов
select arrival_airport_name -- возвращаем код аэропорта из столбца с прибытиями
from flights_v -- используем существующее по умолчанию представление
where aircraft_code = (select aircraft_code --создаем условие в подзапросе на получение кода самолета с максимальной дальностью перелета
						from aircrafts a 
						order by "range" desc -- упорядочиваем по дальности перелета в порядке убывания
						limit 1) -- нам нужен первый из упорядоченного списка самолет

3) Вывести 10 рейсов с максимальным временем задержки вылета

select flight_id, flight_no, actual_departure - scheduled_departure as "delay time" -- возвращаем номер и id рейса, а также время задержки
from flights f 
where actual_departure is not null -- убираем из запроса значения null, то есть оставляем только выполненные рейсы
order by actual_departure - scheduled_departure desc -- сортируем по времени задержки от большего к меньшему
limit 10 -- ограничиваемся десятью рейсами

4) Были ли брони, по которым не были получены посадочные талоны?

select t.book_ref -- возвращаем номера бронирования из таблицы tickets, которые выдали пустые значения по данным boarding_no 
from tickets t
left join boarding_passes bp on t.ticket_no = bp.ticket_no -- присоединяем таблицу с посадочными талонами через left join для возможности вычленить билеты из таблицы tickets c нулевыми значениями из таблицы boarding_passes 
where boarding_no is null -- задаем условие на поиск нулевых значений по данным boarding_passes 

5) Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.
 
-- для решения используем cte-запросы
with cte_seats_all as(
				select aircraft_code,count(seat_no) as seats_all -- запрос на общее количество мест в самолете
				from seats 
				group by aircraft_code), -- производим группировку по модели самолета
cte_seats_with_people as ( 
				select flight_id, count(seat_no) as seats_people -- запрос на количество занятых пассажирами мест в самолете
				from boarding_passes
				group by flight_id) -- производим группировку по рейсу
select f.flight_id, f.departure_airport, f.actual_departure, ca.seats_all as "Количество мест", cp.seats_people as "Мест занято" , ca.seats_all - cp.seats_people as "Свободные места",
	round((ca.seats_all - cp.seats_people)/ca.seats_all::numeric, 2)*100 as "% свободных мест", -- при помощи математических операций и операции округления находим процент свободных мест в самолете для рейса
	sum(cp.seats_people) over (partition by f.departure_airport, actual_departure::date order by f.actual_departure) as "Накопительный итог пассажиров" -- в оконной функции находим накопительный итог пассажиров, группируя данные по аэропорту отправления и дате вылета, сортируем по времени вылета
from flights f 
join cte_seats_all ca on f.aircraft_code = ca.aircraft_code -- присоединяем cte-запрос с общим количеством мест в самолете по его коду
join cte_seats_with_people cp on f.flight_id = cp.flight_id -- присоединяем cte-запрос с количеством мест, занятым пассажирами, по id рейса

6) Найдите процентное соотношение перелетов по типам самолетов от общего количества.

-- нахожу процентное соотношение перелетов через подзапрос к суммарному количеству всех перелетов
select f.aircraft_code, a.model, 
round(round(count(flight_id), 2)*100/(select round(count(flight_id), 2) from flights), 1) as "Процентное соотношение" -- операцию round до сотых использую для избежания ошибок округления
from flights f 
join aircrafts a on f.aircraft_code = a.aircraft_code -- добавляю таблицу aircrafts для отображения названия модели самолета в итоговом запросе
group by f.aircraft_code, a.model -- произвожу группировку по модели и коду самолета

7) Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

-- создадим cte запросы, определяющие города отправления и прилета, а также минимальную и максимальную стоимость билетов отдельно для бизнес-класса и эконом-класса
with cte_business as ( -- бизнес-класс
				select f.flight_id, f.arrival_city, tf.fare_conditions, 
				min(tf.amount) as min_business -- при помощи агрегатной функции находим минимальную стоимость билета бизнес-класса
				from flights_v f -- используем созданное по умолчанию представление
				join ticket_flights tf on f.flight_id = tf.flight_id 
				where tf.fare_conditions = 'Business'
				group by f.flight_id, f.arrival_city, tf.fare_conditions),
	cte_economy as ( -- эконом-класс
				select f.flight_id, f.arrival_city, tf.fare_conditions, 
				max(tf.amount) as max_economy -- при помощи агрегатной функции находим максимальную стоимость билета эконом-класса
				from flights_v f -- используем созданное по умолчанию представление
				join ticket_flights tf on f.flight_id = tf.flight_id 
				where tf.fare_conditions = 'Economy'
				group by f.flight_id, f.arrival_city, tf.fare_conditions)
select distinct cb.arrival_city -- -- в основном запросе обращаемся к созданным cte по условиям, что сравнение будет производиться в рамках перелета (flight_id )
from cte_business cb, cte_economy ce
where ce.flight_id = cb.flight_id and ce.max_economy > cb.min_business
-- по результату в исходной базе данных получаем итог, что таких городов (в которые можно добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета) нет.

8) Между какими городами нет прямых рейсов?
-- Верхняя логика. Создадим представление из всех возможных пар городов, используя декартово произведение в from повторным соединением таблицы airports. 
create view all_flights as
	select a.city as departure_city , a2.city as arrival_city
	from airports a, airports a2 
	where a.city != a2.city -- укажем условие, что города не могут быть одинаковыми, поскольку таких рейсов не существует

-- Нижняя логика. Здесь выбираем только пары городов вылета и прилета, которые существуют в таблице рейсов по уникальному номеру рейса. 
create view  direct_flights as 
	select distinct flight_no, departure_city, arrival_city 
	from flights_v

select departure_city, arrival_city 
from all_flights 
except -- исключением мы убираем из всех возможных вариантов пар те, что существуют в таблице рейсов.
select departure_city, arrival_city
from direct_flights
order by 1
-- получаем таблицу из городов отправления и прибытия, между которыми отсутствуют прямые рейсы

9) Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы.

-- для решения задачи воспользуемся cte-запросами
with cte_flights as( -- создаем cte запрос с информацией о каждом из перелётов с расстоянием между точками отправления и прибытия
		select f.flight_id, f.departure_airport_name, f.arrival_airport_name,
		round((acos(sind(a1.latitude) * sind(a2.latitude) + cosd(a1.latitude) * cosd(a2.latitude) * cosd(a1.longitude - a2.longitude)) * 6371)::numeric) as distance -- при помощи формулы из описания задания находим расстояние между точками
		from flights_v f, airports a1, airports a2 
		where f.departure_airport = a1.airport_code and f.arrival_airport = a2.airport_code), -- условие для корректного объдинения двух таблиц
	cte_aircrafts as ( -- создаем cte запрос с информацией о дальности перелета самолетов
		select a3.aircraft_code, a3.range, f.flight_id
		from airports a 
		join flights f on a.airport_code = f.arrival_airport    
		join aircrafts a3 on a3.aircraft_code = f.aircraft_code)
select distinct cf.departure_airport_name, cf.arrival_airport_name, cf.distance as "Расстояние перелета", ca.range as "Дальность полета самолета", 
case when -- в условное выражение помещаем проверку на возможность перелета по разнице между расстояниями
		(ca.range < cf.distance) then 'Перелет невозможен'
		else 'Перелет возможен'
		end as "Возможность перелета"
from cte_flights cf
join cte_aircrafts ca on ca.flight_id = cf.flight_id -- объединяем таблицы из cte запросов по flight_id
order by cf.departure_airport_name
-- по результату получается, что по всем маршрутам самолеты смогут осуществить перелет
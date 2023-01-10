-- Количество закрывшихся компаний
SELECT Count(*)
FROM   company
WHERE  status = 'closed';

-- Количество привлечённых средств для новостных компаний США
SELECT funding_total
FROM   company
WHERE  country_code = 'USA'
       AND category_code = 'news'
ORDER  BY funding_total DESC 

-- Общая сумма сделок по покупке одних компаний другими в долларах, за наличные с 2011 по 2013 год включительно 
SELECT Sum(price_amount)
FROM   acquisition
WHERE  Extract(year FROM Cast(acquired_at AS DATE)) BETWEEN 2011 AND 2013
       AND term_code = 'cash'
       
-- Имя, фамилия и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver' 
SELECT first_name,
       last_name,
       twitter_username
FROM   people
WHERE  twitter_username LIKE 'Silver%' 

-- Информация о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K' 
SELECT *
FROM   people
WHERE  twitter_username LIKE '%money%'
       AND last_name LIKE 'K%' 

-- Общая сумма привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране 
SELECT country_code,
       Sum(funding_total)
FROM   company
GROUP  BY country_code
ORDER  BY Sum(funding_total) DESC 

-- Дата проведения раунда, минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату 
SELECT funded_at,
       Min(raised_amount),
       Max(raised_amount)
FROM   funding_round
GROUP  BY funded_at
HAVING Min(raised_amount) <> 0
       AND Min(raised_amount) <> Max(raised_amount) 

-- Определение категорий для фондов 
SELECT *,
       CASE
         WHEN invested_companies >= 100 THEN 'high_activity'
         WHEN invested_companies >= 20 THEN 'middle_activity'
         WHEN invested_companies < 20 THEN 'low_activity'
       END
FROM   fund        

-- Среднее количество инвестиционных раундов, в которых фонд принимал участие 
SELECT CASE
         WHEN invested_companies >= 100 THEN 'high_activity'
         WHEN invested_companies >= 20 THEN 'middle_activity'
         ELSE 'low_activity'
       END                           AS activity,
       Round(Avg(investment_rounds)) AS s
FROM   fund
GROUP  BY activity
ORDER  BY s 

-- Страны-инвесторы, которые чаще всего инвестируют в стартапы 
SELECT country_code,
       Min(invested_companies),
       Max(invested_companies),
       Avg(invested_companies)
FROM   fund
WHERE  Extract(year FROM Cast(founded_at AS date)) BETWEEN 2010 AND 2012
GROUP  BY country_code
HAVING Min(invested_companies) <> 0
ORDER  BY Avg(invested_companies) DESC,
          country_code
LIMIT  10

-- Имя, фамилия и учебые заведения всех сотрудников стартапов 
SELECT first_name,
       last_name,
       instituition
FROM   people
       LEFT JOIN education
              ON education.person_id = people.id 
              
-- Количество учебных заведений, которые окончили сотрудники компаний 
SELECT company.name,
       Count(DISTINCT( instituition ))
FROM   company
       LEFT JOIN people
              ON people.company_id = company.id
       LEFT JOIN education
              ON education.person_id = people.id
WHERE  instituition IS NOT NULL
GROUP  BY company.name
ORDER  BY Count(DISTINCT( instituition )) DESC
LIMIT  5 

-- Названия закрытых компаний, для которых первый раунд финансирования оказался последним 
SELECT DISTINCT NAME
FROM   company
       LEFT JOIN funding_round AS f
              ON f.company_id = company.id
WHERE  status = 'closed'
       AND is_first_round = 1
       AND is_last_round = 1 

-- Номера сотрудников, которые работают в компаниях 
SELECT id
FROM   people
WHERE  company_id IN (SELECT DISTINCT company_id
                      FROM   company
                             LEFT JOIN funding_round AS f
                                    ON f.company_id = company.id
                      WHERE  status = 'closed'
                             AND is_first_round = 1
                             AND is_last_round = 1)       

-- Номера сотрудников и учебные заведения, которое окончил сотрудник 
SELECT people.id,
       instituition
FROM   people
       JOIN education AS e
         ON e.person_id = people.id
WHERE  company_id IN (SELECT DISTINCT company_id
                      FROM   company
                             LEFT JOIN funding_round AS f
                                    ON f.company_id = company.id
                      WHERE  status = 'closed'
                             AND is_first_round = 1
                             AND is_last_round = 1)
GROUP  BY people.id,
          instituition  

-- Количество учебных заведений для каждого сотрудника 
SELECT people.id,
       count(instituition)
FROM   people
       JOIN education AS e
         ON e.person_id = people.id
WHERE  company_id IN (SELECT DISTINCT company_id
                      FROM   company
                             LEFT JOIN funding_round AS f
                                    ON f.company_id = company.id
                      WHERE  status = 'closed'
                             AND is_first_round = 1
                             AND is_last_round = 1)
GROUP  BY people.id

-- Среднее число учебных заведений, которые окончили сотрудники разных компаний 
SELECT Avg(q.t)
FROM   (SELECT Count(instituition) AS t
        FROM   people
               JOIN education AS e
                 ON e.person_id = people.id
        WHERE  company_id IN (SELECT DISTINCT company_id
                              FROM   company
                                     LEFT JOIN funding_round AS f
                                            ON f.company_id = company.id
                              WHERE  status = 'closed'
                                     AND is_first_round = 1
                                     AND is_last_round = 1)
        GROUP  BY people.id) AS q                              

-- Среднее число учебных заведений, которые окончили сотрудники Facebook 
SELECT Avg(q.t)
FROM   (SELECT Count(instituition) AS t
        FROM   education AS e
               JOIN people AS p
                 ON p.id = e.person_id
               JOIN company AS c
                 ON c.id = p.company_id
        WHERE  NAME = 'Facebook'
        GROUP  BY p.id) AS q         

-- Название фонда, название компании, сумма инвестиций, которую привлекла компания в раунде,
-- в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год 
SELECT fund.NAME     AS name_of_fund,
       c.NAME        AS name_of_company,
       raised_amount AS amount
FROM   fund
       JOIN investment AS i
         ON i.fund_id = fund.id
       JOIN funding_round AS fr
         ON fr.id = i.funding_round_id
       JOIN company AS c
         ON c.id = fr.company_id
WHERE  Extract(year FROM Cast(funded_at AS DATE)) BETWEEN 2012 AND 2013
       AND c.milestones > 6         

-- Название компании-покупателя, сумма сделки, название компании, которую купили,
-- сумма инвестиций, вложенных в купленную компанию, доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций 
SELECT company.name AS acquiring,
       b.price_amount,
       b.acquired,
       b.funding_total,
       Round(b.price_amount / b.funding_total)
FROM   (SELECT c.name AS acquired,
               a.price_amount,
               a.acquiring_company_id,
               c.funding_total
        FROM   company AS c
               RIGHT JOIN (SELECT acquiring_company_id,
                                  acquired_company_id,
                                  price_amount
                           FROM   acquisition
                           WHERE  price_amount > 0) AS a
                       ON c.id = a.acquired_company_id) AS b
       LEFT JOIN company
              ON company.id = b.acquiring_company_id
WHERE  b.funding_total > 0
ORDER  BY b.price_amount DESC,
          b.acquired
LIMIT  10        

-- Названия компаний из категории social, получившие финансирование с 2010 по 2013 год 
SELECT company.NAME,
       Extract(month FROM Cast(funded_at AS DATE)) AS month
FROM   company
       LEFT JOIN funding_round AS fr
              ON fr.company_id = company.id
WHERE  Extract(year FROM Cast(funded_at AS DATE)) BETWEEN 2010 AND 2013
       AND company.category_code = 'social'
       AND raised_amount > 0 
       
-- Номер месяца, в котором проходили раунды, количество уникальных названий фондов из США, которые инвестировали в этом месяце,
-- количество компаний, купленных за этот месяц, общая сумма сделок по покупкам в этом месяце
WITH q
     AS (SELECT Extract(month FROM Cast(funded_at AS DATE)) AS m,
                Count(DISTINCT fund.NAME)                   AS count_fund
         FROM   funding_round AS fr
                JOIN investment AS i
                  ON i.funding_round_id = fr.id
                JOIN fund
                  ON fund.id = i.fund_id
         WHERE  fund.country_code = 'USA'
                AND Extract(year FROM Cast(funded_at AS DATE)) BETWEEN 2010 AND
                    2013
         GROUP  BY Extract(month FROM Cast(funded_at AS DATE))),
     b
     AS (SELECT Extract(month FROM Cast(acquired_at AS DATE)) AS m,
                Count(a.acquired_company_id)                  AS count_company,
                Sum(price_amount)                             AS sum_total
         FROM   acquisition AS a
         WHERE  Extract(year FROM Cast(acquired_at AS DATE)) BETWEEN 2010 AND
                2013
         GROUP  BY Extract(month FROM Cast(acquired_at AS DATE)))
SELECT b.m,
       count_fund,
       count_company,
       sum_total
FROM   q
       LEFT JOIN b
              ON q.m = b.m 

-- Средняя сумма инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах
WITH a
     AS (SELECT country_code,
                Avg(funding_total) AS sum_total_2011
         FROM   company
         GROUP  BY country_code,
                   Extract(year FROM Cast(founded_at AS DATE))
         HAVING Extract(year FROM Cast(founded_at AS DATE)) = 2011),
     b
     AS (SELECT country_code,
                Avg(funding_total) AS sum_total_2012
         FROM   company
         GROUP  BY country_code,
                   Extract(year FROM Cast(founded_at AS DATE))
         HAVING Extract(year FROM Cast(founded_at AS DATE)) = 2012),
     c
     AS (SELECT country_code,
                Avg(funding_total) AS sum_total_2013
         FROM   company
         GROUP  BY country_code,
                   Extract(year FROM Cast(founded_at AS DATE))
         HAVING Extract(year FROM Cast(founded_at AS DATE)) = 2013)
SELECT a.country_code,
       a.sum_total_2011,
       b.sum_total_2012,
       c.sum_total_2013
FROM   a
       JOIN b
              ON a.country_code = b.country_code
       JOIN c
              ON c.country_code = b.country_code
WHERE  sum_total_2011 IS NOT NULL
       AND sum_total_2011 IS NOT NULL
       AND sum_total_2011 IS NOT NULL
ORDER  BY a.sum_total_2011 DESC      

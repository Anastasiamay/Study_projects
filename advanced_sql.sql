-- Количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки»
SELECT Count(type)
FROM   stackoverflow.post_types AS pt
       JOIN stackoverflow.posts AS p
         ON p.post_type_id = pt.id
WHERE  type = 'Question'
       AND ( score > 300
              OR favorites_count >= 100 ) 
              

-- Среднее количество вопросв в день с 1 по 18 ноября 2008 включительно  
SELECT Round(Avg(cnt))
FROM   (SELECT Cast(creation_date AS DATE) AS dt,
               Count(post_type_id)         AS cnt
        FROM   stackoverflow.post_types AS pt
               JOIN stackoverflow.posts AS p
                 ON p.post_type_id = pt.id
        WHERE  type = 'Question'
               AND Cast(creation_date AS DATE) BETWEEN
                   '2008-11-01' AND '2008-11-18'
        GROUP  BY dt) t    


-- Количество пользователей получивших значки сразу в день регистрации      
SELECT Count(DISTINCT u.id)
FROM   stackoverflow.badges AS b
       JOIN stackoverflow.users AS u
         ON u.id = b.user_id
WHERE  Cast(u.creation_date AS DATE) = Cast(b.creation_date AS DATE) 


-- Количество уникальных постов пользователя с именем Joel Coehoorn, получивших хотя бы один голос?
SELECT Count(DISTINCT post_id)
FROM   stackoverflow.votes AS v
       JOIN stackoverflow.posts AS p
         ON p.id = v.post_id
       JOIN stackoverflow.users AS u
         ON u.id = p.user_id
WHERE  display_name = 'Joel Coehoorn' 


-- Ранжирование полей таблицы vote_types
SELECT *,
       Row_number()
       OVER(ORDER BY id DESC) AS rank
FROM   stackoverflow.vote_types
ORDER  BY id 


-- Пользователи, которые поставили больше всего голосов типа Close
SELECT v.user_id,
       Count(v.post_id) AS cnt
FROM   stackoverflow.posts p
       JOIN stackoverflow.votes v
         ON v.post_id = p.id
       JOIN stackoverflow.vote_types vt
         ON vt.id = v.vote_type_id
WHERE  vt.name = 'Close'
GROUP  BY v.user_id
ORDER  BY cnt DESC,
          user_id DESC
LIMIT  10 


-- Пользователи и количество значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно
SELECT   user_id,
         cnt,
         Dense_rank () OVER (ORDER BY cnt DESC)
FROM     (
                  SELECT   user_id,
                           Count(id) AS cnt
                  FROM     stackoverflow.badges
                  WHERE    Cast(creation_date AS DATE) BETWEEN '2008-11-15' AND '2008-12-15'
                  GROUP BY user_id
                  ORDER BY cnt DESC,
                           user_id) t 
limit 10


-- Среднее количество очков для поста каждого пользователя
SELECT title,
       user_id,
       score,
       Round(sc)
FROM   (SELECT title,
               user_id,
               score,
               Avg(score)
                 OVER(partition BY user_id) AS sc
        FROM   stackoverflow.posts
        WHERE  title IS NOT NULL
               AND score != 0) t 
               
               
-- Заголовки постов, которые были написаны пользователями, получившими более 1000 значков
SELECT title
FROM   (SELECT title,
               Count(b.id)
        FROM   stackoverflow.posts p
               JOIN stackoverflow.users u
                 ON p.user_id = u.id
               JOIN stackoverflow.badges b
                 ON b.user_id = u.id
        GROUP  BY title
        HAVING Count(b.id) > 1000
               AND title IS NOT NULL) t 
               
               
-- 3 группы пользователей из США в зависимости от количества просмотров их профилей
SELECT id,
       views,
       CASE
         WHEN views >= 350 THEN 1
         WHEN ( views >= 100 AND views < 350 ) THEN 2
         WHEN views < 100 THEN 3
       END
FROM   stackoverflow.users
WHERE  views != 0
       AND location LIKE '%United States%' 
       
       
-- Лидеры каждой группы пользователей из США, которые набрали максимальное число просмотров в своей группе 
WITH a
     AS (SELECT id,
                views,
                ( CASE
                    WHEN views >= 350 THEN 1
                    WHEN ( views >= 100 AND views < 350 ) THEN 2
                    WHEN views < 100 THEN 3
                  END ) AS category
         FROM   stackoverflow.users
         WHERE  views != 0
                AND location LIKE '%United States%')
SELECT id,
       views,
       category
FROM   (SELECT id,
               views,
               category,
               Max (views)
                 OVER(partition BY category) AS mx
        FROM a) AS t
WHERE  views = mx
ORDER  BY views DESC, id 


-- Ежедневный прирост новых пользователей в ноябре 2008 года
SELECT dt,
       cnt,
       SUM(cnt)
         over (
           ORDER BY dt)
FROM   (SELECT Extract(day FROM creation_date :: DATE) AS dt,
               Count(id)                               AS cnt
        FROM   stackoverflow.users
        WHERE  creation_date :: DATE BETWEEN '2008-11-01' AND '2008-11-30'
        GROUP  BY Extract(day FROM creation_date :: DATE)) t 
        
        
-- Интервал между регистрацией и временем создания первого поста        
SELECT u.id,
       Min(p.creation_date) - u.creation_date AS time_diff
FROM   stackoverflow.users u
       JOIN stackoverflow.posts p
         ON p.user_id = u.id
GROUP  BY u.id,
          u.creation_date
          
          
-- Общую сумма просмотров постов за каждый месяц 2008 года        
SELECT Cast(Date_trunc('month', creation_date) AS DATE),
       Sum(views_count)
FROM   stackoverflow.posts
GROUP  BY 1
ORDER  BY 2 DESC 


-- Самые активные пользователи, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов
SELECT   u.display_name,
         Count(DISTINCT p.user_id)
FROM     stackoverflow.users u
JOIN     stackoverflow.posts p
ON       p.user_id=u.id
JOIN     stackoverflow.post_types pt
ON       pt.id = p.post_type_id
WHERE    pt.type = 'Answer'
AND      Cast(p.creation_date AS DATE) BETWEEN Cast(u.creation_date AS DATE) AND
         (Cast(u.creation_date AS DATE) + interval '1 month')
GROUP BY 1
HAVING count(post_type_id) > 100
ORDER BY 1


-- Количество постов за 2008 год по месяцам
WITH a AS
(
       SELECT u.id
       FROM   stackoverflow.users u
       JOIN   stackoverflow.posts p
       ON     u.id =p.user_id
       WHERE  (Cast(Date_trunc('month', p.creation_date) AS DATE) 
               BETWEEN '2008-12-01' AND '2008-12-31')
       AND    (Cast(Date_trunc('month', u.creation_date) AS DATE) 
               BETWEEN '2008-09-01' AND '2008-09-30')
       GROUP BY u.id)
SELECT   Cast(Date_trunc('month', p.creation_date) AS DATE),
         Count(p.id)
FROM     stackoverflow.posts p
WHERE    p.user_id IN
         (SELECT a.id FROM a)
AND      (Cast(Date_trunc('year', p.creation_date) AS DATE) = '2008-01-01') 
GROUP BY 1 
ORDER BY 1 DESC


-- Сумма просмотров постов авторов с накоплением
SELECT user_id,
       creation_date,
       views_count,
       Sum(views_count)
       OVER(partition BY user_id
            ORDER BY creation_date)
FROM   stackoverflow.posts
ORDER  BY user_id,
          creation_date 

          
-- Среднее количество дней взаимодействия пользователей с платформой в период с 1 по 7 декабря 2008 года включительно     
SELECT Round(Avg(cnt))
FROM   (SELECT user_id,
               Count(DISTINCT Cast(creation_date AS DATE)) AS cnt
        FROM   stackoverflow.posts
        WHERE  Cast(creation_date AS DATE) BETWEEN '2008-12-01' AND '2008-12-07'
        GROUP  BY user_id) t 
        
        
-- Процентное изменение количества постов ежемесячно с 1 сентября по 31 декабря 2008 года
WITH a
     AS (SELECT Extract('month' FROM creation_date) AS m,
                Count(DISTINCT id)                  AS cnt
         FROM   stackoverflow.posts
         WHERE  Cast(creation_date AS DATE) BETWEEN
                '2008-09-01' AND '2008-12-31'
         GROUP  BY 1)
SELECT m,
       cnt,
       Round(( cnt - Lag(cnt) OVER (ORDER BY m) ) * 100.0 / Lag(cnt) OVER (ORDER BY m), 2) AS col
FROM   a       


-- Данные активности пользователя, который опубликовал больше всего постов за всё время
WITH a AS
(
         SELECT   user_id,
                  Count(id) AS cnt
         FROM     stackoverflow.posts
         GROUP BY user_id
         ORDER BY 2 DESC 
         LIMIT 1), 
     b AS
(
         SELECT   user_id,
                  Extract(week FROM creation_date) AS week,
                  creation_date
         FROM     stackoverflow.posts
         WHERE    Cast(Date_trunc('month', creation_date) AS DATE) = '2008-10-01'
         GROUP BY 1, 2, 3)
SELECT DISTINCT week, Last_value(creation_date) OVER(partition BY week)
FROM a JOIN b ON a.user_id =b.user_id























               






















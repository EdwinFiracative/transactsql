
--procedure to impor a csv file into a temporal table
USE
EMP001_INV

if object_id('tempdb.dbo.#tab_upd_pro_dates') is not null
begin
	print 'existe'
	drop table #tab_upd_pro_dates
end
else
	print 'no existe'

CREATE TABLE #tab_upd_pro_dates
	(
	fie_upd_id int,
	fie_upd_op int,
	fie_upd_date date
	)

SET DATEFORMAT dmy
bulk insert #tab_upd_pro_dates
from 'C:\FechasOPs.csv'

WITH 
  (
    FIELDTERMINATOR = ',', 
	FIRSTROW = 2,
    ROWTERMINATOR = '\n'
  )

-- Select all the ops in the importation file and the new and old dates. If old dates is null the po dosn't exits 
  update
  op3
  set
  fechai2 = fie_upd_date,
  fechaf2 = fie_upd_date
  FROM 
  op3
  inner join
  #tab_upd_pro_dates
  on
  op = fie_upd_op

 
drop table #tab_upd_pro_dates
/*
SELECT * FROM OPENROWSET('MSDASQL',
'Driver={Microsoft Text Driver (*.txt; *.csv)};
DefaultDir=D:\;',
'SELECT * FROM FechasOPs.csv')
*/

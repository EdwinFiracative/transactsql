use
emp001_prod
update
[dbo].[MASTER6]
set
[VALOR] = cant * 21046
from
[dbo].[MASTER6]
where
([CODP] like '[1,3][0-9][0-9][0-9]E%' or codp like 'RC.%')
and
cod = 'SPN9003G'
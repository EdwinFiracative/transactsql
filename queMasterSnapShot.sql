use emp001_prod
go

declare @opar_bit_if_error bit = 0 
declare	@opar_nvc_error nvarchar(MAX) = '' 

declare @tabInserted as table
(
inId int
)

declare @maxid as int

DECLARE @bit_tran_count bit = 0  -- mark if one transaction has satarted
	
	
begin try

	IF @@TRANCOUNT = 0   -- check if there is transaction nesting. If there is don't start another transaction
		BEGIN
			BEGIN TRANSACTION
			SET @bit_tran_count = 1
		END

insert into [EMP001_OFER].dbo.[SnapShot]
([sshDate]
,[sshDescription]
)
output INSERTED.sshId INTO @tabInserted
values
(
getdate()
,'Actualización automática'
)

select @maxid = max(inId) from @tabInserted;

with ataMasStaRC as
(
select
ataMaster.cod,
ataMaster.modelo,
ataMaster.lmin
from
(
select
[COD],
[MODELO],
[LMIN]
from
[dbo].[MASTER]
where
cod like '[1-4][1-9][1-9][1-9]E%'
or
cod like 'RC.%'
) as ataMaster
inner join
(
select
cod
from
EMP001_INV.dbo.MAESTRO 
where
grupo = 'S'
and
(
cod like '[1-4][1-9][1-9][1-9]E%'
or
cod like 'RC.%'
)
)
as ataMaestro
on
ataMaestro.cod = ataMaster.cod
)
INSERT INTO [EMP001_OFER].[dbo].[MasSnapShot]
           ([mssMasCode]
           ,[mssMasModel]
           ,[mssMasComCode]
           ,[mssMasComVarQuantity]
           ,[mssMasComFixQuantity]
           ,[mssSnapShot])
(
select
ataMasSnapShot.[CODP],
ataMasSnapShot.modelo,
ataMasSnapShot.[COD],
ataMasSnapShot.mssComVarQuantity,
ataMasSnapShot.mssComFixQuantity,
@maxid as [mssSnapShot]
from
(
select
[CODP],
modelo,
master1.[COD],
sum([CANT]) as mssComVarQuantity,
0 as mssComFixQuantity
from
[dbo].[MASTER1]
inner join
ataMasStaRC
on
master1.CODP = ataMasStaRC.COD
and
master1.MODELO_MAS = ataMasStaRC.MODELO
where cant > 0
group by
[CODP],
modelo,
master1.[COD]

union
select
[CODP],
modelo,
master2.[COD],
sum([CANT]) as mssComVarQuantity,
sum(CANTF) as mssComFixQuantity
from
[dbo].[MASTER2]
inner join
ataMasStaRC
on
master2.CODP = ataMasStaRC.COD
and
master2.MODELO_MAS = ataMasStaRC.MODELO
where cant > 0
group by
[CODP],
modelo,
master2.[COD]
union
select
[CODP],
modelo,
master6.[COD],
sum([CANT]) as mssComVarQuantity,
0 as mssComFixQuantity
from
[dbo].[MASTER6]
inner join
ataMasStaRC
on
master6.CODP = ataMasStaRC.COD
and
master6.MODELO_MAS = ataMasStaRC.MODELO
where cant > 0
group by
[CODP],
modelo,
master6.[COD]
) as ataMasSnapShot
)
print 'end insert ' 
if @bit_tran_count = 1
		BEGIN
			COMMIT
		END
	
		
end try
begin catch
		print 'bit_tran_count in catch is ' + convert(nvarchar(10), @bit_tran_count)
		if @bit_tran_count = 1
		BEGIN
			ROLLBACK
		END
		SET CONCAT_NULL_YIELDS_NULL OFF

		select @opar_nvc_error =  'Error number: ' + convert( nvarchar(10), ERROR_NUMBER() ) + '. Severity: ' + convert(nvarchar(10), ERROR_SEVERITY())  + '. State: '+ convert(nvarchar(10),ERROR_STATE()) + '. Procedure: '  
		+  ERROR_PROCEDURE() + '. Line: ' + 
		convert(nvarchar(10),ERROR_LINE()) + '. Messsage: '  
		+ ERROR_MESSAGE()
		print @opar_nvc_error
		set @opar_bit_if_error = 1						
end catch 
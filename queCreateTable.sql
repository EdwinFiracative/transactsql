use
emp001_ofer

create table MasSnapShot

(
mssMasCode	nvarchar(23) not Null,
mssMasModel	char(1) not null,
mssMasBatch	numeric(8,4) not null,
mssMasComCode nvarchar(20) not null,
mssMasComVarQuantity numeric(16,7) not null,
mssMasComFixQuantity numeric(16,7) not null,
mssMasComStaCost numeric(16,7) not null,
mssSnapShot int not null,
mssId int IDENTITY(1,1) constraint mssPriKeyConsstrait primary key NOT NULL,
constraint mssComVarQuaPositive Check (mssMasComVarQuantity > 0),
constraint mssComFixQuaPositive Check (mssMasComFixQuantity > 0),
constraint mssComStaCostPositive Check (mssMasComStaCost > 0)
)


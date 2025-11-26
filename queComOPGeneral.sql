WITH aviLasOps -- temporary result set with the open OPs (production orders) and the closed op created in the las 90 days
As
(
SELECT
  OP.OP,
  OP.COD,
  OP.CANTP, -- quantity to produce in the op
  op.CANTE,
  op.FECHA_I,
  op.FECHA_T
FROM OP
WHERE
( 
OP.FECHA_T IS NULL  -- ops no closed
OR
(
OP.FECHA_T IS NOT NULL
AND
GETDATE() - OP.FECHA_I < 90
)
)
AND
OP.CANTP > 0
)

SELECT 
aviLasOps.op,
aviLasOps.COD AS afiCodProduct,
EMP001_INV.dbo.vi_mae_clasificado.NOM AS afiNomProduct,
EMP001_INV.dbo.vi_mae_clasificado.[ca_cla-ni2_nombre] AS afiNiv2Product,
EMP001_INV.dbo.vi_mae_clasificado.[ca_cla-ni3_nombre] AS afiNiv3Product,
EMP001_INV.dbo.vi_mae_clasificado.[ca_cla-ni4_nombre] AS afiNiv4Product,
EMP001_INV.dbo.vi_mae_clasificado.[ca_cla-ni5_nombre]AS afiNiv5Product,
EMP001_INV.dbo.vi_mae_clasificado.[CSTD] as afiCosStandard,
aviLasOps.CANTP,
aviLasOps.CANTE,
aviLasOps.FECHA_I,
aviLasOps.FECHA_T,
ataPivTable.COD,
ataPivTable.NOM,
ataPivTable.UD,
ataPivTable.CONV,
ataPivTable.uda,
ataPivTable.GRUP,
Isnull([OPQuantity],0) AS afiOPQuantity,
Isnull([OPCost],0) AS afiOPCost,
Isnull([MasterQuantity],0) AS afiMasterQuantity,
Isnull([MasterCost],0) AS afiMasterCost,
Isnull([OPQuantity],0) - Isnull([MasterQuantity],0) AS afiQuaDifference,
Isnull([OPCost],0) - Isnull([MasterCost],0) AS  afiCostDifference,
co_clasificacion.[ca_cla-ni1_nombre],
co_clasificacion.[ca_cla-ni2_nombre],
co_clasificacion.[ca_cla-ni3_nombre],
co_clasificacion.[ca_cla-ni4_nombre],
co_clasificacion.[ca_cla-ni5_nombre]

 FROM
(

-- ******* First block with the costs and quantities of the materiales charged into the OP
SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataOP1Resume.COD,
EMP001_INV.dbo.MAESTRO.NOM,
EMP001_INV.dbo.MAESTRO.UD,
EMP001_INV.dbo.MAESTRO.CONV,
EMP001_INV.dbo.MAESTRO.UDA,
EMP001_INV.dbo.MAESTRO.GRUP,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue, -- Value of the cost source, can be quantity or cost
ataCosQuantity.cquOrigin -- Origin of the cost Production order or master reference 
FROM
aviLasOps
INNER JOIN
(
SELECT
op,
cod,
CONVERT (decimal(38,4),sum(cant)) as afiTotQuantity,
CONVERT (decimal(38,4),sum(cmp)) AS afiTotCMP
from
EMP001_INV.dbo.op1
WHERE cant <> 0
GROUP BY
op,
cod
) as ataOP1Resume
on
ataOP1Resume.op = aviLasOps.op
INNER JOIN
EMP001_INV.dbo.MAESTRO
ON
EMP001_INV.dbo.MAESTRO.COD = ataOP1Resume.COD
CROSS APPLY -- inner join with a table created with the Values expression
(
VALUES ('OPQuantity', ataOP1Resume.afiTotQuantity),('OPCost', ataOP1Resume.afiTotCMP)
)AS ataCosQuantity (cquOrigin, cquValue)

-- **********  Second block with the costs of labour MO and Factory overhead CIF

UNION
SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataCosQuantity.cquCode,
ataOP2Resume.NOM,
'H' AS afiUnit,
1 AS afiConversion,
'H' AS afiSecUnit,
ataCosQuantity.cquGroup,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue,
ataCosQuantity.cquOrigin
FROM
aviLasOps
INNER JOIN
(
SELECT
op,
dpto,
EMP001_INV.dbo.DPTO.NOM,
CONVERT (decimal(38,4),SUM(CANT)) AS afiTotQuatity,
CONVERT (decimal(38,4),sum(EMP001_INV.dbo.op2.CMO)) AS afiTotCMO,
CONVERT (decimal(38,4),sum(EMP001_INV.dbo.op2.CCF)) AS afiTotCCF
FROM
EMP001_INV.dbo.op2
INNER JOIN
EMP001_INV.dbo.DPTO
ON
EMP001_INV.dbo.DPTO.COD = EMP001_INV.dbo.op2.DPTO
WHERE
cant <> 0
GROUP BY
op,
dpto,
EMP001_INV.dbo.DPTO.NOM

) AS ataOP2Resume
on
ataOP2Resume.op = aviLasOps.op
CROSS APPLY
(

VALUES 
(RTRIM(ataOP2Resume.DPTO) + ' MO', 'PR.MO.'+ RTRIM(ataOP2Resume.DPTO), 'OPQuantity',ataOP2Resume.afiTotQuatity ), 
(RTRIM(ataOP2Resume.DPTO) + ' MO', 'PR.MO.'+ RTRIM(ataOP2Resume.DPTO), 'OPCost',ataOP2Resume.afiTotCMO ),
(RTRIM(ataOP2Resume.DPTO) + ' CIF', 'PR.CIF.'+ RTRIM(ataOP2Resume.DPTO), 'OPQuantity',ataOP2Resume.afiTotQuatity ), 
(RTRIM(ataOP2Resume.DPTO) + ' CIF', 'PR.CIF.'+ RTRIM(ataOP2Resume.DPTO), 'OPCost',ataOP2Resume.afiTotCCF )

)AS ataCosQuantity (cquCode, cquGroup, cquOrigin, cquValue)

-- **********  Third block with the costs of third party services

UNION
SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataAdicResume.COD,
ataAdicResume.NOM,
CASE WHEN ataCosQuantity.cquGroup = 'SPG' THEN 'M2' ELSE CASE WHEN ataCosQuantity.cquGroup  = 'SIN' THEN 'IYN' ELSE 'SE' END end  AS afiUnit,
1 AS afiConversion,
CASE WHEN ataCosQuantity.cquGroup = 'SPG' THEN 'M2' ELSE CASE WHEN ataCosQuantity.cquGroup  = 'SIN' THEN 'IYN' ELSE 'SE' END end  AS afiSecUnit,
ataCosQuantity.cquGroup,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue,
ataCosQuantity.cquOrigin
FROM
aviLasOps
INNER JOIN
(
SELECT
op,
COD,
NOM,
sum(CANT) AS afiTotQuatity,
sum(VALOR) AS afiTotValor
FROM
EMP001_INV.dbo.ADIC AS ataEmp001InvAdic
WHERE 
cant <> 0
group BY 
op,
COD,
NOM
) AS ataAdicResume
ON
ataAdicResume.OP = aviLasOps.OP
CROSS apply
(
VALUES 
(CASE WHEN left(ltrim(ataAdicResume.COD),1) = 'P' THEN 'SPG' ELSE CASE WHEN left(ltrim(ataAdicResume.COD),1) = 'I' THEN 'SIN' ELSE 'OTR' END end , 'OPQuantity', ataAdicResume.afiTotQuatity),
(CASE WHEN left(ltrim(ataAdicResume.COD),1) = 'P' THEN 'SPG' ELSE CASE WHEN left(ltrim(ataAdicResume.COD),1) = 'I' THEN 'SIN' ELSE 'OTR' END end, 'OPCost', ataAdicResume.afiTotValor)

) AS ataCosQuantity ( cquGroup, cquOrigin, cquValue)

UNION

-- **********  Fourd block with the costs of raw material from master estándar

SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataMaster1Resume.COD,
ataMaster1Resume.NOM,
ataMaster1Resume.UD,
ataMaster1Resume.CONV,
ataMaster1Resume.UDA,
ataMaster1Resume.GRUP,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue,
ataCosQuantity.cquOrigin

FROM
aviLasOps
INNER join
(
SELECT
ataEmp001ProdMaster1.CODP,
ataEmp001ProdMaster1.COD,
ataEmp001InvMaestro.NOM,
ataEmp001InvMaestro.UD,
ataEmp001InvMaestro.CONV,
ataEmp001InvMaestro.UDA,
ataEmp001InvMaestro.GRUP,
ataEmp001ProdMaster.LMIN,
sum(ataEmp001ProdMaster1.CANT) as afiTotQuantity,
sum(ataEmp001ProdMaster1.CANT* ataEmp001InvMaestro.CSTD) AS afiTotCMP
FROM
EMP001_PROD.dbo.MASTER1 as ataEmp001ProdMaster1
inner JOIN
EMP001_INV.dbo.MAESTRO AS ataEmp001InvMaestro
ON
ataEmp001InvMaestro.cod = ataEmp001ProdMaster1.COD
INNER JOIN
EMP001_PROD.dbo.MASTER AS ataEmp001ProdMaster
ON
ataEmp001ProdMaster.COD = ataEmp001ProdMaster1.CODP
AND
ataEmp001ProdMaster.MODELO = ataEmp001ProdMaster1.MODELO_MAS
WHERE
ataEmp001ProdMaster1.MODELO_MAS = ' '
AND
ataEmp001ProdMaster1.cant > 0 
AND
ataEmp001ProdMaster.LMIN > 0
GROUP BY
ataEmp001ProdMaster1.CODP,
ataEmp001ProdMaster1.COD,
ataEmp001InvMaestro.NOM,
ataEmp001InvMaestro.UD,
ataEmp001InvMaestro.CONV,
ataEmp001InvMaestro.UDA,
ataEmp001InvMaestro.GRUP,
ataEmp001ProdMaster.LMIN
)AS ataMaster1Resume
ON
ataMaster1Resume.codp = aviLasOps.COD
CROSS APPLY
(
VALUES ('MasterQuantity', ataMaster1Resume.afiTotQuantity*aviLasOps.CANTP/ataMaster1Resume.LMIN),('MasterCost', ataMaster1Resume.afiTotCMP*aviLasOps.CANTP/ataMaster1Resume.LMIN)
)AS ataCosQuantity (cquOrigin, cquValue)

-- **********  Fiveth block with the costs of labour form master estándar

UNION
SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataCosQuantity.cquCode,
ataMaster2Resume.NOM,
'H' AS afiUnit,
1 AS afiConversion,
'H' AS afiSecUnit,
ataCosQuantity.cquGroup,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue,
ataCosQuantity.cquOrigin
FROM
aviLasOps
INNER JOIN
(
SELECT
ataEmp001ProdMaster2.CODP,
ataEmp001ProdMaster2.COD,
ataEmp001InvDpto.NOM,
ataEmp001ProdMaster.LMIN,
sum(ataEmp001ProdMaster2.CANT + ataEmp001ProdMaster2.CANTF) as afiTotQuantity,
sum((ataEmp001ProdMaster2.CANT +ataEmp001ProdMaster2.CANTF)* ataEmp001InvDpto.SMO) AS afiTotSMO,
sum((ataEmp001ProdMaster2.CANT+ ataEmp001ProdMaster2.CANTF)* ataEmp001InvDpto.SCF) AS afiTotSCF
FROM
EMP001_PROD.dbo.MASTER2 as ataEmp001ProdMaster2
inner JOIN
 EMP001_INV.dbo.DPTO AS ataEmp001InvDpto
ON
ataEmp001InvDpto.COD = ataEmp001ProdMaster2.COD
INNER JOIN
EMP001_PROD.dbo.MASTER AS ataEmp001ProdMaster
ON
ataEmp001ProdMaster.COD = ataEmp001ProdMaster2.CODP
AND
ataEmp001ProdMaster.MODELO = ataEmp001ProdMaster2.MODELO_MAS
WHERE
ataEmp001ProdMaster2.MODELO_MAS = ' '
AND
ataEmp001ProdMaster2.cant > 0 
AND
ataEmp001ProdMaster.LMIN > 0
GROUP BY
ataEmp001ProdMaster2.CODP,
ataEmp001ProdMaster2.COD,
ataEmp001InvDpto.NOM,
ataEmp001ProdMaster.LMIN
) AS ataMaster2Resume
on
ataMaster2Resume.CODP = aviLasOps.COD
CROSS APPLY
(

VALUES 
(RTRIM(ataMaster2Resume.COD) + ' MO', 'PR.MO.'+ RTRIM(ataMaster2Resume.COD), 'MasterQuantity',ataMaster2Resume.afiTotQuantity*aviLasOps.CANTP/ataMaster2Resume.LMIN), 
(RTRIM(ataMaster2Resume.COD) + ' MO', 'PR.MO.'+ RTRIM(ataMaster2Resume.COD), 'MasterCost',ataMaster2Resume.afiTotSMO*aviLasOps.CANTP/ataMaster2Resume.LMIN ),
(RTRIM(ataMaster2Resume.COD) + ' CIF', 'PR.CIF.'+ RTRIM(ataMaster2Resume.COD), 'MasterQuantity',ataMaster2Resume.afiTotQuantity*aviLasOps.CANTP/ataMaster2Resume.LMIN ), 
(RTRIM(ataMaster2Resume.COD) + ' CIF', 'PR.CIF.'+ RTRIM(ataMaster2Resume.COD), 'MasterCost',ataMaster2Resume.afiTotSCF*aviLasOps.CANTP/ataMaster2Resume.LMIN )

)AS ataCosQuantity (cquCode, cquGroup, cquOrigin, cquValue)

-- **********  Sixth block with the costs of labour form master estándar


UNION
SELECT
aviLasOps.op,
aviLasOps.CANTP,
ataMaster6Resume.COD,
ataMaster6Resume.NOM,
CASE WHEN ataCosQuantity.cquGroup = 'SPG' THEN 'M2' ELSE CASE WHEN ataCosQuantity.cquGroup  = 'SIN' THEN 'IYN' ELSE 'SE' END end  AS afiUnit,
1 AS afiConversion,
CASE WHEN ataCosQuantity.cquGroup = 'SPG' THEN 'M2' ELSE CASE WHEN ataCosQuantity.cquGroup  = 'SIN' THEN 'IYN' ELSE 'SE' END end  AS afiSecUnit,
ataCosQuantity.cquGroup,
CONVERT (decimal(38,4),ataCosQuantity.cquValue) AS cquValue,
ataCosQuantity.cquOrigin
FROM
aviLasOps
INNER JOIN
(
SELECT
ataEmp001ProdMaster6.CODP,
ataEmp001ProdMaster6.COD,
EMP001_INV.dbo.SERVTERC.NOM,
ataEmp001ProdMaster.LMIN,
sum(ataEmp001ProdMaster6.CANT) as afiTotQuantity,
sum(ataEmp001ProdMaster6.VALOR) AS afiTotValor
FROM
EMP001_PROD.dbo.MASTER6 as ataEmp001ProdMaster6
INNER JOIN
EMP001_PROD.dbo.MASTER AS ataEmp001ProdMaster
ON
ataEmp001ProdMaster.COD = ataEmp001ProdMaster6.CODP
AND
ataEmp001ProdMaster.MODELO = ataEmp001ProdMaster6.MODELO_MAS
LEFT JOIN
EMP001_INV.dbo.SERVTERC
ON
EMP001_INV.dbo.SERVTERC.COD = ataEmp001ProdMaster6.COD
WHERE
ataEmp001ProdMaster6.MODELO_MAS = ' '
AND
ataEmp001ProdMaster6.cant > 0 
AND
ataEmp001ProdMaster.LMIN > 0
GROUP BY
ataEmp001ProdMaster6.CODP,
ataEmp001ProdMaster6.COD,
EMP001_INV.dbo.SERVTERC.NOM,
ataEmp001ProdMaster.LMIN
) AS ataMaster6Resume
ON
ataMaster6Resume.CODP = aviLasOps.COD
CROSS apply
(
VALUES 
(left(ltrim(ataMaster6Resume.COD),3), 'MasterQuantity', ataMaster6Resume.afiTotQuantity*aviLasOps.CANTP/ataMaster6Resume.LMIN),
(left(ltrim(ataMaster6Resume.COD),3), 'MasterCost', ataMaster6Resume.afiTotValor*aviLasOps.CANTP/ataMaster6Resume.LMIN)

) AS ataCosQuantity ( cquGroup, cquOrigin, cquValue)
) AS ataTotCosts

PIVOT
(
SUM(ataTotCostS.cquValue) FOR ataTotCosts.cquOrigin 
IN
(
[OPQuantity],
[OPCost],
[MasterQuantity],
[MasterCost]
) 
) AS ataPivTable

LEFT JOIN
EMP001_INV.dbo.co_clasificacion
ON
 ataPivTable.GRUP = co_clasificacion.[ca_cla-ni5_gru_factory]
right JOIN
aviLasOps
ON
aviLasOps.OP =  ataPivTable.OP
LEFT JOIN 
EMP001_INV.dbo.vi_mae_clasificado
ON
EMP001_INV.dbo.vi_mae_clasificado.COD = aviLasOps.COD

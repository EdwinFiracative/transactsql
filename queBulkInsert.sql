-- *** Two ways to import bulk datas using a  format file 1. with bulk insert

use
emp001_inv



bulk insert [dbo].[tb_precios_proveedor]
from 'C:\abbTotPrices.txt'

WITH 
  (
	FORMATFILE = 'C:\formatpp2.fmt'
  )

-- ******** using OPENROWSET
 INSERT INTO [dbo].[tb_precios_proveedor]
           ([ca_pre-pro_lista]
           ,[ca_pre-pro_cod_mat_proveedor]
           ,[ca_pre-pro_cod_mat_fabricante]
           ,[ca_pre_pro_tipo]
           ,[ca_pre-pro_descripcion]
           ,[ca_pre-pro_prec_lista]
           ,[ca_pre-pro_descuento]
           ,[ca_pre_pro_uni_negocio]
           ,[ca_pre-pro_id_excel])
 
  SELECT *
      FROM  OPENROWSET(BULK   'C:\abbTotPrices.txt',  
      FORMATFILE='C:\formatpp2.fmt'  
       ) as t1 ;



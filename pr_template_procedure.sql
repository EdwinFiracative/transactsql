USE -- [here data base name]
GO
/****** Object:  StoredProcedure [dbo].[pr_imp_offer]    Script Date: 24-06-24 8:12:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:[author]
-- Create date: [date]
-- Description:	[description of the procedure funcionality]
-- =============================================
CREATE PROCEDURE [dbo].[pr_imp_offer]
	-- tuis procedure don't have parameters
		@opar_bit_if_error bit = 0 output,   -- output parameter 0 no error, 1 error in the procedure
	@opar_nvc_error nvarchar(MAX) = '' output   -- xml with error messsages ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine, ErrorMessage
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @bit_tran_count bit = 0  -- mark if one transaction has satarted
	
	
begin try

	IF @@TRANCOUNT = 0   -- check if there is transaction nesting. If there is don't start another transaction
		BEGIN
			BEGIN TRANSACTION
			SET @bit_tran_count = 1
		END

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
		print @opar_nvc_error -- print error information
		set @opar_bit_if_error = 1						
end catch 


END

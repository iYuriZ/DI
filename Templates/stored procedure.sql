DROP PROCEDURE IF EXISTS PROC_NAME
GO
CREATE PROCEDURE PROC_NAME
	-- Variables
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT OFF
	DECLARE @TranCounter = @@TRANCOUNT
	
	IF @TranCounter > 0
		SAVE TRANSACTION procTrans
	ELSE
		BEGIN TRANSACTION

	BEGIN TRY
		
		-- Query
		
		IF @TranCounter = 0 AND XACT_STATE() = 1
			COMMIT TRANSACTION
		
	END TRY
	BEGIN CATCH
	
		IF @TranCounter = 0 AND XACT_STATE() = 1
			ROLLBACK TRANSACTION
	
		THROW;
	END CATCH
END
GO

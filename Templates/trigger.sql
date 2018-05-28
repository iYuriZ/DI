DROP TRIGGER IF EXISTS trgName;
GO
CREATE TRIGGER trgName
ON
	Table
AFTER INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY
		-- Query
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO